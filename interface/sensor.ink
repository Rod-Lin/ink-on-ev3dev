#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

iev3_Sensor = fn (id) { /* id: numeric */
	this.id = id
	this.getValue = fn () { /* error: return -1 */
		if (!(let ret = new File(iev3_SensorPath + "/sensor" + base.id + "/value0").gets())) {
			-1
		} else {
			numval(ret.substr(0, ret.length() - 1)) /*  */
		}
	}
}

iev3_Sensor.getList = fn () {
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
