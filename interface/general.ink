#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

let iev3_Port = fn (port_name) {
	let dec = port_name.split(":")
	let i = 0

	this.type = "unknown"
	this.id = -1
	this.is_mux = 0
	this.mux_id = -1
	this.interface = "unknown"

	dec.each { | val |
		if (val.substr(0, 2) == "in") {
			this.type = "in"
			this.id = numval(val.substr(2))
		} else if (val.substr(0, 3) == "out") {
			this.type = "out"
			this.id = val.substr(3)
		} else if (val.substr(0, 3) == "mux") {
			this.is_mux = 1
			this.mux_id = numval(val.substr(3))
		} else if (i == 2 && val != "") {
			this.interface = val
		}
		i++
	}
}

let require = fn (args...) {
	let block = args.last()
	let run = 1
	args.each { | val |
		if (val == undefined || val == null) {
			p("Require failed")
			run = 0
			if (typename(block) != "function") {
				exit
			}
		}
	}
	if (run && typename(block) == "function") {
			block()
	}
}
