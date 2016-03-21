#! /usr/bin/ink

import blueprint
import io
import "constants.ink"

let iev3_MotorState = fn (state_str) {
	let state_list = state_str.split(" ")

	this.running = 0
	this.ramping = 0
	this.holding = 0
	this.stalled = 0

	state_list.each { | v |
		if (this[v] != undefined) {
			this[v] = 1
		}
	}

	this.missing = fn (name) {
		let tmp = ""
		if (name[-1] == "?" &&
			base[tmp = name.substr(0, name.length() - 1)] != undefined) {
			base[tmp]
		} else {
			0
		}
	}
}

let iev3_Motor = fn (id) {
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
	this.setStopCommand = fn (cmd) {
		new File(iev3_Motor.getPathOf(base.id, "stop_command"), "w").puts(cmd.to_str())
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
	this.getState = fn () {
		let tmp = new File(iev3_Motor.getPathOf(base.id, "state"), "r").gets()
		new iev3_MotorState(tmp.substr(0, tmp.length() - 1))
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
	this.runTimed = fn (speed, time, stop_cmd) {
		stop_cmd = stop_cmd || "coast"
		base.setDutyCircleSpeed(speed)
		base.setTimeSP(time)
		base.setStopCommand(stop_cmd)
		base.setCommand("run-timed")
	}
	this.runRelat = fn (speed, deg, stop_cmd) {
		stop_cmd = stop_cmd || "coast"
		base.setDutyCircleSpeed(speed)
		base.setPositionSP(deg)
		base.setStopCommand(stop_cmd)
		base.setCommand("run-to-rel-pos")
	}
	this.setRelat = fn (speed, deg, stop_cmd) {
		stop_cmd = stop_cmd || "coast"
		base.setDutyCircleSpeed(speed)
		base.setPositionSP(deg)
		base.setStopCommand(stop_cmd)
	}
	this.goRelat = fn () {
		base.setCommand("run-to-rel-pos")
	}
	this.runDirect = fn (speed) {
		base.setDutyCircleSpeed(speed)
		base.setCommand("run-direct")
	}
	this.stop = fn (stop_cmd) {
		stop_cmd = stop_cmd || "coast"
		base.setStopCommand(stop_cmd)
		base.setCommand("stop")
	}
	this.reset = fn () {
		base.setCommand("reset")
	}
}

let runDoubleRelat = fn (m1, m2, m1sp, m1pos, m2sp, m2pos) {
	m2sp ||= m1sp
	m2pos ||= m1pos

	require (m1, m2) {
		m1.setRelat(m1sp, m1pos)
		m2.setRelat(m2sp, m2pos)

		m1.goRelat()
		m2.goRelat()
	}
}

let iev3_Motor.getPathOf = fn (id, file) {
	iev3_TMotorPath + "/motor" + id + "/" + file
}

let iev3_Motor.getList = fn () {
	let dir = new Directory(iev3_TMotorPath)
	let ret = new Array()

	dir.each { | name |
		if (name.length() > 5 && name.substr(0, 5) == "motor") {
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

let iev3_Motor_motorIDMap = { A: 0, B: 1, C: 2, D: 3 }

let iev3_Motor_procList = fn (list) {
	let ret = { A: null, B: null, C: null, D: null} // port A-D
	let port = null

	list.each { | val |
		/* parse port name */
		port = new iev3_Port(val.port_name)
		ret[port.id] = { port: port, val: new iev3_Motor(val.id) }
	}

	ret
}
