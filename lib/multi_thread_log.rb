require 'tty-spinner'

module Pod
    module UserInterface

        class << self
            @@spinners = nil
            @@spinner_map = {}
            @@my_mutex = Mutex.new

            alias_method :multi_thread_titled_section, :titled_section
            def titled_section(title, options = {})
                # 为了缩短 Pre-downloading 和 Fetching podspec 的文字长度，防止log出现换行而错乱
                if title =~ /(Pre-downloading: `.+?`) .*/ ||
                    title =~ /(Fetching podspec for `.+?`) .*/
                    title = $1
                end
                if block_given?
                    multi_thread_titled_section(title, options, &Proc.new)
                else
                    multi_thread_titled_section(title, options)
                end
            end

            alias :pod_puts_0706 :puts
            def puts(message = '')
                mainThread = Thread.main == Thread.current
                thread_id = Thread.current.object_id
                message = message.join if message.is_a? Array
                @@my_mutex.synchronize do
                    spinner = @@spinner_map[thread_id]
                    if !mainThread && @@spinners && spinner.nil?
                        spinner = @@spinners.register "[:spinner] #{message}"
                        spinner.auto_spin
                        @@spinner_map[thread_id] = spinner
                    else
                        pod_puts_0706(message)
                    end
                end
            end

            def set_spinners(title=nil)
                @@my_mutex.synchronize do
                    @@spinners = title.nil? ? nil : TTY::Spinner::Multi.new
                end
            end

            def report_status(status)
                thread_id = Thread.current.object_id
                @@my_mutex.synchronize do
                    spinner = @@spinner_map.delete thread_id
                    unless spinner.nil?
                        spinner.success
                    end
                end
            end
        end
    end
end
