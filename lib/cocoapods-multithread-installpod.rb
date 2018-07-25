require "cocoapods-multithread-installpod/version"
require 'concurrent'

module Pod
  class Installer

    alias_method :multi_thread_install_pod_sources, :install_pod_sources
    def install_pod_sources
      @worker = Concurrent::FixedThreadPool.new(5)
      UI.set_spinners('Downloading dependencies')
      @installed_specs = []
      pods_to_install = sandbox_state.added | sandbox_state.changed
      title_options = { :verbose_prefix => '-> '.green }
      root_specs.sort_by(&:name).each do |spec|
        if pods_to_install.include?(spec.name)
          @worker.post do
            if sandbox_state.changed.include?(spec.name) && sandbox.manifest
              current_version = spec.version
              previous_version = sandbox.manifest.version(spec.name)
              has_changed_version = current_version != previous_version
              current_repo = analysis_result.specs_by_source.detect { |key, values| break key if values.map(&:name).include?(spec.name) }
              current_repo &&= current_repo.url || current_repo.name
              previous_spec_repo = sandbox.manifest.spec_repo(spec.name)
              has_changed_repo = !previous_spec_repo.nil? && current_repo && !current_repo.casecmp(previous_spec_repo).zero?
              title = "Installing #{spec.name} #{spec.version}"
              title << " (was #{previous_version} and source changed to `#{current_repo}` from `#{previous_spec_repo}`)" if has_changed_version && has_changed_repo
              title << " (was #{previous_version})" if has_changed_version && !has_changed_repo
              title << " (source changed to `#{current_repo}` from `#{previous_spec_repo}`)" if !has_changed_version && has_changed_repo
            else
              title = "Installing #{spec}"
            end
            UI.titled_section(title.green, title_options) do
              install_source_of_pod(spec.name)
            end
            UI.report_status(true)
          end
        else
          UI.titled_section("Using #{spec}", title_options) do
            create_pod_installer(spec.name)
          end
        end
      end
      @worker.shutdown
      @worker.wait_for_termination
      UI.set_spinners
    end

    class Analyzer

      alias_method :ori_fetch_external_sources, :fetch_external_sources
      def fetch_external_sources(podfile_state)
        @worker = Concurrent::FixedThreadPool.new(5)
        UI.set_spinners('Fetching external sources')
        ori_fetch_external_sources(podfile_state)
        @worker.shutdown
        @worker.wait_for_termination
        UI.set_spinners
      end

      alias_method :ori_fetch_external_source, :fetch_external_source
      def fetch_external_source(dependency, use_lockfile_options)
        @worker.post do
          ori_fetch_external_source(dependency, use_lockfile_options)
          UI.report_status(true)
        end
      end
    end
  end
end
