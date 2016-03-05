#! /usr/bin/ink

import blueprint
import io
import multink
import "interface/sensor.ink"
import "interface/motor.ink"
import "interface/led.ink"
import "interface/general.ink"

`$io.file.File`.putln = fn (str) {
	base.puts(str.to_str() + "\n")
}

`$io.file.File`.putsp = fn (str) {
	base.puts(str.to_str() + " ")
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

p("mux 1-3 in input 1")

sensor_list.each { | val |
	let port = new iev3_Port(val.port_name)
	if (port.type == "in" && port.is_mux) {
		let tmp_sensor = new iev3_Sensor(val.id);
		p(tmp_sensor.getValue())
	}
}

let motorB = null
let motorC = null

motor_list.each { | val |
	let port = new iev3_Port(val.port_name)
	if (port.type == "out" && port.id == "B") {
		motorB = new iev3_Motor(val.id);
		//let tmp_motor = new iev3_Motor(val.id);
		//tmp_motor.runRelat(100, 360)
		//p("start")
		//receive() for(8000)
		//p("end");
		//tmp_motor.stop()
	} else if (port.type == "out" && port.id == "C") {
		motorC = new iev3_Motor(val.id);
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

let wait_for_stop = fn (motor) {
	while (1) {
		if (!motor.getState().running) {
			p("stop!!")
			break
		}
	}
}

let require = fn (motor) {
	if (!motor) {
		p("Require motor")
		exit
	}
}

let led_rainbow = fn () {
	let backup = iev3_LED_getLEDState()

	for (let i = 255, i > 0, i -= 5) {
		iev3_LED_setBrightness("left", "red", i)
		receive() for(10)
	}
	for (let i = 0, i < 255, i += 5) {
		iev3_LED_setBrightness("left", "green", i)
		receive() for(10)
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

led_rainbow()
led_alert(10)

require(motorC)

motorC.runRelat(100, 1080)
wait_for_stop(motorC)

p("end!")

sm_acc(motorC)
receive() for(3000)
motorC.stop()

motorC.runForever(100)
receive() for(1000)
motorC.stop("hold")

motorC.runForever(100)
receive() for(1000)
motorC.stop()

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
