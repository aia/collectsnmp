module CollectSnmp
	module Tasks
		# Base Task class to extend
		class Base
			# +name+ stores the task's name
			attr_accessor :name
			# +log_path+ has the path to the task's logs
			attr_accessor :log_path
			# +log_level indicates the logging threashold
			attr_accessor :log_level
			# +interval+ is the interval for the task's execution
			attr_accessor :interval
			# +ttl+ is the time until the task runs again
			attr_accessor :ttl
			# +thread+ is the thread handle
			attr_accessor :thread
			# +continue_loop+ contains the flag to stop the loop
			attr_accessor :continue_loop
 
			# Class constructor
			def initialize(name, interval, log_path, log_level = 3)
				@name = name
				@log_path = log_path
				@log_level = log_level.to_i
				@interval = Integer(interval)
				@ttl = @interval
			end

			def continue_loop?
				return (@continue_loop)
			end
 
			# Initialize task's logging
			def start_log(filename)
				@log_file = [@log_path, filename].join("/")

				begin
					# Make directory path for local log if needed
					if (!File.directory?(@log_path))
						FileUtils.mkpath(@log_path)
					end

					# Either create or append to the local log file
					if File.exists?(@log_file)
						@logh = File.open(@log_file, "a")
					else
						@logh = File.new(@log_file, "w")
					end

					# Always flush the buffer
					@logh.sync = true
				rescue Exception => except
					# Catch and report exceptions to global log file
					CollectSnmp.log("Exception #{except.class.name}")
					CollectSnmp.log("Message #{except.message}")
					CollectSnmp.log("Backtrace #{except.backtrace.inspect}")
				end
			end

			# Log a given local message
			def log(message, log_level = 3)
				if (log_level < @log_level)
					return
				end
				begin 
					# Prepend a given message with the timestamp and the name of the thread
					@logh.puts("#{Time.now.strftime("%Y/%m/%d-%H:%M:%S")} #{Thread.current["name"]}: #{message}")
				rescue Exception => except
					# If writing to a log file handle fails, report the exception and the message to global log file
					CollectSnmp.log("Exception #{except.class.name}")
					CollectSnmp.log("Message #{except.message}")
					CollectSnmp.log("Backtrace #{except.backtrace.inspect}")
					CollectSnmp.log("#{message}")
				end
			end

			# Handle exceptions
			def ehandle(except)
				log("Exception #{except.class.name}")
				log("Message #{except.message}")
				log("Backtrace #{except.backtrace.inspect}")
			end
		end 
	end
end
