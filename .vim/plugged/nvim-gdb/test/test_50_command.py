'''Test custom command.'''

TESTS = {
    'gdb': [("GdbCustomCommand('print i')", '$1 = 0'),
            ("GdbCustomCommand('info locals')", 'i = 0')],
    'lldb': [("GdbCustomCommand('frame var argc')", "(int) argc = 1"),
             ("GdbCustomCommand('frame var i')", "(int) i = 0")],
}

def test_backend(eng, backend):
    '''Custom command in C++.'''
    eng.feed(backend['launch'])
    assert eng.wait_paused() is None
    eng.feed(backend['tbreak_main'])
    eng.feed('run\n', 1000)
    eng.feed('<esc>')
    eng.feed('<f10>')
    for cmd, exp in TESTS[backend['name']]:
        assert exp == eng.eval(cmd)

def test_pdb(eng, post):
    '''Custom command in PDB.'''
    assert post
    eng.feed(' dp\n')
    assert eng.wait_paused() is None
    eng.feed('b _foo\n')
    eng.feed('cont\n')
    def _print_num():
        return eng.eval("GdbCustomCommand('print(num)')")
    eng.wait_for(_print_num, lambda res: res == "0")
    eng.feed('cont\n')
    eng.wait_for(_print_num, lambda res: res == "1")

WATCH_TESTS = {
    'gdb': ('info locals', ['i = 0']),
    'lldb': ('frame var i', ['(int) i = 0']),
}

def test_watch_backend(eng, backend_express):
    '''Watch window with custom command in C++.'''
    eng.feed(backend_express['launch'])
    assert eng.wait_paused() is None
    eng.feed(backend_express['tbreak_main'])
    eng.feed('run\n', 1000)
    eng.feed('<esc>')
    cmd, res = WATCH_TESTS[backend_express["name"]]
    eng.feed(f':GdbCreateWatch {cmd}\n')
    eng.feed(':GdbNext\n')
    eng.wait_for(lambda: eng.eval(f"getbufline('{cmd}', 1)"),
                 lambda out: out == res)


def test_watch_backend_cleanup(eng, backend_express):
    '''Cleanup of watch window with custom command in C++.'''
    eng.feed(backend_express['launch'])
    assert eng.wait_paused() is None
    eng.feed(backend_express['tbreak_main'])
    eng.feed('run\n', 1000)
    eng.feed('<esc>')
    cmd, res = WATCH_TESTS[backend_express["name"]]
    eng.feed(f':GdbCreateWatch {cmd}\n')
    bufname = cmd.replace(" ", "\\\\ ")
    # If a user wants to get rid of the watch window manually,
    # the plugin should take care of properly getting rid of autocommands
    # in the backend.
    auid = eng.exec_lua(f"return vim.api.nvim_create_autocmd('User', {{pattern='NvimGdbCleanup', command='bwipeout! {bufname}'}})")
    try:
        eng.feed(':GdbDebugStop\n')

        # Start and test another time to check that no error is raised
        eng.feed(backend_express['launch'])
        assert eng.wait_paused() is None
        eng.feed(backend_express['tbreak_main'])
        eng.feed('run\n', 1000)
        eng.feed('<esc>')
        cmd, res = WATCH_TESTS[backend_express["name"]]
        eng.feed(f':GdbCreateWatch {cmd}\n')
        eng.feed(':GdbNext\n')
        eng.wait_for(lambda: eng.eval(f"getbufline('{cmd}', 1)"),
                     lambda out: out == res)
    finally:
        eng.exec_lua(f"vim.api.nvim_del_autocmd({auid})")
