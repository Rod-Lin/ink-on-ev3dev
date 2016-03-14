#! /usr/bin/ink

let iev3_SensorPath = "/sys/class/lego-sensor"
let iev3_SensorPortName = "address"

let iev3_TMotorPath = "/sys/class/tacho-motor"
let iev3_TMotorPortName = "address"

let iev3_TMotorCommand_RunForever = "run-forever"
let iev3_TMotorCommand_RunToAbsPos = "run-to-abs-pos"
let iev3_TMotorCommand_RunToRelPos = "run-to-rel-pos" /* relative position */
let iev3_TMotorCommand_RunTimed = "run-timed"
let iev3_TMotorCommand_RunDirect = "run-direct"
let iev3_TMotorCommand_Stop = "stop"
let iev3_TMotorCommand_Reset = "reset"

let iev3_LEDPath = "/sys/class/leds"
