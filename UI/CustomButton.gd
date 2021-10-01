extends Control

signal pressed;

var pressed : bool = false

func _init():
	connect("mouse_entered", self, "_on_mouse_entered");
	connect("mouse_exited", self, "_on_mouse_exited");

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed(): _on_pressed();
		
func _on_pressed():
	$Centering/ButtonRoot/ButtonNormal.visible = false;
	$Centering/ButtonRoot/ButtonHover.visible = false;
	$Centering/ButtonRoot/ButtonPressed.visible = true;
	$AnimationPlayer.play("Pressed");
	emit_signal("pressed");

func _on_mouse_entered():
	if pressed: return;
	$Centering/ButtonRoot/ButtonNormal.visible = false;
	$Centering/ButtonRoot/ButtonHover.visible = true;

func _on_mouse_exited():
	if pressed: return;
	$Centering/ButtonRoot/ButtonHover.visible = false;
	$Centering/ButtonRoot/ButtonNormal.visible = true;
