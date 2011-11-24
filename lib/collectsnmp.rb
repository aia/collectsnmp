require 'rubygems'
require 'erb'
require 'find'

require 'collectsnmp/version'
require 'collectsnmp/datatype'
require 'collectsnmp/host'
require 'collectsnmp/tasks'
require 'collectsnmp/records'
require 'collectsnmp/writers'

module CollectSnmp
  extend self

  # +data+ is a hash of data objects
  attr_reader :data
  # +hosts+ is a hash of host objects
  attr_reader :hosts
  
  @data, @hosts = {}, {}

  # Initialize SNMP poller components
  def load(data, hosts, writers, tasks)
    load_data(data)
    load_hosts(hosts)
    load_writers(writers)
    load_tasks(tasks)
  end 

  # Initialize SNMP poller data objects
  def load_data(data)
    data.each { |element| @data[element['name']] = DataType.new(element) }
  end

  # Initialize SNMP poller host objects
  def load_hosts(hosts)
    hosts.each { |host| @hosts[host['name']] = Host.new(host) }
  end

  # Initialize SNMP poller writer objects
  def load_writers(writers)
    Writers.load(writers)
  end

  # Initialize SNMP poller tasks
  def load_tasks(tasks)
    Tasks.load(tasks)
  end

  # Fallback log method
  def log(msg)
    puts(msg)
  end 
end
