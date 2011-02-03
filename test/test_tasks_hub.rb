#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/helper'

class TasksHubTest < Test::Unit::TestCase
	include TestData
	
	context "#hub" do 
		setup do
			load_testdata
			CollectSnmp::load(@data, @hosts, @writers, @rrd_tasks)
			@current_task = CollectSnmp::Tasks.list[@rrd_tasks[0]['config']['name']]
			@current_task.instance_variable_set(:@logh, $stdout)
			flexmock("current_task", @current_task)
			#flexmock("current_task_thread", @current_task.thread)
			@hub_task = CollectSnmp::Tasks.hub
			@hub_task.instance_variable_set(:@logh, $stdout)
			flexmock("hub_task", @hub_task)
		end
		
		should "A: run correctly" do
			log_path = @hub_task.instance_variable_get(:@log_path)
			filepath = [log_path, ["hub", "log"].join(".")].join("/")
			flexmock(File).should_receive(:directory?).with(log_path).once.and_return(true)
			flexmock(File).should_receive(:exists?).with(filepath).once.and_return(true)
			flexmock(File).should_receive(:open).with(filepath, "a").once.and_return($stdout)
			@current_task.should_receive(:run).and_return(true)
			@current_task.thread = flexmock("current_task_thread", :run => true)
			@hub_task.should_receive(:continue_loop?).times(1).and_return(false)
			@hub_task.should_receive(:sleep).and_return(true) 
			@hub_task.run
		end
	end
end