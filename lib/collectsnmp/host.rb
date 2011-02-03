module CollectSnmp
	# Class for represeting Host records
	class Host
		# +name+ stores the name of the SNMP host
		attr_accessor :name                                       
		# +idprefix+ stores the prefix id of the SNMP host
		attr_accessor :idprefix
		# +address+ stores the FQDN or IP address of the SNMP host
		attr_accessor :address
		# +version+ stores the SNMP version to be used when querying the SNMP host
		attr_accessor :version
		# +community+ stores the SNMP community string to be used when querying the SNMP host
		attr_accessor :community

		# Class constructor
		def initialize(name, idprefix, address, version, community)
			@name, @idprefix, @address, @version, @community = name, idprefix, address, version, community
		end

		# Class constructor
		def initialize(hash)
			hash.each { |key, value| instance_variable_set("@#{key}", value)}
			@values = []
		end

		# Easy printing
		def to_s
			[@name, @idprefix, @address, @version, @community].join(": ")
		end
	end
end                     
