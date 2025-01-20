extends Control

@export var censoring_bar: Image

var drawing := false

@onready var text_label := $RichTextLabel
@onready var texture_rect := $TextureRect

@onready var censoring := Image.create_empty(text_label.size.x, text_label.size.y, 
											 false, Image.FORMAT_RGBA8)

func _ready():
	texture_rect.texture = ImageTexture.create_from_image(censoring)


func evaluate(word_groups: Dictionary[StringName, PackedStringArray]):
	var eval_text: String = text_label.text.to_lower()
	
	for group: StringName in word_groups:
		for word in word_groups[group]:
			var idx := 0
			var word_length := word.length()
			
			while true:
				idx = text_label.text.findn(word, idx + word_length)
				if idx == -1:
					break
					
				var line_no: int = text_label.get_character_line(idx)
				var line_break: int = text_label.text.rfind("\n", idx)
				
				line_break = line_break + 1 if line_break > 0 else 0
				
				for i in word.length():
					var char_pos := idx + i
					var h_off: Vector2 = text_label.get_theme_font("normal_font").get_string_size(
						text_label.text.substr(line_break, char_pos - line_break),
						HORIZONTAL_ALIGNMENT_LEFT, -1, text_label.get_theme_font_size("normal_font"),
						text_label.justification_flags
					)
				
					h_off = Vector2(h_off.x + (char_pos - line_break), (h_off.y + 4.8) * line_no)
					censoring.fill_rect(Rect2i(h_off, Vector2i(12, 18)), Color.YELLOW)
	texture_rect.texture.update(censoring)

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
		elif event.pressed:
			print("eval")
			evaluate({first = ["Anteile", "Text", "Absätze"]})
	elif drawing and event is InputEventMouseMotion:
		var mouse_pos := get_local_mouse_position()
		mouse_pos = Vector2i(mouse_pos.x - 12, mouse_pos.y - 12)
		
		censoring.blit_rect(censoring_bar, Rect2i(0, 0, 24, 24), mouse_pos)
		texture_rect.texture.update(censoring)
			
