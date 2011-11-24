module CollectSnmp
  # Data type class used to store data type parameters that will be accessed by reference from other classes
  class DataType
    # +name+ stores the name of the SNMP data type
    attr_accessor :name
    # +instance+ stores SNMP instance OID to query (will be used as names for the values)
    attr_accessor :instance
    # +dst+ stores DST parameter e.g. COUNTER, GAUGE
    attr_accessor :dst
    # +range+ stores Range parameter
    attr_accessor :range
    # +values+ stores SNMP values OID
    attr_accessor :values

    # Class constructor
    def initialize(name, instance, dst, range)
      @name, @instance, @dst, @range = name, instance, dst, range
      @values = []
    end

    # Class constructor
    def initialize(hash)
      hash.each { |key, value| instance_variable_set("@#{key}", value) unless (key == "values")}
      @values = hash['values'].split(" ")
    end

    # Easy printing
    def to_s
      [@name, @instance, @dst, @range, @values.join(" ")].join(": ")
    end
  end
end
