require "cocoapods-multithread-installpod/version"
require 'thread'

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
                  title = "Thread.current #{Thread.current},Installing #{spec.name} #{spec.version} (was #{previous})"
                else
                  title = "Thread.current #{Thread.current},Installing #{spec}"
                end
                UI.titled_section(title.green, title_options) do
                  install_source_of_pod(spec.name)
                  UI.titled_section("Thread.current #{Thread.current}, Installed #{spec}", title_options)
                end
              else
                UI.titled_section("Thread.current #{Thread.current},Using #{spec}", title_options) do
                  create_pod_installer(spec.name)
                  UI.titled_section("Thread.current #{Thread.current}, Installed #{spec}", title_options)
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

      def ensure_matching_version
          version_file = root + 'VERSION'
          version = version_file.read.strip if version_file.file?

          root.rmtree if version != Pod::VERSION && root.exist?
          root.mkpath

          Thread.main do
            version_file.open('w') { |f| f << Pod::VERSION }
          end
      end

    end

  end

end

# module UserInterface
#   class << self
#     def wrap_string(string, indent = 0)
#       if disable_wrap
#         string
#       else
#         first_space = ' ' * indent
#         # indented = CLAide::Helper.wrap_with_indent(string, indent, 9999)
#         # first_space + indented
#       end
#     end
#   end
# end

