module PACKMAN
  class RunManager
    def self.delegated_methods
      [:run]
    end

    def self.default_command_prefix
      cmd_str = ''
      PACKMAN.append_env 'CPPFLAGS', PACKMAN.cppflags
      PACKMAN.append_env 'LDFLAGS', PACKMAN.ldflags
      # Handle RPATH variable.
      rpath_flag = PACKMAN.compiler(:c).flag(:rpath).("#{ConfigManager.install_root}/#{CompilerManager.active_compiler_set_index}")
      PACKMAN.append_env 'LDFLAGS', rpath_flag
      # Handle compilers.
      CompilerManager.active_compiler_set.compilers.each do |language, compiler|
        flags = compiler.default_flags[language]
        PACKMAN.append_env PACKMAN.compiler_flags_env_name(language), flags
        PACKMAN.append_env PACKMAN.compiler_flags_env_name(language), rpath_flag
        case language
        when 'c'
          PACKMAN.reset_env 'CC', compiler.command
        when 'cxx'
          PACKMAN.reset_env 'CXX', compiler.command
        when 'fortran'
          PACKMAN.reset_env 'F77', compiler.command
          PACKMAN.reset_env 'FC', compiler.command
        end
      end
      # Handle customized environment variables.
      PACKMAN.env_keys.each do |key|
        cmd_str << "#{PACKMAN.export_env key} && "
      end
      return cmd_str
    end

    def self.run cmd, *args
      cmd_str = default_command_prefix
      cmd_args = args.select { |a| a.class == String }.join(' ')
      run_args = args.select { |a| a.class == Symbol }
      cmd_str << " #{cmd} "
      cmd_str << "#{cmd_args} "
      if CommandLine.has_option? '-debug'
        PACKMAN.blue_arrow cmd_str
      else
        PACKMAN.blue_arrow "#{cmd} #{cmd_args}", :truncate
      end
      if not CommandLine.has_option? '-verbose' and not run_args.include? :screen_output
        cmd_str << "1> #{ConfigManager.package_root}/stdout 2> #{ConfigManager.package_root}/stderr"
      end
      system cmd_str
      if not $?.success? and not run_args.include? :skip_error
        info =  "PATH: #{FileUtils.pwd}\n"
        info << "Command: #{cmd_str}\n"
        info << "Return: #{$?}\n"
        if not CommandLine.has_option? '-verbose'
          info << "Standard output: #{ConfigManager.package_root}/stdout\n"
          info << "Standard error: #{ConfigManager.package_root}/stderr\n"
        end
        CLI.report_error "Failed to run the following command:\n"+info
      end
      if not CommandLine.has_option? '-verbose' and not run_args.include? :screen_output
        FileUtils.rm("#{ConfigManager.package_root}/stdout")
        FileUtils.rm("#{ConfigManager.package_root}/stderr")
      end
    end
  end
end
