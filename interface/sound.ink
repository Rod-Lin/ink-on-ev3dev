#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

iev3_Sound_ESpeak = fn (text, aml, args) {
	aml = aml || 200
	args = args || ""
	sys.cmd("espeak -a " + aml.to_str() + " " + args.to_str() + " \"" + text + "\" --stdout | aplay")
}