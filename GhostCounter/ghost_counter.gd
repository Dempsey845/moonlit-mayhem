class_name GhostCounter
extends Node

signal ghost_added

var _ghost_count: int = 0
var ghost_count: int:
    get():
        return _ghost_count
    set(value):
        _ghost_count = value

func add_ghost():
    ghost_count += 1
    ghost_added.emit()
