#! /usr/bin/ink

import blueprint
import io
import multink
import "interface/sensor.ink"
import "interface/motor.ink"
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

//motorB.runTimed(100, 3000)
//motorC.runTimed(100, 3000)


motorC.runRelat(100, 360)
motorB.runRelat(100, 360)

receive() for(1000)

motorC.runRelat(100, 360)
motorB.runRelat(100, 360)

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
