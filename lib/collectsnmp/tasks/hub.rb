module CollectSnmp
  module Tasks
    class Hub < Base
      def initialize(hash)
        super(hash['name'], hash['interval'], hash['log_path'])
        @continue_loop = true
        hash['log_level'] ? @log_level = hash['log_level'] : true
      end
      
      def run
        start_log([@name, "log"].join('.'))
        Thread.current["name"] = "Hub"
        list = CollectSnmp::Tasks.list
        list.each_value {|task| task.run }

        begin
          list.each_value { |task| log("#{task.thread.inspect}: #{task.to_s}") }
          sleep @interval
          list.each_value do |task|
            task.ttl -= @interval
            if (task.ttl == 0)
              task.thread.run 
            end
          end
        end until (!continue_loop?) 
      end
    end
  end
end
