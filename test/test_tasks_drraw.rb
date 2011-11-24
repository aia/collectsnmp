#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'helper'

class TasksDrrawTest < Test::Unit::TestCase
  include TestData

  context "#drraw" do 
    setup do
      load_testdata
      CollectSnmp::load(@data, @hosts, @writers, @drraw_tasks)
      @drraw_task = CollectSnmp::Tasks.list[@drraw_tasks[0]['config']['name']] 
      @drraw_task.instance_variable_set(:@logh, $stdout)
      flexmock(CollectSnmp::Tasks.list[@drraw_tasks[0]['config']['name']])
    end

    should "A: index drraw file correctly" do
      drraw_index = @drraw_tasks[0]['config']['log_path'] + "/index"
      flexmock(File).should_receive(:exists?).with(drraw_index).times(2).and_return(true)
      flexmock(File).should_receive(:read).with(drraw_index).once.and_return(@drraw_var)
      @drraw_task.index_drraw
      assert_equal("g1294881337.15444", 
        @drraw_task.idrraw["HOST2/ifmib-if-octets64/Vlan-302"].gindex)
      assert_equal("HOST2/ifmib-if-octets64/Vlan-302", 
        @drraw_task.idrraw["HOST2/ifmib-if-octets64/Vlan-302"].host)
      assert_equal("1294881337", 
        @drraw_task.idrraw["HOST1/ifmib-if-octets64/GigabitEthernet-1-10"].gindex)
      assert_equal(112, 
        @drraw_task.idrraw["HOST1/ifmib-if-octets64/GigabitEthernet-1-10"].dindex)
      assert_equal("HOST1", 
        @drraw_task.idrraw["HOST1/ifmib-if-octets64/GigabitEthernet-1-10"].host)
      assert_equal("ifmib-if-octets64", 
        @drraw_task.idrraw["HOST1/ifmib-if-octets64/GigabitEthernet-1-10"].data)
      assert_equal("GigabitEthernet-1-10", 
        @drraw_task.idrraw["HOST1/ifmib-if-octets64/GigabitEthernet-1-10"].name)
      assert_equal(113, @drraw_task.hid["HOST1"])
      assert_equal("1294881337", @drraw_task.hmd["HOST1"])
      flexmock(File).should_receive(:read).with(drraw_index).once.and_raise(RuntimeError)
      @drraw_task.index_drraw
    end

    should "B: add a template correctly" do
      @drraw_task.idrraw = {
        "HOST1/ifmib-if-octets64/GigabitEthernet-1-10" => flexmock(
          :comment => "",
          :data => "ifmib-if-octets64",
          :dindex => 112,
          :gindex => "1294881337",
          :host => "HOST1",
          :name => "GigabitEthernet-1-10"
        )
      }
      @erb_mock = flexmock
      @erb_mock.should_receive(:result).and_return("Test")
      @drraw_task.erb_ref = flexmock()
      @drraw_task.erb_ref.should_receive(:new).and_return(@erb_mock)
      flexmock(File).should_receive(:read).with("template").times(2).and_return(true)
      flexmock(File).should_receive(:open).with(String, "w").once.and_return(flexmock(:puts => true, :close => true))
      @drraw_task.add_template(
        "template", 
        "HOST1/ifmib-if-octets64/GigabitEthernet-1-10", 
        "host1", 
        "ifmib-if-octets64", 
        "GigabitEthernet-1-10", 
        "comment"
      )
      flexmock(File).should_receive(:open).with(String, "w").once.and_raise(RuntimeError)
      @drraw_task.add_template(
        "template", 
        "HOST1/ifmib-if-octets64/GigabitEthernet-1-10", 
        "host1", 
        "ifmib-if-octets64", 
        "GigabitEthernet-1-10", 
        "comment"
      )
      @drraw_task.add_template(
        "template", 
        "HOST4/ifmib-if-octets64/GigabitEthernet-1-10", 
        "host1", 
        "ifmib-if-octets64", 
        "GigabitEthernet-1-10", 
        "comment"
      )
    end

    should "C: index RRD folder correctly" do
      @drraw_task.instance_variable_set(:@logh, $stdout)
      flexmock(File).should_receive(:directory?).with(String).
        times(7).and_return(true, false, false, false, true, false, false, false)
      flexmock(File).should_receive(:exists?).with(String).times(3).and_return(true)
      flexmock(Find).should_receive(:find).with(String, Proc).and_return do |s, block|
        block.call(@drraw_paths[0])
        block.call(@drraw_paths[1])
        block.call(@drraw_paths[2])
        block.call(@drraw_paths[3])
        block.call(@drraw_paths[4])
      end
      flexmock(@drraw_task, :add_template => true)
      @drraw_task.idrraw = @idrraw[0]
      @drraw_task.index_rrd
      @drraw_task.index_rrd
    end

    should "D: write index correctly" do
      mock_fh = flexmock
      mock_fh.should_receive(:puts).with(String).times(3).and_return(true)
      mock_fh.should_receive(:close).once.and_return(true)
      flexmock(File).should_receive(:open).with(String, "w").once.and_return(mock_fh)
      @drraw_task.idrraw = @idrraw[1]
      @drraw_task.write_index
    end

    should "E: run correctly" do
      log_path = @drraw_task.instance_variable_get(:@log_path)
      filepath = [log_path, [@drraw_tasks[0]['config']['name'], "log"].join(".")].join("/")
      flexmock(File).should_receive(:directory?).with(log_path).once.and_return(true)
      flexmock(File).should_receive(:exists?).with(filepath).once.and_return(true)
      flexmock(File).should_receive(:open).with(filepath, "a").once.and_return($stdout)
      #flexmock(CollectSnmp::Tasks.list[@drraw_tasks[0]['config']['name']], :start_log => true)
      #flexmock(CollectSnmp::Tasks.list[@drraw_tasks[0]['config']['name']], :log => true)
      @drraw_task.should_receive(:index_drraw).and_return(true)
      @drraw_task.should_receive(:index_rrd).and_return(true)
      @drraw_task.should_receive(:write_index).and_return(true)
      flexmock(Thread).should_receive(:new).with(Proc).once.and_return { |block| block.call }
      flexmock(Thread).should_receive(:stop).times(2).and_return(true)
      @drraw_task.should_receive(:continue_loop?).times(2).and_return(true, false)
      @drraw_task.run
    end
  end
end
