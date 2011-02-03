#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/helper'

class WritersCSVTest < Test::Unit::TestCase
	include TestData
	
	context "#write_csv" do
		setup do
			load_testdata
			CollectSnmp::load(@data, @hosts, @csv_writers, @csv_tasks)
			CollectSnmp::Tasks.list['collect-host1'].instance_variable_set(:@logh, $stdout)
			@current_writer = CollectSnmp::Writers.list[@csv_writers[0]['config']['name']]
			@current_task = CollectSnmp::Tasks.list[@csv_tasks[0]['config']['name']]
			@current_task.instance_variable_set(:@logh, $stdout)
		end
		
		should "A: create directories correctly" do
			flexmock(File).should_receive(:directory?).with(String).times(@current_task.data.length + 1).and_return(true)
			flexmock(FileUtils).should_receive(:mkpath).never
			@current_writer.create_directories(@current_task.host, @current_task.data, @current_task)
			@current_writer.start(@current_task.host, @current_task.data, @current_task)
			flexmock(File).should_receive(:directory?).with(String).times(@current_task.data.length).and_return(false)
			flexmock(FileUtils).should_receive(:mkpath).times(@current_task.data.length).and_return(true)
			@current_writer.create_directories(@current_task.host, @current_task.data, @current_task)
			flexmock(File).should_receive(:directory?).with(String).times(@current_task.data.length).and_raise(RuntimeError)
			flexmock(FileUtils).should_receive(:mkpath).never
			@current_writer.create_directories(@current_task.host, @current_task.data, @current_task)
			flexmock(File).should_receive(:directory?).with(String).times(@current_task.data.length).and_return(false)
			flexmock(FileUtils).should_receive(:mkpath).times(@current_task.data.length).and_raise(RuntimeError)
			@current_writer.create_directories(@current_task.host, @current_task.data, @current_task)
		end
		
		should "B: update file correctly" do
			mock_fh1 = flexmock("mock1")
			mock_fh1.should_receive(:puts).with(String).times(2).and_return(true)
			mock_fh1.should_receive(:close).and_return(true)
			mock_fh2 = flexmock("mock2")
			mock_fh2.should_receive(:puts).and_raise(RuntimeError)
			mock_fh2.should_receive(:close).and_return(true)
			flexmock(File).should_receive(:open).with(String, "a+").times(3).and_return(mock_fh1, mock_fh1, mock_fh2)
			@current_writer.update(@current_task.host.name, @snmp_last, @current_task)
			@current_writer.update(@current_task.host.name, @snmp_last, @current_task)
			@current_writer.update(@current_task.host.name, @snmp_last_stale, @current_task)
			@current_writer.write(@current_task.host.name, @snmp_last, @current_task) 
		end
	end
end
