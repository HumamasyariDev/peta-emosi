extends Node


func _ready() -> void:
	call_deferred("_go_title")


func _go_title() -> void:
	Router.go_to("res://scenes/ui/TitleScreen.tscn")

