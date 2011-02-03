require 'RRD'

module CollectSnmp
	module Writers
		class RRD < Base
			# +rra+ stores an array of RRD RRA format settings
			attr_accessor :rra
			# +interval+ stores the RRD interval setting
			attr_accessor :interval
			
			def initialize(hash)
				super(hash['name'], hash['write_path']) 
				@rra = hash['rra'].split(' ')
				@interval = Integer(hash['interval'])
				@rrd_ref = Object.const_get(:RRD)
			end

			# Standard start interface method
			def start(hostname, datatypes, callobj)
				create_directories(hostname, datatypes, callobj)
			end

			# Standard write interface method
			def write(hostname, records, callobj)
				create_files(hostname, records, callobj)
				update(hostname, records, callobj)
			end

			
			def update(hostname, records, callobj)
				callobj.log("Writing data")
				# For each value in the <last> hashtable
				records.each_value do |record|
					if (record.is_updated == 0)
						callobj.log("Stale entry: #{record.data}, #{record.values}")
						next
					end
					# Reconstruct the RRD filename to update with the value
					filename = [@write_path, hostname, record.data.name, 
						record.values[0].gsub(/[\s\/\\]/, '-')].join("/") + ".rrd"
					callobj.log("Writing to file: #{filename}")
					# Construct the argument to run RRD update
					args = "N"
					record.values[1..-1].each { |value| args += ":#{value}"}
					callobj.log("Writing values: #{args.to_s}")
					begin
						# Try to update RRD
						@rrd_ref.update(filename, args)
					rescue Exception => except
						# Catch and report exceptions to local log
						callobj.ehandle(except)
					end
					#r.is_updated = 0
				end
			end

			# Create new RRD directories
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

			# Create new RRD files
			def create_files(hostname, records, callobj)
				callobj.log("Creating new files")

				# For each value in the <last> hashtable
				records.each_value do |record|
					# If the SNMP poll record is new
					if (record.is_new == 1)
						# Construct an RRD file name
						filename = [@write_path, hostname, record.data.name, 
							record.values[0].gsub(/[\s\/\\]/, '-')].join("/") + ".rrd"
						# Create RRD file if it does not exist
						if (File.exists?(filename))
							callobj.log("File exists: #{filename}")
						else
							callobj.log("New file: #{filename}")
							# Construct RRD arguments
							tnow = Time.now
							start = Time.local(tnow.year, tnow.month, 1, 0, 0, 0).to_i
							heartbeat = 2 * @interval
							args = []
							name = "a"
							1.upto(record.data.values.size) do
								args.push("DS:#{name}:#{record.data.dst}:#{heartbeat}:#{record.data.range}")
								name.succ!
							end
							@rra.each { |ra| args.push(ra) }
							callobj.log("Args: #{args}")
							begin
								# Try to run RRD.create
								@rrd_ref.create(
									filename,
									"--start", "#{start - 1}",
									"--step", "#{@interval}" ,
									*args)
								# Reset the new fag of the SNMP poll record
								#record.is_new = 0
							rescue Exception => except
								# Catch and report exceptions to local log
								callobj.ehandle(except)
							end
						end
					end
				end

				callobj.log("Finished creating new files")
			end
		end
	end
end
