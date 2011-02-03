#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/helper'

class TasksPollTest < Test::Unit::TestCase
	include TestData
	
	context "#poll" do 
		setup do
			load_testdata
			CollectSnmp::load(@data, @hosts, @writers, @rrd_tasks)
			@poll_task = CollectSnmp::Tasks.list[@rrd_tasks[0]['config']['name']]
			@poll_task.instance_variable_set(:@logh, $stdout)
		end
		
		should "A: run a single iteration and correctly process SNMP data" do
			@snmp_return = flexmock()
			@snmp_return.should_receive(:walk).with(Array, Proc).and_return do |array, block| 
				block.call(@snmp_var[0])
			end
			@snmp_return.should_receive(:close).and_return(true)
			flexmock(SNMP::Manager).should_receive(:new).and_return(@snmp_return)
			@poll_task.snmp_walk
			task_p = @poll_task.instance_variable_get(:@last)[[@data[0]['name'], @snmp_var[0][0].name].flatten.join(".")]
			current_data = CollectSnmp::data[@data[0]['name']]
			assert_equal(current_data, task_p.data)
			assert_equal(@snmp_var[0].map { |v| v.value }, task_p.values)
			assert_equal(@snmp_var[0][0].value.to_s.gsub(/[\s\/\\]/, '-'), task_p.name)
			assert_equal(1, task_p.is_new)
		end
		
		should "B: run two iterations and correctly process SNMP data" do 
			@snmp_return = []
			@snmp_var[0..1].each do |s|
				ret = flexmock()
				ret.should_receive(:walk).with(Array, Proc).and_return do |array, block| 
					block.call(s)
				end
				ret.should_receive(:close).and_return(true)
				@snmp_return << ret
			end
			flexmock(SNMP::Manager).should_receive(:new).times(2).and_return(@snmp_return[0], @snmp_return[1])
			@poll_task.snmp_walk
			task_p = @poll_task.instance_variable_get(:@last)[[@data[0]['name'], @snmp_var[0][0].name].flatten.join(".")]
			task_p.is_new = 0
			@poll_task.snmp_walk
			current_data = CollectSnmp::data[@data[0]['name']]
			assert_equal(current_data, task_p.data)
			assert_equal(@snmp_var[1].map { |v| v.value }, task_p.values)
			assert_equal(@snmp_var[0][0].value.to_s.gsub(/[\s\/\\]/, '-'), task_p.name)
			assert_equal(0, task_p.is_new)
		end
		
		should "C: run iterations with multiple variables and correctly process SNMP data" do
			@snmp_return = []
			ret = flexmock()
			ret.should_receive(:walk).with(Array, Proc).and_return do |array, block| 
				block.call(@snmp_var[1])
				block.call(@snmp_var[2])
			end
			ret.should_receive(:close).and_return(true)
			@snmp_return << ret
			ret = flexmock()
			ret.should_receive(:walk).with(Array, Proc).and_return do |array, block| 
				block.call(@snmp_var[3])
			end
			ret.should_receive(:close).and_return(true)
			@snmp_return << ret
			flexmock(SNMP::Manager).should_receive(:new).times(2).and_return(@snmp_return[0], @snmp_return[1])
			@poll_task.snmp_walk
			task_p = @poll_task.instance_variable_get(:@last)[[@data[0]['name'], @snmp_var[1][0].name].flatten.join(".")]
			task_p.is_new = 0
			task_q = @poll_task.instance_variable_get(:@last)[[@data[0]['name'], @snmp_var[2][0].name].flatten.join(".")]
			task_q.is_new = 0
			@poll_task.snmp_walk
			current_data = CollectSnmp::data[@data[0]['name']]
			assert_equal(current_data, task_p.data)
			assert_equal(@snmp_var[1].map { |v| v.value }, task_p.values)
			assert_equal(@snmp_var[1][0].value.to_s.gsub(/[\s\/\\]/, '-'), task_p.name)
			assert_equal(0, task_p.is_new)
			assert_equal(current_data, task_q.data)
			assert_equal(@snmp_var[3].map { |v| v.value }, task_q.values)
			assert_equal(@snmp_var[2][0].value.to_s.gsub(/[\s\/\\]/, '-'), task_q.name)
			assert_equal(0, task_q.is_new)
		end
		
		should "D: execute run method correctly" do
			@snmp_return = flexmock("snmp_return")
			@snmp_return.should_receive(:walk).with(Array, Proc).and_return do |array, block| 
				block.call(@snmp_var[0])
			end
			@snmp_return.should_receive(:close).and_return(true)
			flexmock(SNMP::Manager).should_receive(:new).and_return(@snmp_return)
			flexmock(CollectSnmp::Tasks.list[@rrd_tasks[0]['config']['name']], :start_log => true)
			#flexmock(CollectSnmp::Tasks.list[@rrd_tasks[0]['config']['name']]).should_receive(:start_log).with(String).once.and_return(false)
			#pp CollectSnmp::Tasks.list[@rrd_tasks[0]['config']['name']].start_log
			#flexmock(File).should_receive(:directory?).with(log_path).and_return(false)
			#flexmock(File).should_receive(:exists?).with(String).once.and_return(true)
			#flexmock(File).should_receive(:open).with(String, "a").times(2).and_return(flexmock(:sync= => true, :puts  => true))
			flexmock(Thread).should_receive(:new).with(Proc).times(1).and_return { |block| block.call }
			flexmock(Thread).should_receive(:stop).times(1).and_return(true)
			flexmock(File).should_receive(:directory?).with(String).and_return(true)
			flexmock(FileUtils).should_receive(:mkpath).never
			mock_rrd = flexmock("mock_rrd")
			mock_rrd.should_receive(:create).times(1).and_return(true)
			mock_rrd.should_receive(:update).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd",
				"N:1617125152:1617125151").times(1).and_return(true)
			CollectSnmp::Writers.list[@writers[0]['config']['name']].instance_variable_set(:@rrd_ref, mock_rrd)
			flexmock(File).should_receive(:exists?).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd").
				times(1).and_return(false)
			@poll_task.continue_loop = false
			@poll_task.run
			#mock_exception = flexmock("mock_exception")
			#mock_exception.should_receive(:is_new).and_return(1)
			#mock_exception.should_receive(:is_new=).and_raise(RuntimeError)
			#@poll_task.last = { :one => mock_exception }
			#@poll_task.run
		end
		
		should "E: log and process exceptions" do
			log_handle = flexmock()
			log_handle.should_receive(:puts).and_raise(RuntimeError)
			@poll_task.instance_variable_set(:@logh, log_handle)
			@poll_task.log("Message")
			mock_exception = flexmock()
			mock_exception.should_receive(:message).and_return("MockException")
			mock_exception.should_receive(:backtrace).and_return("Backtrace")
			@poll_task.ehandle(mock_exception)
			flexmock(CollectSnmp, :log => true)
			@poll_task.log("Message", 4)
		end
		
		should "F: start logging" do 
			log_path = @poll_task.instance_variable_get(:@log_path)
			filepath = [log_path, "test.log"].join("/")
			flexmock(File).should_receive(:directory?).with(log_path).and_return(false)
			flexmock(File).should_receive(:exists?).with(filepath).times(3).and_return(true, false, false)
			flexmock(File).should_receive(:open).with(filepath, "a").once.and_return(flexmock(:sync= => true))
			flexmock(File).should_receive(:new).with(filepath, "w").once.and_return(flexmock(:sync= => true))
			flexmock(FileUtils).should_receive(:mkpath).with(log_path).and_return(true)
			@poll_task.start_log("test.log")
			@poll_task.start_log("test.log")
			flexmock(File).should_receive(:new).with(filepath, "w").once.and_raise(RuntimeError)
			flexmock(CollectSnmp, :log => true)
			@poll_task.start_log("test.log")
		end
	end
end
