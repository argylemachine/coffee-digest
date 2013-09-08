log		= require( "logging" ).from __filename
async		= require "async"
find		= require "find"
util		= require "util"
fs		= require "fs"
coffee_script	= require "coffee-script"

directories = [ "./" ]

async.map directories, ( directory, cb ) ->
	find.file /\.coffee/, directory, ( files ) ->
		async.map files, ( file, cb ) ->
			fs.readFile file, { encoding: "utf8" }, ( err, data ) ->
				if err
					return cb err


				nodes = coffee_script.nodes data

				type_counter	= { }
				depths		= [ ]
				depth		= 0

				recursive_scan = ( node ) ->
	
					# We're starting a particular node, increment the
					# current depth
					depth++

					# Note that we're on this depth.
					depths.push depth

					# Get what type this node is..
					_type = node.constructor.name

					# Increment or set the type counter for the given
					# type..
					if not type_counter[_type]?
						type_counter[_type] = 1
					else
						type_counter[_type] += 1

					# Recruse down the tree.
					node.eachChild recursive_scan

					# We hit the end of the node.. decrement the current depth.
					depth--

				# Scan the nodes!
				recursive_scan coffee_script.nodes data

				# Calculate the average depth of the operations.
				# also graph the max and min.
				sum = 0
				sum += depth for depth in depths
				_depths = { "average": Math.round( sum / depths.length ), "max": Math.max.apply( null, depths ) }

				# Grab the number of lines both coffeescript and js.
				num_cs_lines = data.split("\n").length
				num_js_lines = coffee_script.compile( data ).length

				# Determine the ratio of cs to js lines.
				explode_ratio = num_js_lines / num_cs_lines

				# Define the object we'll contiue to abuse until we return it.
				_o = { "file": file, "ops": type_counter, "depths": _depths, "num_cs_lines": num_cs_lines, "num_js_lines": num_js_lines, "explode_ratio": explode_ratio }

				# At this point also compute each operation per line.
				for op, c of type_counter
					_o[op + "_pl"] = c / num_cs_lines

				# Return the object.
				return cb null, _o

		, cb

, ( err, res ) ->
	if err
		log "Fatal error: #{err}"
		process.exit 1

	# Just collapse the response arrays
	_res = [ ]
	_res.push file_detail for file_detail in detail_array for detail_array in res

	log "_res is #{util.inspect _res}"
