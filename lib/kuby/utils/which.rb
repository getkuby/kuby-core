module Kuby
  module Utils
    # This code was copied from the ptools gem, licensed under the Artistic v2 license:
    # https://github.com/djberg96/ptools/blob/4ef26adc870cf02b8342df58da53c61bcd4af6c4/lib/ptools.rb
    #
    # Only the #which function and dependent constants have been copied. None of the copied code
    # has been modified.
    #
    module Which
      if File::ALT_SEPARATOR
        MSWINDOWS = true
        if ENV['PATHEXT']
          WIN32EXTS = ".{#{ENV['PATHEXT'].tr(';', ',').tr('.', '')}}".downcase
        else
          WIN32EXTS = '.{exe,com,bat}'.freeze
        end
      else
        MSWINDOWS = false
      end

      def which(program, path = ENV['PATH'])
        raise ArgumentError, 'path cannot be empty' if path.nil? || path.empty?

        # Bail out early if an absolute path is provided.
        if program =~ /^\/|^[a-z]:[\\\/]/i
          program += WIN32EXTS if MSWINDOWS && File.extname(program).empty?
          found = Dir[program].first
          if found && File.executable?(found) && !File.directory?(found)
            return found
          else
            return nil
          end
        end

        # Iterate over each path glob the dir + program.
        path.split(File::PATH_SEPARATOR).each do |dir|
          dir = File.expand_path(dir)

          next unless File.exist?(dir) # In case of bogus second argument

          file = File.join(dir, program)

          # Dir[] doesn't handle backslashes properly, so convert them. Also, if
          # the program name doesn't have an extension, try them all.
          if MSWINDOWS
            file = file.tr(File::ALT_SEPARATOR, File::SEPARATOR)
            file += WIN32EXTS if File.extname(program).empty?
          end

          found = Dir[file].first

          # Convert all forward slashes to backslashes if supported
          if found && File.executable?(found) && !File.directory?(found)
            found.tr!(File::SEPARATOR, File::ALT_SEPARATOR) if File::ALT_SEPARATOR
            return found
          end
        end

        nil
      end

      extend(self)
    end
  end
end
