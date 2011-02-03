Dir["#{File.dirname(__FILE__)}/records/*.rb"].each { |f| require f }

module CollectSnmp
	module Records
		extend self
	end
end
