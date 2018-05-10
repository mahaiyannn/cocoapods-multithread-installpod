require "cocoapods-multithread-installpod/version"
require 'thread/pool'

module Pod
  class Installer
    attr_accessor :worker
    attr_accessor :todo_workers
    attr_accessor :doing_workers

    alias_method :ori_install_pod_sources, :install_pod_sources
    def install_pod_sources
      @worker = Thread.pool(5)
      @todo_workers = []
      @doing_workers = []
      ori_install_pod_sources
      @worker.shutdown
      UI.titled_section "All download task completed!"
    end

    alias_method :ori_install_source_of_pod, :install_source_of_pod
    def install_source_of_pod(pod_name)
      @todo_workers << pod_name
      @worker.process do
        @todo_workers.delete(pod_name)
        @doing_workers << pod_name
        ori_install_source_of_pod(pod_name)
        @doing_workers.delete(pod_name)
        UI.titled_section "Download completed: #{pod_name} (Remain Doing: #{@doing_workers.count} Waiting: #{@todo_workers.count})"
      end
    end

    class Analyzer
      attr_accessor :worker
      attr_accessor :todo_workers
      attr_accessor :doing_workers

      alias_method :ori_fetch_external_sources, :fetch_external_sources
      def fetch_external_sources
        @worker = Thread.pool(5)
        @todo_workers = []
        @doing_workers = []
        ori_fetch_external_sources
        @worker.shutdown
        UI.titled_section "All download task completed!"
      end

      alias_method :ori_fetch_external_source, :fetch_external_source
      def fetch_external_source(dependency, use_lockfile_options)
        @todo_workers << dependency.name
        @worker.process do
          @todo_workers.delete(dependency.name)
          @doing_workers << dependency.name
          ori_fetch_external_source(dependency, use_lockfile_options)
          @doing_workers.delete(dependency.name)
          UI.titled_section "Download completed: #{dependency.name} (Remain Doing: #{@doing_workers.count} Waiting: #{@todo_workers.count})"
        end
      end
    end


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

  module Downloader
    # The class responsible for managing Pod downloads, transparently caching
    # them in a cache directory.
    #
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
