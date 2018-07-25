require 'cocoapods'

module Pod
  class Installer
    class PodSourcePreparer
      # Remove Dir.chidr to ensure thread safety.
      alias_method :ori_run_prepare_command, :run_prepare_command
      def run_prepare_command
        return unless spec.prepare_command
        UI.section(' > Running prepare command', '', 1) do
          begin
            ENV.delete('CDPATH')
            ENV['COCOAPODS_VERSION'] = Pod::VERSION
            prepare_command = spec.prepare_command.strip_heredoc.chomp
            full_command = "cd \"#{path}\"\nset -e\n" + prepare_command
            bash!('-c', full_command)
          ensure
            ENV.delete('COCOAPODS_VERSION')
          end
        end
      end
    end
  end

  class Specification
    class << self
      @@my_mutex = Mutex.new
      alias_method :pod_from_string_0712, :from_string
      def from_string(spec_contents, path, subspec_name = nil)
        @@my_mutex.synchronize do
          pod_from_string_0712(spec_contents, path, subspec_name)
        end
      end
    end
  end

  module Downloader
    class Cache
      @@mutex=Mutex.new
      alias_method :ori_ensure_matching_version, :ensure_matching_version
      def ensure_matching_version
        @@mutex.lock
        ori_ensure_matching_version
        @@mutex.unlock
      end
    end
  end
end
