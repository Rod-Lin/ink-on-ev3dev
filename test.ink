#! /usr/bin/ink

import blueprint
import io
import multink
import "interface/sensor.ink"
import "interface/motor.ink"
import "interface/led.ink"
import "interface/sound.ink"
import "interface/general.ink"

$file.putln = fn (str) {
	base.puts(str.to_str() + "\n")
}

$file.putsp = fn (str) {
	base.puts(str.to_str() + " ")
}

$array.p = fn (args...) {
	let prefix = ""
	if (args.size()) {
		prefix = args[0];
	}

	p(prefix + "{");
	base.each() { | elem |
		if (elem.p) {
			elem.p(prefix + "  ");
		} {
			p(prefix + "  " + elem + ",");
		}
	}
	p(prefix + "}");
}

$numeric.times = fn (block) {
	for (let i = 0, i < base, i++) {
		block()
	}
}

//sensor_1_mux3 = new iev3_Sensor(17);
//sensor_1_mux2 = new iev3_Sensor(9);
//sensor_1_mux3 = new iev3_Sensor(11);

//p(sensor_1_mux3.getValue())
//p(sensor_1_mux2.getValue())
//p(sensor_1_mux3.getValue())
//iev3_Motor.getList().each(p(_))

(let sensor_list = iev3_Sensor.getList()).each { | val |
	stdout.puts("" + val.id + ": ")
	let port = new iev3_Port(val.port_name)
	stdout.putsp(port.type)
	stdout.putsp(port.id)
	stdout.putsp(port.is_mux)
	stdout.putln(port.mux_id)
}

(let motor_list = iev3_Motor.getList()).each { | val |
	stdout.puts("" + val.id + ": ")
	let port = new iev3_Port(val.port_name)
	stdout.putsp(port.type)
	stdout.putsp(port.id)
	stdout.putsp(port.is_mux)
	stdout.putln(port.mux_id)
}

let sensor1 = null
let sensor2 = null

sensor_list.each { | val |
	let port = new iev3_Port(val.port_name)
	if (port.type == "in" && port.is_mux) {
		let tmp_sensor = new iev3_Sensor(val.id)
		p(tmp_sensor.getValue())
	} else if (port.type == "in" && port.id == "1") {
		sensor1 = new iev3_Sensor(val.id)
	} else if (port.type == "in" && port.id == "2") {
		sensor2 = new iev3_Sensor(val.id)
	}
}

let motorB = null
let motorC = null
let motorA = null

motor_list.each { | val |
	let port = new iev3_Port(val.port_name)
	if (port.type == "out" && port.id == "B") {
		motorB = new iev3_Motor(val.id);
	} else if (port.type == "out" && port.id == "C") {
		motorC = new iev3_Motor(val.id);
	} else if (port.type == "out" && port.id == "A") {
		motorA = new iev3_Motor(val.id);
	}
}

//motorB.stop(100)

//motorB.runTimed(10, 3000)
//motorC.runTimed(100, 3000)

//motorC.reset()
//motorB.reset()

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

let led_rainbow = fn () {
	let backup = iev3_LED_getLEDState()

	for (let i = 255, i > 0, i -= 5) {
		iev3_LED_setBrightness("left", "red", i)
	}
	for (let i = 0, i < 255, i += 5) {
		iev3_LED_setBrightness("left", "green", i)
	}

	iev3_LED_setLEDState(backup)
}

let led_alert = fn (count, max_bright) {
	max_bright = max_bright || 255

	let backup = iev3_LED_getLEDState()

	for (let i = 0, i < count, i++) {
		if (i % 2) {
			iev3_LED_setBrightness("left", "red", max_bright)
			iev3_LED_setBrightness("right", "red", max_bright)
			iev3_LED_setBrightness("left", "green", 0)
			iev3_LED_setBrightness("right", "green", 0)
		} else {
			iev3_LED_setBrightness("left", "green", max_bright)
			iev3_LED_setBrightness("right", "green", max_bright)
			iev3_LED_setBrightness("left", "red", 0)
			iev3_LED_setBrightness("right", "red", 0)
		}
	}

	iev3_LED_setLEDState(backup)
}

let scan_by = fn (motor, dis, part, do_block) {
	let unit = (dis / part).floor()
	let i = 0
	let judge = fn () { i < dis }

	if (dis < 0) {
		judge = fn () { i > dis }
	}

	for (i = 0, judge(), i += unit) {
		motor.runRelat(40, unit, "hold")
		wait_hold_while_do(motor, do_block)
	}
	motor.stop()
}

/* offset: look from head to tail: 
 * offset > 0: sensor on the right
 * offset < 0: sensor on the left
 * unit: cm
 */
let scan_scanner_offset = 5
let scan_is_black = fn (val) { val < 15 }

let times_array = fn (time, val) {
	ret = new Array()
	time.times {
		ret.push(val)
	}
	ret
}

let compress_data = fn (data) {
	let ret = new Array()

	for (let i = 0, i < data.size(), i++) {
		if (data[i] == 1) {
			let count = 1
			for (0, ++i < data.size() && data[i] == 1, count++)
			while (i + 1 < data.size() && data[i + 1] == 1) {
				/* case like 11101 */
				/*              ^  */
				for (0, ++i < data.size() && data[i] == 1, count++)
			}
			ret.push(count)
			i--
		} else {
			let count = -1
			for (0, ++i < data.size() && data[i] == 0, count--)
			ret.push(count)
			i--
		}
	}

	ret
}

