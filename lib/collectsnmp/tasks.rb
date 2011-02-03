# Need to make sure for Ruby 1.8.6 that Base class gets loaded first 
Dir["#{File.dirname(__FILE__)}/tasks/*.rb"].sort.each { |f| require f }

module CollectSnmp
	module Tasks
		extend self
		
		attr_reader :list
		attr_reader :hub
		
		def load(tasks)
			@list = {}
			tasks.each do |task| 
				@list[task['config']['name']] = 
					Object.const_get(:CollectSnmp).const_get(:Tasks).const_get(task['type']).new(task['config'])
			end
			
			@hub = CollectSnmp::Tasks::Hub.new({
				'name'  => "hub",
				'interval' => "25",
				'log_path'  => tasks[0]['config']['log_path']
			})
		end
	end
end
