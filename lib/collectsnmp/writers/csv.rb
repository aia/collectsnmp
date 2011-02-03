module CollectSnmp
	module Writers
		class CSV < Base
			def initialize(hash)
				super(hash['name'], hash['write_path'])
			end
			
			def start(hostname, datatypes, callobj)
				create_directories(hostname, datatypes, callobj)
			end
			
			def write(hostname, records, callobj)
				update(hostname, records, callobj)
			end
			
			def update(hostname, records, callobj)
				current_time = Time.now.to_i
				callobj.log("Writing data")
				# For each value in the <last> hashtable
				records.each_value do |record|
					if (record.is_updated == 0)
						callobj.log("Stale entry: #{record.data}, #{record.values}")
						next
					end
					# Reconstruct the CSV filename to update with the value
					filename = [@write_path, hostname, record.data.name, 
						record.values[0].gsub(/[\s\/\\]/, '-')].join("/") + ".csv"
					callobj.log("Writing to file: #{filename}")
					# Construct the argument to run CSV update
					args = "#{current_time}"
					record.values[1..-1].each { |value| args += ",#{value}"}
					callobj.log("Writing values: #{args.to_s}")
					begin
						fh = File.open(filename, "a+")
						fh.puts(args.to_s)
						fh.close
					rescue Exception => except
						# Catch and report exceptions to local log
						callobj.ehandle(except)
					end
					#r.is_updated = 0
				end
			end
		end
	end
end
