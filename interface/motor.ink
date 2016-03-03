#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

iev3_Motor = fn (id) {
	this.id = id
	this.setCommand = fn (cmd) {
		new File(iev3_Motor.getPathOf(base.id, "command"), "w").puts(cmd.to_str())
	}
	this.setPosition = fn (pos) {
		new File(iev3_Motor.getPathOf(base.id, "position"), "w").puts(pos.to_str())
	}
	this.setPositionSP = fn (pos) {
		new File(iev3_Motor.getPathOf(base.id, "position_sp"), "w").puts(pos.to_str())
	}
	this.setTimeSP = fn (time) {
		new File(iev3_Motor.getPathOf(base.id, "time_sp"), "w").puts(time.to_str())
	}
	this.getPosition = fn () {
		let tmp = new File(iev3_Motor.getPathOf(base.id, "position"), "r").gets()
		numval(tmp.substr(0, tmp.length() - 1))
	}
	this.getSpeed = fn () {
		let tmp = new File(iev3_Motor.getPathOf(base.id, "speed"), "r").gets()
		numval(tmp.substr(0, tmp.length() - 1))
	}
	this.getTPC = fn () { /* tachometer pulse counts per one rotation */
		let tmp = new File(iev3_Motor.getPathOf(base.id, "count_per_rot"), "r").gets()
		numval(tmp.substr(0, tmp.length() - 1))
	}
	/* NOTICE: getSpeed and setDutyCircleSpeed are not the same */
	this.setDutyCircleSpeed = fn (speed) { /* -100 < speed < 100 */
		new File(iev3_Motor.getPathOf(base.id, "duty_cycle_sp"), "w").puts(speed.to_str())
	}
	this.setSpeedSP = fn (speed) { /* -100 < speed < 100 */
		new File(iev3_Motor.getPathOf(base.id, "speed_sp"), "w").puts(speed.to_str())
	}
	this.runForever = fn (speed) {
		base.setDutyCircleSpeed(speed)
		base.setCommand("run-forever")
	}
	this.runTimed = fn (speed, time) {
		base.setSpeedSP(speed)
		base.setTimeSP(time)
		base.setCommand("run-timed")
	}
	this.runRelat = fn (speed, deg) {
		base.setSpeedSP(speed)
		base.setPositionSP(deg)
		base.setCommand("run-to-rel-pos")
	}
	this.stop = fn () {
		base.setCommand("stop")
	}
	this.reset = fn () {
		base.setCommand("reset")
	}
}

iev3_Motor.getPathOf = fn (id, file) {
	iev3_TMotorPath + "/motor" + id + "/" + file
}

iev3_Motor.getList = fn () {
	let dir = new Directory(iev3_TMotorPath)
	let ret = new Array()

	dir.each { | name |
		if (name != "." && name != ".." && name.substr(0, 5) == "motor") {
			ret.push({
				id: numval(name.substr(5)),
				port_name: inl () {
					let tmp = new File(dir.path() + "/" + name + "/" + iev3_TMotorPortName, "r").gets()
					tmp.substr(0, tmp.length() - 1)
				} ()
			})
		}
	}

	ret
}
