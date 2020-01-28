require 'colorized_string'

module Kuby
  class CLIBase
    private

    def pipeline_w(env, cmd, opts = {}, &block)
      cmd_s = cmd.join(' ')
      print_cmd(cmd_s)
      Open3.pipeline_w([env, cmd_s], opts, &block)
    end

    def execc(cmd)
      cmd_s = cmd.join(' ')
      print_cmd(cmd_s)
      exec(cmd_s)
    end

    def systemm(cmd)
      cmd_s = cmd.join(' ')
      print_cmd(cmd_s)
      system(cmd_s)
    end

    def backticks(cmd)
      cmd_s = cmd.join(' ')
      print_cmd(cmd_s)
      `#{cmd_s}`
    end

    def print_cmd(cmd)
      puts ColorizedString["Executing #{cmd}"].yellow
    end
  end
end
