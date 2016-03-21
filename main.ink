#! /usr/bin/ink

import blueprint
import io
import multink
import "interface/sensor.ink"
import "interface/motor.ink"
import "interface/led.ink"
import "interface/sound.ink"
import "interface/general.ink"

p("init sensor map")
let sensor_map = iev3_Sensor_procList(iev3_Sensor.getList())
p("init motor map")
let motor_map = iev3_Motor_procList(iev3_Motor.getList())

/* some utils */
let sm_acc = fn (motor) {
	for (let i = 0, i < 100, i += 5) {
		motor.runDirect(i)
		receive() for(50)
	}
}

let sm2_acc = fn (m1, m2, max) {
	max ||= 60
	m1.runDirect(0); m2.runDirect(0)
	for (let i = 5, i < max, i += 5) {
		m1.setDutyCircleSpeed(i)
		m2.setDutyCircleSpeed(i)
		receive() for(50)
	}
}

let wait_for_stop = fn (motor) {
	while (1) {
		if (!motor.getState().running) {
			p("stop!!")
			break
		}
	}
}

let wait_stop_while_do = fn (motor, block) {
	while (1) {
		if (typename(block) == "function") {
			block()
		}
		if (!motor.getState().running) {
			p("stop!!")
			break
		}
	}
}

let wait_hold_while_do = fn (motor, block) {
	while (1) {
		if (typename(block) == "function") {
			block()
		}
		if (motor.getState().holding) {
			p("hold!!")
			break
		}
	}
}

let is_black = fn (v) {
	v >= 0 && v <= 13
}

require (let s1 = sensor_map[1].val,
		 let s2 = sensor_map[2].val,
		 let mB = motor_map.B.val,
		 let mC = motor_map.C.val) {
	// runDoubleRelat(mB, mC, 100, 3600)
	// p("yeah")
	sm2_acc(mB, mC, 40)

	let turn = 0 // -1 right, 0 no, 1 left
	let white_count = 0 // how many times the sensor is not black

	p("start")
	for (let i = 0, i < 150, i++) {
		if (is_black(s1.getValue())) {
			if (is_black(s2.getValue())) {
				mB.setDutyCircleSpeed(10)
				mC.setDutyCircleSpeed(10)
				turn = 0
				white_count = 0
			} else {
				mB.setDutyCircleSpeed(0)
				mC.setDutyCircleSpeed(40)
				turn = -1
				white_count = 0
			}
		} else {
			if (is_black(s2.getValue())) {
				mB.setDutyCircleSpeed(40)
				mC.setDutyCircleSpeed(0)
				turn = 1
				white_count = 0
			} else {
				// iev3_Sound_ESpeak("double white")
				white_count++
				if (turn != 0) {
					if (turn < 0) { // has turned left, then scan to right and left
						// p("finding trace, right then left")
						runDoubleRelat(mB, mC, 30, 300, 1, 1)
						let has_turned = 0
						wait_stop_while_do(mB) {
							if (is_black(s2.getValue())) {
								has_turned = 1
								mB.stop(); mC.stop()
								// p("found trace!")
							}
						}
						if (!has_turned) {
							runDoubleRelat(mB, mC, 1, 1, 30, 300)
							// p("couldn't find trace!")
						}
						mB.runDirect(0); mC.runDirect(0)
					} else if (turn > 0) { // has turned right, then scan to left and right
						// p("finding trace, left then right")
						runDoubleRelat(mB, mC, 1, 1, 30, 300)
						let has_turned = 0
						wait_stop_while_do(mB) {
							if (is_black(s1.getValue())) {
								mB.stop(); mC.stop()
								has_turned = 1
								mB.stop(); mC.stop()
								// p("found trace!")
							}
						}
						if (!has_turned) {
							runDoubleRelat(mB, mC, 50, 300, 1, 1)
							// p("couldn't find trace!")
						}
						mB.runDirect(0); mC.runDirect(0)
					}
				} else if (white_count >= 30) {
					p("too much white, finding trace")
					let has_turned = 0

					runDoubleRelat(mB, mC, 30, -80, 30, -80)
					wait_for_stop(mB)
					mB.stop(); mC.stop()
					p("back done")
					p("scan to right")
					runDoubleRelat(mB, mC, 30, 150, 1, 1)
					wait_stop_while_do(mB) {
						if (is_black(s1.getValue()) || is_black(s2.getValue())) {
							has_turned = 1
							mB.stop(); mC.stop()
							p("found trace!")
						}
					}
					p("scan right done")
					if (!has_turned) {
						p("scan to left")
						runDoubleRelat(mB, mC, 1, 1, 30, 150)
						wait_stop_while_do(mC) {
							if (is_black(s1.getValue()) || is_black(s2.getValue())) {
								has_turned = 1
								mB.stop(); mC.stop()
								p("found trace!")
							}
						}
						p("scan left done")

						if (!has_turned) {
							p("couldn't find trace!")
						}
					}
					mB.runDirect(0); mC.runDirect(0)
				}

				mB.setDutyCircleSpeed(30)
				mC.setDutyCircleSpeed(30)
				turn = 0
			}
		}
	}
	mB.stop(); mC.stop()
}
