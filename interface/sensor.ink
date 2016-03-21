#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

let iev3_Sensor = fn (id) { /* id: numeric */
	this.id = id
	this.getValue = fn () { /* error: return -1 */
		if (!(let ret = new File(iev3_SensorPath + "/sensor" + base.id + "/value0").gets())) {
			-1
		} else {
			numval(ret.substr(0, ret.length() - 1)) /*  */
		}
	}
}

let iev3_Sensor.getList = fn () {
	let dir = new Directory(iev3_SensorPath)
	let ret = new Array()

	dir.each { | name |
		if (name != "." && name != ".." && name.substr(0, 6) == "sensor") {
			ret.push({
				id: numval(name.substr(6)),
				port_name: inl () {
					let tmp = new File(dir.path() + "/" + name + "/" + iev3_SensorPortName, "r").gets()
					tmp.substr(0, tmp.length() - 1)
				} ()
			})
		}
	}

	ret
}

let iev3_Sensor_procList = fn (list) {
	let ret = [null, null, null, null] // port 1-4
	let port = null

	list.each { | val |
		/* parse port name */
		port = new iev3_Port(val.port_name)

		if (port.id > 0 && port.id <= ret.size()) {
			if (port.is_mux) {
				if (typename(ret[port.id - 1]) == "array") {
					ret[port.id - 1][port.mux_id] = { port: port, sensor: new iev3_Sensor(val.id) }
				} else {
					ret[port.id - 1] = [null, null, null] // max 3 mux supported
				}
			} else {
				ret[port.id - 1] = { port: port, val: new iev3_Sensor(val.id) }
			}
		}
	}

	ret.`_[]` = ret.`[]`
	ret.`[]` = fn (i) {
		base.`_[]`(i - 1)
	}

	ret
}
