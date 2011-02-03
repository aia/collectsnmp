module CollectSnmp
	module Records
		# Class for represting Poll records
		class Poll
			# +data+ stores a reference to SnmpDataType associated with the SNMP poll record
			attr_accessor :data
			# +name+ stores SNMP poll record name
			attr_accessor :name
			# +is_new+ stores a flag whether the record is new
			attr_accessor :is_new
			# +is_updated+ shows a record with updated values that has not been written
			attr_accessor :is_updated
			# +values+ stores the SNMP poll record values
			attr_accessor :values

			# Class constructor
			def initialize(data)
				@data = data
				@name = ""
				@values = []
				@is_new = 1
				@is_updated = 0
			end

			# Easy printing
			def to_s
				[@data.to_s, @name, @is_new.to_s, @is_updatred, @values.join(" ")].join(": ")
			end
		end
	end
end
