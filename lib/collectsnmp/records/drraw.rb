module CollectSnmp
	module Records
		# class for representing DRRAW records
		class Drraw
			# +host+ stores the host information associated with the DRRAW record
			attr_accessor :host
			# +data+ stores the data information associated with the DRRAW record
			attr_accessor :data
			# +name+ stores the name information associated with the DRRAW record
			attr_accessor :name
			# +gindex+ stores the graph index information associated with the DRRAW record
			attr_accessor :gindex
			# +dindex+ stores the data index information associated with the DRRAW record
			attr_accessor :dindex
			# +comment+ stores to comment information associated with the DRRAW record
			attr_accessor :comment 

			# Class constructor
			def initialize(host, data, name, gindex, dindex, comment)
				@host = host
				@data = data
				@name = name
				@gindex = gindex
				@dindex = dindex
				@comment = comment
			end

			# Easy printing
			def to_s
				[@host, @data, @name, @gindex, @dindex.to_s, @comment].join(": ")
			end
		end
	end
end
