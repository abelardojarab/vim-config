local fn = require('distant.fn')
local Driver = require('spec.e2e.driver')

describe('fn', function()
    local driver

    before_each(function()
        driver = Driver:setup({ label = 'fn.spawn_wait' })
    end)

    after_each(function()
        driver:teardown()
    end)

    describe('spawn_wait', function()
        local function to_tbl(res)
            return {
                success = res.success,
                exit_code = res.exit_code,
                stdout = string.char(unpack(res.stdout)),
                stderr = string.char(unpack(res.stderr)),
            }
        end

        it('should execute remote program and return results', function()
            local err, res = fn.spawn_wait({ cmd = 'echo some output' })
            assert(not err, err)
            assert.are.same({
                success = true,
                exit_code = 0,
                stdout = 'some output\n',
                stderr = '',
            }, to_tbl(res))
        end)

        -- distant and ssh modes behave differently here as ssh treats as a success and
        -- echoes out that the process does not exist whereas distant clearly marks
        -- as an error
        --
        -- TODO: For some reason, stderr is also not captured in the test below. distant-ssh2
        --       is able to correctly capture stderr, so this will need to be investigated
        if driver:mode() == 'distant' then
            it('should support capturing stderr', function()
                local err, res = fn.spawn_wait({ cmd = 'sh -c "echo some output 1>&2"' })
                assert(not err, err)
                assert.are.same({
                    success = true,
                    exit_code = 0,
                    stdout = '',
                    stderr = 'some output\n',
                }, to_tbl(res))
            end)

            it('should support capturing exit code', function()
                local err, res = fn.spawn_wait({ cmd = 'sh -c "exit 99"' })
                assert(not err, err)
                assert.are.same({
                    success = false,
                    exit_code = 99,
                    stdout = '',
                    stderr = '',
                }, to_tbl(res))
            end)
        end
    end)
end)
