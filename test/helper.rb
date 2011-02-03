$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'collectsnmp'
require 'shoulda'
require 'flexmock'
require 'pp'

module TestData
	include FlexMock::TestCase
	
	def load_testdata
		@data = [{
				"name"  => "ifmib-if-octets64",
				"instance" => "1.3.6.1.2.1.31.1.1.1.1",
				"values" => "1.3.6.1.2.1.31.1.1.1.6 1.3.6.1.2.1.31.1.1.1.10",
				"dst" => "COUNTER",
				"range" => "0:U"
		}]
		@hosts = [{
				"name"  => "host1",
				"idprefix" => "111",
				"address" => "10.127.1.3",
				"version" => "2c",
				"community" => "ryspebalispu"
		}]
		@writers = [
		{
			"type" => "RRD",
			"config"  => {
				"name" => "RRD1",
				"rra" => "RRA:AVERAGE:0.5:1:4608 RRA:AVERAGE:0.5:5:4032",
				"write_path" => "/some/data/path",
				"interval" => "150"
			}
		}
		]
		@rrd_tasks = [{
			"type" => "Poll",
			"config"  => {
				"name" => "collect-host1",
				"data" => "ifmib-if-octets64",
				"host" => "host1",
				"log_path" => "/some/data/path",
				"log_level" => 3,
				"interval" => "150",
				"writers" => "RRD1"
			}
		}]
		@drraw_tasks = [{
			"type" => "Drraw",
			"config"  => {
				"name" => "drraw",
				"log_path" => "/some/data/path",
				"log_level" => 4,
				"drraw_path" => "/some/data/path",
				"rrd_path" => "/some/data/path",
				"erb_path" => "/some/data/path",
				"interval" => "150",
			}
		}]
		@snmp_var = [
			[
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 1, 1107788775],
				:value => "Vlan 999"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 6, 1107788775],
				:value => "1617125152"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 10, 1107788775],
				:value => "1617125151"
			)
			],
			[
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 1, 1107788775],
				:value => "Vlan 999"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 6, 1107788775],
				:value => "1617125154"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 10, 1107788775],
				:value => "1617125153"
			)
			],
			[
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 1, 1107788776],
				:value => "Vlan 111"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 6, 1107788776],
				:value => "1617125154"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 10, 1107788776],
				:value => "1617125155"
			)
			],
			[
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 1, 1107788776],
				:value => "Vlan 111"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 6, 1107788776],
				:value => "1617125157"
			),
			flexmock(
				:name => [1, 3, 6, 1, 2, 1, 31, 1, 1, 1, 10, 1107788776],
				:value => "1617125156"
			)
			]
		]
		@snmp_last = {
			"ifmib-if-octets64.1.3.6.1.2.1.31.1.1.1.1.1107788775" =>
			flexmock(
				:data  => flexmock(
					:dst  => "COUNTER",
					:instance => "1.3.6.1.2.1.31.1.1.1.1",
					:name => "ifmib-if-octets64",
					:range => "0:U",
					:values => ["1.3.6.1.2.1.31.1.1.1.6", "1.3.6.1.2.1.31.1.1.1.10"]
				),
				:is_new => 1,
				:is_new= => true,
				:is_updated => 1,
				:is_updated= => true,
				:name => "Vlan-999",
				:values => ["Vlan 999", "1617125152", "1617125151"]
			)
		}
		@snmp_last_stale = {
			"ifmib-if-octets64.1.3.6.1.2.1.31.1.1.1.1.1107788776" =>
			flexmock(
				:data  => flexmock(
					:dst  => "COUNTER",
					:instance => "1.3.6.1.2.1.31.1.1.1.1",
					:name => "ifmib-if-octets64",
					:range => "0:U",
					:values => ["1.3.6.1.2.1.31.1.1.1.6", "1.3.6.1.2.1.31.1.1.1.10"]
				),
				:is_new => 1,
				:is_new= => true,
				:is_updated => 0,
				:is_updated= => true,
				:name => "Vlan-111",
				:values => ["Vlan 111", "1617125154", "1617125155"]
			)
		}
		@drraw_var = [
			"g1294881337.15444:HOST2/ifmib-if-octets64/Vlan-302",
			"g1294881337.112111:HOST1/ifmib-if-octets64/GigabitEthernet-1-10",
			"g1294881337.113111:HOST1/ifmib-if-octets64/GigabitEthernet-1-11",
			"ohai"
		]
		@drraw_paths = [
			"/some/data/path/host1/ifmib-if-octets64/GigabitEthernet-1-10.rrd",
			"/some/data/path/host1/ifmib-if-octets64/GigabitEthernet-1-11.rrd",
			"/some/data/path/host2/ifmib-if-octets64/GigabitEthernet-1-10.rrd",
			"/some/data/path/host2/ifmib-if-octets64/GigabitEthernet-1-11.rrd",
			"/somethingnotparsablehost2GigabitEthernet-1-11.rrd"
		]
		@idrraw = [
		{
			"HOST1/ifmib-if-octets64/GigabitEthernet-1-10" => flexmock(
				:comment => "",
				:data => "ifmib-if-octets64",
				:dindex => 112,
				:gindex => "1294881337",
				:host => "HOST1",
				:name => "GigabitEthernet-1-10"
			)
		},
		{
			"HOST1/ifmib-if-octets64/GigabitEthernet-1-10" => flexmock(
				:comment => "",
				:data => "ifmib-if-octets64",
				:dindex => 112,
				:gindex => "1294881337",
				:host => "HOST1",
				:name => "GigabitEthernet-1-10"
			),
			"HOST1/ifmib-if-octets64/GigabitEthernet-1-11" => flexmock(
				:comment => "somecomment",
				:data => "ifmib-if-octets64",
				:dindex => 113,
				:gindex => "1294881337",
				:host => "HOST1",
				:name => "GigabitEthernet-1-11"
			),
			"HOST1/ifmib-if-octets64/GigabitEthernet-1-12" => flexmock(
				:comment => "",
				:data => "",
				:dindex => 114,
				:gindex => "1294881337",
				:host => "HOST1",
				:name => "GigabitEthernet-1-12"
			)
		}
		]
		@csv_writers = [
			{
				"type" => "CSV",
				"config"  => {
					"name" => "CSV1",
					"write_path" => "/some/data/path"
				}
			}
		]
		@csv_tasks = [{
			"type" => "Poll",
			"config"  => {
				"name" => "collect-host1",
				"data" => "ifmib-if-octets64",
				"host" => "host1",
				"log_path" => "/some/data/path",
				"log_level" => 4,
				"interval" => "150",
				"writers" => "CSV1"
			}
		}]
	end
end