let choose_left_offset = 0
let choose_right_offset = 1

let choose_first = fn (cdata) {
	let left_w = 0
	let right_w = 0

	for (let i = 0, i < cdata.size() && cdata[i] < 0, i++) {
		left_w -= cdata[i]
	}

	while (i < cdata.size()) {
		for (0, i < cdata.size() && cdata[i] >= 0, i++)

		for (0, i < cdata.size() && cdata[i] < 0, i++) {
			right_w -= cdata[i]
		}
	}

	[left_w + choose_left_offset, right_w + choose_right_offset]
}

let apply_to_motor = fn (data) {
	let base_num = 5
	require(motorB, motorC) {
		motorB.runRelat(100, data[0] * 5)
		motorC.runRelat(100, data[1] * 5)
		wait_for_stop(motorB)
		wait_for_stop(motorC)
	}
}

//runDoubleRelat(motorB, motorC, 100, 3600)

let is_black = fn (v) {
	v >= 0 && v <= 15
}

require (motorB, motorC, sensor1, sensor2) {
	sm2_acc(motorB, motorC, 40)
	p("start")
	for (let i = 0, i < 150, i++) {
		if (is_black(sensor1.getValue())) {
			if (is_black(sensor2.getValue())) {
				motorB.setDutyCircleSpeed(10)
				motorC.setDutyCircleSpeed(10)
			} else {
				motorB.setDutyCircleSpeed(0)
				motorC.setDutyCircleSpeed(60)
			}
		} else {
			if (is_black(sensor2.getValue())) {
				motorB.setDutyCircleSpeed(60)
				motorC.setDutyCircleSpeed(0)
			} else {
				// iev3_Sound_ESpeak("double white")
				motorB.setDutyCircleSpeed(30)
				motorC.setDutyCircleSpeed(30)
			}
		}
	}
}

let get_ratio = fn (data) {
	let bin_data = new Array()
	data.each { | val |
		if (scan_is_black(val)) {
			bin_data.push(1) // black
		} else {
			bin_data.push(0)
		}
	}
	compress_data(bin_data)
}

require(motorA, sensor1, null) {
	let cdata = null

	for (let j = 0, j < 5, j++) {
		let data = new Array()
		for (let i = 0, i < 1, i++) {
			/*motorA.runRelat(25, -100)
			wait_stop_while_do(motorA) {
				data.last().push(sensor1.getValue())
				//p("la~~")
			}

			data.push(new Array())
			motorA.runRelat(25, 107)
			wait_stop_while_do(motorA) {
				data.last().push(sensor1.getValue())
				//p("wu~~")
			}*/
			
			scan_by(motorA, -80, 10) {
				data.push(sensor1.getValue())
			}
			motorA.runRelat(50, 85)
			wait_for_stop(motorA)
		}
		data.p()
		(cdata = choose_first(get_ratio(data))).p()
		apply_to_motor(cdata)
	}
}

if (0) {
	iev3_Sound_ESpeak("Welcome to, ink, on E V 3 dev.")
	// iev3_Sound_ESpeak("其实我会说中文", 200, "-vzh")

	iev3_Sound_ESpeak("L E D")
	iev3_Sound_ESpeak("测试", 200, "-vzh")

	iev3_LED_setLEDState({ l_g: 255, l_r: 0, r_g: 255, r_r: 0 })

	led_rainbow()
	led_alert(10)

	iev3_Sound_ESpeak("电机测试", 200, "-vzh")

	require(motorC)

	motorC.runRelat(100, 1080)
	wait_for_stop(motorC)

	iev3_Sound_ESpeak("电机转动完成", 200, "-vzh")

	p("end!")

	iev3_Sound_ESpeak("智能加速测试", 200, "-vzh")

	sm_acc(motorC)
	receive() for(3000)
	motorC.stop()

	iev3_Sound_ESpeak("刹车模式测试", 200, "-vzh")

	motorC.runForever(100)
	receive() for(1000)
	motorC.stop("hold")

	motorC.runForever(100)
	receive() for(1000)
	motorC.stop()

	iev3_Sound_ESpeak("其他测试", 200, "-vzh")

	motorC.runRelat(100, 360)
	motorB.runRelat(100, 360)

	receive() for(1000)

	require(motorB)

	motorC.runRelat(100, 360)
	motorB.runRelat(100, 360)

	receive() for(1000)

	motorC.runDirect(20)
	motorB.runDirect(40)

	receive() for(1000)

	motorC.setDutyCircleSpeed(50)
	motorB.setDutyCircleSpeed(100)

	receive() for(1000)

	motorC.stop()
	motorB.stop()

	iev3_Sound_ESpeak("电机测试结束", 200, "-vzh")
	iev3_Sound_ESpeak("所有测试结束, 白白", 200, "-vzh")
}

/*
iev3_Motor.getList().each { | val |
	p("" + val.id + ": " + val.port_name)
	let port = new iev3_Port(val.port_name)
	stdout.putsp(port.type)
	stdout.putsp(port.id)
	stdout.putsp(port.is_mux)
	stdout.putln(port.mux_id)
}
*/
