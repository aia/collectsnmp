module CollectSnmp
	module Writers
		class Base
			# +name+ is the reference name of the writer instance
			attr_accessor :name
			# +write_path+
			attr_accessor :write_path
			
			def initialize(name, write_path)
				@name = name
				@write_path = write_path
			end
			
			def create_directories(hostname, datatypes, callobj)
				callobj.log("Creating new directories")
				# For each data type polled
				datatypes.each do |element|
					# Construct a directory name
					dirname = [@write_path, hostname, element.name].join("/")
					begin
						# Create path if needed
						if (File.directory?(dirname))
							callobj.log("Directory exists: #{dirname}")
						else
							callobj.log("New directory: #{dirname}")
							FileUtils.mkpath(dirname) 
						end	
					rescue Exception => except
						# Catch and report exceptions to local log
						callobj.ehandle(except)
					end
				end
				callobj.log("Finished creating directories")
			end
		end
	end
end