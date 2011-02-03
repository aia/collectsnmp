require 'snmp'

module CollectSnmp
	module Tasks
		# Poll task class
		class Poll < Base
			# +host+ stores a reference to the SNMP host record 
			attr_accessor :host
			# +data+ stores an array of references to the SNMP data type records
			attr_accessor :data
			# +writers+ stores RRD RRA parameters
			attr_accessor :writers
			# +last+ stores a hash table of references to SNMP poll records obtained during the latest run
			attr_accessor :last

			# Class constructor
			def initialize(hash)
				super(hash['name'], hash['interval'], hash['log_path'])
				hash['log_level'] ? @log_level = hash['log_level'] : true
				@host = CollectSnmp::hosts[hash['host']]
				@data = []
				@writers = {}
				@last = {}
				@continue_loop = true
				# Set data objects references
				hash['data'].split(' ').each { |element| @data << CollectSnmp::data[element] }
				# Set writer objects references
				hash['writers'].split(' ').each { |writer| @writers[writer] = CollectSnmp::Writers.list[writer] }
			end

			# Standard run method
			def run
				# Start logging
				start_log([@name, "log"].join('.'))
				# Start writers
				@writers.each_value {|writer| writer.start(@host.name, @data, self) }
				# Start a thread 
				@thread = Thread.new {
					# Set the thread name
					Thread.current["name"] = @name
					# Start a loop
					begin
						log("Processing task started: #{self}")
						
						begin
							# Run SNMP query
							snmp_walk
							# Write SNMP values
							@writers.each_value { |writer| writer.write(@host.name, @last, self) }
							# Reset poll records flags
							@last.each_value{ |record| (record.is_new = 0) && (record.is_updated = 0) }
						rescue	Exception => except
							# Catch and report exceptions
							ehandle(except)
						end
						
						# Reset TTL
						@ttl = @interval
						
						# Stop the thread
						Thread.stop
					# Continue to loop if the condition is set 
					end until (!continue_loop?)
				}
			end

			# Walk SNMP objects and store the results in the @last variable
			def snmp_walk
				# Try creating SNMP handle
				manager = SNMP::Manager.new(
						:Host => @host.address,
						:Community => @host.community,
						:Retries => 2
				)
			
				# For each SNMP data type
				@data.each do |element|
					# Try running SNMP walk
					manager.walk([element.instance] + element.values) do |ifname|
						# Extract OID
						oid = [element.name, ifname[0].name].flatten.join(".")
						log("Oid: #{oid}")
						# If the OID is new
						if (@last[oid] == nil)
							log("Got a new object: #{oid}")
							# Initialize the new SNMP poll record
							@last[oid] = CollectSnmp::Records::Poll.new(element)
						end
						# Extract SNMP poll record name
						newname = ifname[0].value.to_s.gsub(/[\s\/\\]/, '-')
						# If the SNMP poll record name has changed
						if (@last[oid].name != newname)
							log("Instance name has changed")
							log("Old #{@last[oid].name} - new #{newname}")
							# Update the record name
							@last[oid].name = newname
							# Set the record for an update
							@last[oid].is_new = 1
						end
						# Update SNMP poll record values
						log("Updating values")
						@last[oid].values = ifname.map { |index| index.value.to_s }
						@last[oid].is_updated = 1
					end
				end
				
				# Close the handle
				manager.close
			end
			
			# Easy printing
			def to_s
				[@name, @host.to_s, @interval, @ttl].join(": ")
			end
		end 
	end
end
