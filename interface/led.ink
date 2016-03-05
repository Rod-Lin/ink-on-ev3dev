#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

iev3_LED_getPathOf = fn (direct, color) { /* direct: left/right; color: red/green */
	iev3_LEDPath + "/ev3:" + direct.to_str() + ":" + color.to_str() + ":ev3dev";
}

iev3_LED_setBrightness = fn (direct, color, bright) {
	new File(iev3_LED_getPathOf(direct, color) + "/brightness", "w").puts(bright.to_str())
}

iev3_LED_getBrightness = fn (direct, color) {
	let tmp = new File(iev3_LED_getPathOf(direct, color) + "/brightness", "r").gets()
	numval(tmp.substr(0, tmp.length() - 1))
}

iev3_LED_getLEDState = fn () {
	{
		l_g: iev3_LED_getBrightness("left", "green"),
		l_r: iev3_LED_getBrightness("left", "red"),
		r_g: iev3_LED_getBrightness("right", "green"),
		r_r: iev3_LED_getBrightness("right", "red")
	}
}

iev3_LED_setLEDState = fn (state) {
	if (state.l_g && state.l_r && state.r_g && state.r_r) {
		iev3_LED_setBrightness("left", "green", state.l_g)
		iev3_LED_setBrightness("left", "red", state.l_r)
		iev3_LED_setBrightness("right", "green", state.r_g)
		iev3_LED_setBrightness("right", "red", state.r_r)
	}
}
