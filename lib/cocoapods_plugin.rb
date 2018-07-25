
module Pod
  class Installer
    alias_method :multi_thread_install_0712!, :install!
    def install!
      unless config.verbose?
          require 'multi_thread_log.rb'
          require 'thread_safe_hook.rb'
          require 'cocoapods-multithread-installpod.rb'
      end
      multi_thread_install_0712!
    end
  end
end
