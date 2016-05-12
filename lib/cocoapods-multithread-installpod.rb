require "cocoapods-multithread-installpod/version"
require 'thread'

if Pod::VERSION=='0.39.0' or Pod::VERSION=='1.0.0'
  module Pod
    class Installer
      def install_pod_sources
        @installed_specs = []
        pods_to_install = sandbox_state.added | sandbox_state.changed
        title_options = { :verbose_prefix => '-> '.green }

        work_q = Queue.new
        root_specs.sort_by(&:name).each{|spec| work_q.push spec }
        workers = (0...20).map do
          Thread.new do
            begin
              while spec = work_q.pop(true)
                if pods_to_install.include?(spec.name)
                  if sandbox_state.changed.include?(spec.name) && sandbox.manifest
                    previous = sandbox.manifest.version(spec.name)
                    title = "Installing #{spec.name} #{spec.version} (was #{previous})"
                  else
                    title = "Installing #{spec}"
                  end
                  UI.titled_section(title.green, title_options) do
                    install_source_of_pod(spec.name)
                    #UI.titled_section("Installed #{spec}", title_options)
                  end
                else
                  UI.titled_section("Using #{spec}", title_options) do
                    create_pod_installer(spec.name)
                    #UI.titled_section("Installed #{spec}", title_options)
                  end
                end
              end
            rescue ThreadError
            end
          end
        end
        workers.map(&:join)

      end
    end


    module Downloader
      # The class responsible for managing Pod downloads, transparently caching
      # them in a cache directory.
      #
      class Cache
        @@mutex=Mutex.new
        def ensure_matching_version
          @@mutex.lock
          version_file = root + 'VERSION'
          version = version_file.read.strip if version_file.file?

          root.rmtree if version != Pod::VERSION && root.exist?
          root.mkpath
          version_file.open('w') { |f| f << Pod::VERSION }
          @@mutex.unlock
        end
      end
    end
  end

elsif Pod::VERSION=='0.35.0'
  module Pod
    class Installer
      def install_pod_sources
        @installed_specs = []
        pods_to_install = sandbox_state.added | sandbox_state.changed
        title_options = { :verbose_prefix => '-> '.green }
        sorted_root_specs = root_specs.sort_by(&:name)
        threads=[]
        max_thread_count = 20.0
        per_thead_task_count =(sorted_root_specs.count/max_thread_count).ceil
        i = 0
        while i < max_thread_count
          sub_sorted_root_specs = sorted_root_specs[i*per_thead_task_count, per_thead_task_count]
          if sub_sorted_root_specs != nil
            threads << Thread.new(sub_sorted_root_specs) do |specs|
              specs.each do |spec|
                if pods_to_install.include?(spec.name)
                  if sandbox_state.changed.include?(spec.name) && sandbox.manifest
                    previous = sandbox.manifest.version(spec.name)
                    title = "Installing #{spec.name} #{spec.version} (was #{previous})"
                  else
                    title = "Installing #{spec}"
                  end
                  UI.titled_section(title.green, title_options) do
                    install_source_of_pod(spec.name)
                  end
                else
                  UI.titled_section("Using #{spec}", title_options)
                end
              end
            end
          end
          i+=1
        end
        threads.each{|t| t.join}
      end
    end

    module UserInterface
      class << self
        def wrap_string(string, indent = 0)
          if disable_wrap
            string
          else
            first_space = ' ' * indent
            # indented = CLAide::Helper.wrap_with_indent(string, indent, 9999)
            # first_space + indented
          end
        end
      end
    end
  end
end


