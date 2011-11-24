#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'helper'

class CollectSnmpTest < Test::Unit::TestCase
  include TestData

  context "#load" do 
    setup do
      load_testdata
      CollectSnmp::load(@data, @hosts, @writers, @rrd_tasks)
    end

    should "A: load data correctly" do
      @data.each do |element|
        data_ref = CollectSnmp::data[element['name']]
        assert_equal(element['name'], data_ref.name)
        assert_equal(element['instance'], data_ref.instance)
        assert_equal(element['values'].split(' '), data_ref.values)
        assert_equal(element['dst'], data_ref.dst)
        assert_equal(element['range'], data_ref.range)
      end
    end

    should "B: load hosts correctly" do
      @hosts.each do |host|
        host_ref = CollectSnmp::hosts[host['name']]
        assert_equal(host['name'], host_ref.name)
        assert_equal(host['idprefix'], host_ref.idprefix)
        assert_equal(host['address'], host_ref.address)
        assert_equal(host['version'], host_ref.version)
        assert_equal(host['community'], host_ref.community)
      end
    end

    should "C: load writers correctly" do
      writers_list = CollectSnmp::Writers.instance_variable_get(:@list)
      @writers.each do |writer|
        writers_ref = writers_list[writer['config']['name']]
        assert_equal(writer['config']['name'], writers_ref.name)
        assert_equal(writer['config']['interval'].to_i, writers_ref.interval)
        assert_equal(writer['config']['write_path'], writers_ref.write_path)
        assert_equal(writer['config']['rra'].split(' '), writers_ref.rra)
      end
    end

    should "D: load tasks correctly" do
      task_list = CollectSnmp::Tasks.instance_variable_get(:@list) 
      @rrd_tasks.each do |t|
        task_ref = task_list[t['config']['name']]
        host_ref = CollectSnmp::hosts[t['config']['host']]
        writer_ref = CollectSnmp::Writers.instance_variable_get(:@list)[t['config']['writers']]
        data_ref = CollectSnmp::data[t['config']['data']]
        assert_equal(t['config']['name'], task_ref.name)
        assert_kind_of(CollectSnmp::DataType, task_ref.data[0])
        assert_equal(data_ref, task_ref.data[0]) 
        assert_equal(t['config']['interval'].to_i, task_ref.interval)
        assert_equal(t['config']['log_path'], task_ref.log_path)
        assert_kind_of(CollectSnmp::Host, task_ref.host)
        assert_equal(host_ref, task_ref.host)
        assert_equal(writer_ref, task_ref.writers[t['config']['writers']])
      end
    end

    should "E: log correctly" do
      mock_log = flexmock(CollectSnmp)
      mock_log.should_receive(:puts).with("Message").once.and_return(true)
      CollectSnmp.log("Message")
    end
  end
end
