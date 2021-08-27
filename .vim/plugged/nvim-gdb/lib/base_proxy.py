"""
Run a CLI application in a pty.

This will allow to inject server commands not exposing them
to a user.
"""

import abc
import argparse
import array
import errno
import fcntl
import logging
import os
import pty
import re
import select
import signal
import socket
import sys
import termios
import tty
from typing import Union

import stream_filter


class BaseProxy:
    """This class does the actual work of the pseudo terminal."""

    def __init__(self, app_name: str):
        """Create a spawned process."""
        parser = argparse.ArgumentParser(
            description="Run %s through a filtering proxy." % app_name)
        parser.add_argument('cmd', metavar='ARGS', nargs='+',
                            help='%s command with arguments' % app_name)
        parser.add_argument('-a', '--address', metavar='ADDR',
                            help='A file to dump the side channel UDP port.')
        args = parser.parse_args()

        self.exitstatus = 0
        self.server_address: str = args.address
        self.argv = args.cmd
        log_handler = logging.NullHandler() if not os.environ.get('CI') \
            else logging.FileHandler("proxy.log")
        logging.basicConfig(
            level=logging.DEBUG,
            format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
            handlers=[log_handler])
        self.logger = logging.getLogger(type(self).__name__)
        self.logger.info("Starting proxy: %s", app_name)

        self.sock: Union[socket.socket, None] = None
        if self.server_address:
            # Create a UDS socket
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.bind(('127.0.0.1', 0))
            self.sock.settimeout(0.5)
            _, port = self.sock.getsockname()
            with open(self.server_address, 'w') as f:
                f.write(f"{port}")

        # Create the filter
        self.filter = [(stream_filter.Filter(), lambda _: None)]
        # Where was the last command received from?
        self.last_addr = None

        # Last user command
        self.last_command = b''
        self.command_buffer = bytearray()

        # Spawn the process in a PTY
        self.pid, self.master_fd = pty.fork()
        if self.pid == pty.CHILD:
            try:
                os.execvp(self.argv[0], self.argv)
            except OSError as e:
                sys.stderr.write(f"Failed to launch: {e}\n")
                os._exit(1)

    def run(self):
        """Run the proxy, the entry point."""
        old_handler = signal.signal(signal.SIGWINCH,
                                    lambda signum, frame: self._set_pty_size())

        mode = tty.tcgetattr(pty.STDIN_FILENO)
        tty.setraw(pty.STDIN_FILENO)

        self._set_pty_size()

        try:
            self._process()
        except OSError as os_err:
            # Avoid printing I/O Error that happens on every GDB quit
            if os_err.errno != errno.EIO:
                self.logger.exception("Exception")
                raise
        except Exception:
            self.logger.exception("Exception")
            raise
        finally:
            tty.tcsetattr(pty.STDIN_FILENO, tty.TCSAFLUSH, mode)

            _, systemstatus = os.waitpid(self.pid, 0)
            if systemstatus:
                if os.WIFSIGNALED(systemstatus):
                    self.exitstatus = os.WTERMSIG(systemstatus) + 128
                else:
                    self.exitstatus = os.WEXITSTATUS(systemstatus)
            else:
                self.exitstatus = 0

            os.close(self.master_fd)
            self.master_fd = None
            signal.signal(signal.SIGWINCH, old_handler)

            if self.server_address:
                try:
                    os.unlink(self.server_address)
                except OSError:
                    pass

    def set_filter(self, filt, handler):
        """Push a new filter with given handler."""
        self.logger.info("set_filter %s %s", str(filt), str(handler))
        if len(self.filter) == 1:
            self.logger.info("filter accepted")
            # Only one command at a time. Should be an assertion here,
            # but we wouldn't want to terminate the program.
            if self.filter:
                self._timeout()
            self.filter.append((filt, handler))
            return True
        self.logger.warning("filter rejected")
        return False

    @abc.abstractmethod
    def get_prompt(self):
        """Get a compiled regex to match the debugger prompt.

        The implementations should implement this.
        """

    def process_handle_command(self, cmd, response):
        """Process output of custom command."""
        self.logger.info("Process handle command %s bytes", len(response))
        # Assuming the prompt occupies the last line
        result = response[(len(cmd) + 1):response.rfind(b'\n')].strip()
        return result

    def filter_command(self, command):
        """Prepare a requested command for execution."""
        tokens = re.split(r'\s+', command.decode('utf-8'))
        if tokens[0] == 'handle-command':
            cmd = command[len('handle-command '):]
            res = self.set_filter(
                stream_filter.StreamFilter(self.get_prompt()),
                lambda resp: self.process_handle_command(cmd, resp))
            return cmd if res else b''
        return command

    def _set_pty_size(self):
        """Set the window size of the child pty."""
        assert self.master_fd is not None
        buf = array.array('h', [0, 0, 0, 0])
        try:
            fcntl.ioctl(pty.STDOUT_FILENO, termios.TIOCGWINSZ, buf, True)
            fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, buf)
        except OSError as ex:
            # Avoid printing I/O Error that happens on every GDB quit
            if ex.errno != errno.EIO:
                self.logger.exception("Exception")

    def _process(self):
        """Run the main loop."""
        while True:
            try:
                sockets = [self.master_fd]
                if self.sock:
                    sockets.append(self.sock)
                # Don't handle user input while a side command is running.
                if len(self.filter) == 1:
                    sockets.append(pty.STDIN_FILENO)
                rfds, _, _ = select.select(sockets, [], [], 0.25)
                self._process_reads(rfds)
            except OSError as ex:
                if ex.errno == errno.EAGAIN:   # Interrupted system call.
                    continue
                raise

    def _process_reads(self, rfds):
        if not rfds:
            self._timeout()
        else:
            # Handle one packet at a time to mitigate the side channel
            # breaking into user input.
            if self.master_fd in rfds:
                # Reading the program's output
                data = os.read(self.master_fd, 1024)
                self.master_read(data)
            elif pty.STDIN_FILENO in rfds:
                # Reading user's input
                data = os.read(pty.STDIN_FILENO, 1024)
                self.stdin_read(data)
            elif self.sock in rfds:
                data, self.last_addr = self.sock.recvfrom(65536)
                if data[-1] == b'\n':
                    self.logger.warning(
                        "The command ending with <nl>. "
                        "The StreamProxy filter known to fail.")
                self.logger.info("Got command '%s'", data.decode('utf-8'))
                command = self.filter_command(data)
                self.logger.info("Translated command '%s'",
                                 command.decode('utf-8'))
                if command:
                    self.write_master(command)
                    self.write_master(b'\n')

    @staticmethod
    def _write(fdesc, data):
        """Write the data to the file."""
        while data:
            count = os.write(fdesc, data)
            data = data[count:]

    def _timeout(self):
        filt, _ = self.filter[-1]
        data = filt.timeout()
        self._write(pty.STDOUT_FILENO, data)
        # Get back to the passthrough filter on timeout
        if len(self.filter) > 1:
            self.filter.pop()

    def write_stdout(self, data):
        """Write to stdout for the child process."""
        self.logger.debug("%s", data)
        filt, handler = self.filter[-1]
        data, filtered = filt.filter(data)
        self._write(pty.STDOUT_FILENO, data)
        if filtered:
            self.logger.info("Filter matched %d bytes", len(filtered))
            self.filter.pop()
            assert callable(handler)
            res = handler(filtered)
            self.logger.debug("Sending to %s: %s", self.last_addr, res)
            self.sock.sendto(res, 0, self.last_addr)

    def write_master(self, data):
        """Write to the child process from its controlling terminal."""
        self._write(self.master_fd, data)

    def master_read(self, data):
        """Handle data from the child process."""
        self.write_stdout(data)

    def stdin_read(self, data):
        """Handle data from the controlling terminal."""
        # Executing side commands messes with the command history.
        # Most popular debuggers use empty command to prepeat the last
        # command. We need to keep track of user commands to be able
        # to simulate the expected behaviour.
        self.command_buffer.extend(data)
        if re.fullmatch(b'[\r\n]', self.command_buffer):
            # Empty command detected, pass the last known command
            if self.last_command:
                self.logger.info("Repeat last command %s", self.last_command)
                self.write_master(self.last_command)
            else:
                self.write_master(data)
            self.command_buffer.clear()
        else:
            self.write_master(data)
            while True:
                m = re.search(b'[\n\r]', self.command_buffer)
                if not m:
                    break
                self.last_command = self.command_buffer[:m.end()+1]
                self.command_buffer = self.command_buffer[m.end()+1:]
