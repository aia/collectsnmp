# Need to make sure for Ruby 1.8.6 that Base class gets loaded first
Dir["#{File.dirname(__FILE__)}/writers/*.rb"].sort.each { |f| require f }

module CollectSnmp
  module Writers
    extend self

    attr_reader :list
 
    def load(writers)
      @list = {}
      writers.each do |writer|
        @list[writer['config']['name']] = 
          Object.const_get(:CollectSnmp).const_get(:Writers).const_get(writer['type']).new(writer['config'])
      end
    end

  end
end
