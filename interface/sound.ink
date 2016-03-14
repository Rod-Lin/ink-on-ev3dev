#! /usr/bin/ink

import blueprint
import blueprint.sys
import io
import "constants.ink"

let iev3_Sound_ESpeak = fn (text, aml, args) {
	aml = aml || 200
	args = args || ""
	sys.cmd("espeak -a " + aml.to_str() + " " + args.to_str() + " \"" + text + "\" --stdout | aplay")
}
