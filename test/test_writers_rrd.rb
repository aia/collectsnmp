#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)

require 'helper'

class WritersRRDTest < Test::Unit::TestCase
	include TestData
	
	context "#write_rrd" do
		setup do
			load_testdata
			CollectSnmp::load(@data, @hosts, @writers, @rrd_tasks)
			CollectSnmp::Tasks.list['collect-host1'].instance_variable_set(:@logh, $stdout)
			@current_writer = CollectSnmp::Writers.list[@writers[0]['config']['name']]
			@current_task = CollectSnmp::Tasks.list[@rrd_tasks[0]['config']['name']]
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
		
		should "B: create files correctly" do
			mock_rrd = flexmock()
			mock_rrd.should_receive(:create).times(1).and_return(true)
			@current_writer.instance_variable_set(:@rrd_ref, mock_rrd)
			flexmock(File).should_receive(:exists?).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd").
				times(3).and_return(true, false, false)
			@current_writer.create_files(@current_task.host.name, @snmp_last, @current_task)
			@current_writer.create_files(@current_task.host.name, @snmp_last, @current_task)
			mock_rrd = flexmock()
			mock_rrd.should_receive(:create).times(1).and_raise(RuntimeError)
			@current_writer.instance_variable_set(:@rrd_ref, mock_rrd) 
			@current_writer.create_files(@current_task.host.name, @snmp_last, @current_task)
		end
		
		should "C: update file correctly" do
			mock_rrd = flexmock()
			mock_rrd.should_receive(:update).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd",
				"N:1617125152:1617125151").times(1).and_return(true)
			@current_writer.instance_variable_set(:@rrd_ref, mock_rrd)
			@current_writer.update(@current_task.host.name, @snmp_last, @current_task)
			
			mock_rrd = flexmock()
			mock_rrd.should_receive(:update).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd",
				"N:1617125152:1617125151").times(1).and_raise(RuntimeError)
			@current_writer.instance_variable_set(:@rrd_ref, mock_rrd)
			@current_writer.update(@current_task.host.name, @snmp_last, @current_task)
			
			mock_rrd = flexmock()
			mock_rrd.should_receive(:update).never
			@current_writer.instance_variable_set(:@rrd_ref, mock_rrd)
			@current_writer.update(@current_task.host.name, @snmp_last_stale, @current_task)
		end
		
		should "D: correctly run write" do
			mock_rrd = flexmock()
			mock_rrd.should_receive(:create).times(1).and_return(true)
			mock_rrd.should_receive(:update).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd",
				"N:1617125152:1617125151").times(1).and_return(true)
			@current_writer.instance_variable_set(:@rrd_ref, mock_rrd)
			flexmock(File).should_receive(:exists?).with("/some/data/path/host1/ifmib-if-octets64/Vlan-999.rrd").
				times(1).and_return(false)
			@current_writer.write(@current_task.host.name, @snmp_last, @current_task)
		end
	end
end
