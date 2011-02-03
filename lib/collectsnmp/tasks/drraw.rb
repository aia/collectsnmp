module CollectSnmp
	module Tasks
		class Drraw < Base
			# +drraw_path+ stores the filesystem path to DRRAW installation
			attr_accessor :drraw_path
			# +rrd_path+ stores the path to RRD root folder 
			attr_accessor :rrd_path
			# +erb_path+ has the path to ERB templates
			attr_accessor :erb_path
			# +idrraw+ contains a list of DRRAW objects
			attr_accessor :idrraw
			# +hid+ is a variable to store the host's index
			attr_accessor :hid
			# +hmd+ is a variable to store the graph's index
			attr_accessor :hmd
			# +changed+ contains a flag indicating if a list of DRRAW object changed
			attr_accessor :changed
			# +erb_ref+ is a reference to ERB object
			attr_accessor :erb_ref

			# Class constructor
			def initialize(hash)
				super(hash['name'], hash['interval'], hash['log_path'])
				hash['log_level'] ? @log_level = hash['log_level'] : true
				@drraw_path = hash['drraw_path']
				@rrd_path = hash['rrd_path']
				@erb_path = hash['erb_path']
				@idrraw = {}
				@hid = {}
				@hmd = {}
				@changed = 0
				@continue_loop = true
				@erb_ref = Object.const_get(:ERB)
			end

			# Standard task run method
			def run
				# Start logging
				start_log([@name, "log"].join('.'))
				# Start a thread
				@thread = Thread.new {
					# Set the thread's name
					Thread.current["name"] = @name
					# Start a loop
					begin 
						log("DRRAW index started: #{self}")
						begin
							# Load DRRAW index
							index_drraw
							# Index RRD folders 
							index_rrd
							# If new DRRAW objects created
							if (@changed == 1)
								log("DRRAW index changed, writing")
								# Write index
								write_index
							end
						rescue Exception => except
							# Catch and report exceptions
							ehandle(except)
						end
						
						# Reset TTL
						@ttl = @interval
						
						log("DRRAW index finished: #{self}")
						# Stop the thread
						Thread.stop
					# Continue to loop if the condition is set
					end until (!continue_loop?)
				}
			end

			# Parse DRRAW index file
			def index_drraw
				if (File.exists?(@drraw_path + "/index"))
					begin
						log("started indexing drraw")
						drraw_index = File.read(@drraw_path + "/index")
						@idrraw = {}
						drraw_index.each do |index|
							log("Entry #{index}")
							parse_drraw_index_entry(index) 
						end
						log("finished indexing drraw")
					rescue Exception => except
						# Catch and report exceptions
						ehandle(except)
					end
				end
			end

			# Add a template for an index entry
			def add_template(template, idx, host, data, name, comment) 
				if (@idrraw[idx] == nil)
					log("Index does not exist")
					return
				end
				log("Adding with a DRRAW template: #{template}")
				@drrawfilename = [@rrd_path.gsub(/\//,"%2F"), host, data, "", name].join("%2F") + ".rrd"
				log("RRD filename #{@drrawfilename}")
				if (comment == "")
					@drrawtitle = [host.upcase, data, name].join("%2F")
				else
					@drrawtitle = [[host.upcase, data, name].join("%2F"), "-", 
						comment.gsub(/ /,"%20")].join("%20")
				end
				log("DRRAW title #{@drrawtitle}")
				erb_template_content = File.read(template);
				erb_output = @erb_ref.new(erb_template_content)
				log("ERB output #{erb_output}")
				begin
					drraw_graph = [@drraw_path, "/g", @idrraw[idx].gindex, ".", @idrraw[idx].dindex.to_s,
						CollectSnmp::hosts[host.downcase].idprefix].join
					drraw_graph_content = File.open(drraw_graph , "w")
					log("drraw opened #{drraw_graph}")
					erb_formatted = erb_output.result(self.send("binding"))
					drraw_graph_content.puts(erb_formatted)
					log("drraw printed result")
					drraw_graph_content.close
				rescue Exception => except
					ehandle(except)
				end
			end

			# Index RRD foler
			def index_rrd
				if (!File.directory?(@rrd_path)) 
					return
				end
				log("started indexing rrds")
				Find.find(@rrd_path) do |path|
					if (File.directory?(path))
						next
					end
					host, data, name = path.match(/#{@rrd_path}\/?(.+)\/(.+)\/(.+)\.rrd/).to_a[1..3]
					if ((host == nil) || (data == nil) || (name == nil)) 
						log("Unable to match the string")
						log("#{p}")
						next
					end
					log("#{host}, #{data}, #{name}")
					curid = [host.upcase, data, name].join("/")
					if (@idrraw[curid] == nil) 
						log("Index not found")
						log("#{curid}")
						if (File.exists?([@erb_path, "/", data, ".erb"].join))
							log("Template found")
							add_index_entry(host, data, name, curid)
						end
					else
						log("Index found")
						check_index_entry(host, data, name, curid)
					end
				end
				log("finished indexing rrds")
			end

			# Write DRRAW index
			def write_index
				# Open DRRAW index for writing
				drrawfh = File.open(@drraw_path + "/index", "w")
				@idrraw.each_value do |id|
					if (id.data == "")
						val = [id.gindex, ":", id.host].join
						drrawfh.puts("#{val}")
					else
						if (id.comment == "")
							val = ["g", id.gindex, ".", id.dindex.to_s, 
								CollectSnmp::hosts[id.host.downcase].idprefix,
								":", [id.host.upcase, id.data, id.name].join("/")].join
						else
							val = ["g", id.gindex, ".", id.dindex.to_s, 
								CollectSnmp::hosts[id.host.downcase].idprefix, 
								":", [id.host.upcase, id.data, id.name].join("/"), 
								" - ", id.comment].join
						end
						drrawfh.puts("#{val}")
					end
				end
				@changed = 0
				# Close DRRAW index file handle
				drrawfh.close
			end

			# Easy printing
			def to_s
				[@name, @interval, @changed, @ttl].join(": ")
			end
			
			def update_host_indexes(host, dindex, gindex)
				if (@hid[host] != nil)
					if (@hid[host] < dindex.to_i) 
						@hid[host] = dindex.to_i
					end
				else
					@hid[host] = dindex.to_i
				end
				if (@hmd[host] == nil)
					@hmd[host] = gindex
				end
			end

			private

			def get_host_indexes(host)
				if (@hmd[host] == nil)
					gindex = Time.now.to_i.to_s
					@hmd[host] = gindex
				else
					gindex = @hmd[host]
				end
				if (@hid[host.upcase] == nil)
					dindex = 1
					@hid[host.upcase] = 1
				else
					@hid[host.upcase] += 1
					dindex = @hid[host.upcase]
				end
				return [dindex, gindex]
			end

			def parse_drraw_index_entry(entry)
				gindex, din, host, data, coname = 
					entry.match(/g(\d+)\.(\d+):(.+)\/(.+)\/(.+)/).to_a[1..5]
				if ((gindex == nil) || (din == nil) || (host == nil) || 
					(coname == nil) || (CollectSnmp::hosts[host.downcase] == nil))
					log("Couldn't parse the entry. Treating as custom")
					gindex, host = entry.split(':')
					if ((gindex == nil) || (host == nil))
						log("Couldn't parse entry at all")
					else
						@idrraw[host] = CollectSnmp::Records::Drraw.new(
							host, "", "", gindex, 0, ""
						)
					end
					# Get the next record
					return 
				end
				
				log("Entry parsed")
				
				suffix = CollectSnmp::hosts[host.downcase].idprefix
				
				dindex = din.match(/(\d+)#{suffix}$/).to_a[1]
				name, comment = coname.split(/ - /, 2)
				if (comment == nil)
					comment = ""
				end
				log("#{host}, #{data}, #{name}, #{gindex}, #{dindex}, #{comment}") 
				@idrraw[[host, data, name].join("/")] = 
					CollectSnmp::Records::Drraw.new(
						host, data, name, gindex, dindex.to_i, comment
					)
					
				update_host_indexes(host, dindex, gindex)
			end
			


			def check_index_entry(host, data, name, curid)
				log("Checking file dindex #{@idrraw[curid].dindex.to_s}")
				drraw_graph = [@drraw_path, "/g", @idrraw[curid].gindex, ".", 
					@idrraw[curid].dindex.to_s, 
					CollectSnmp::hosts[host.downcase].idprefix].join
				log("#{drraw_graph}")
				if (File.exists?(drraw_graph))
					log("Drraw file found")
				else
					log("Drraw file not found")
					if (File.exists?([@erb_path, "/", data, ".erb"].join))
						log("Template found")
						add_template([@erb_path, "/", data, ".erb"].join, 
							[host.upcase, data, name].join("/"), 
							host, data, name, @idrraw[curid].comment)
					else
						log("Template not found")
					end
				end
			end

			def add_index_entry(host, data, name, curid)
				dindex, gindex = get_host_indexes(host)
				new_index = CollectSnmp::Records::Drraw.new(
					host, data, name, gindex, dindex, ""
				)
				log("New index #{new_index.to_s}")
				if (CollectSnmp::hosts[host.downcase] != nil)
					@idrraw[curid] = new_index
					add_template([@erb_path, "/", data, ".erb"].join, 
						[host.upcase, data, name].join("/"), host, data, name, "")
					@changed = 1
				else
					log("Unknown host, skipping")
				end
			end
		end 
	end
end
