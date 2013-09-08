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

				ops = { }
				recursive_populate = ( node ) ->
					node.eachChild recursive_populate

					_op = node.constructor.name
					if not ops[_op]?
						ops[_op] = 1
					else
						ops[_op] += 1

				recursive_populate coffee_script.nodes data

				return cb null, {"file": file, "ops": ops}

		, cb

, ( err, res ) ->
	if err
		log "Fatal error: #{err}"
		process.exit 1
	log "I have res of #{util.inspect res[0], true, 9}"
