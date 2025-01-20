extends Control

@export var censoring_bar: Image

var drawing := false

@onready var text_label := $RichTextLabel
@onready var texture_rect := $TextureRect

@onready var censoring := Image.create_empty(text_label.size.x, text_label.size.y, 
											 false, Image.FORMAT_RGBA8)

func _ready():
	texture_rect.texture = ImageTexture.create_from_image(censoring)


func _approx_word_boundaries(word: String, idx: int) -> Rect2i:
	var line_no: int = text_label.get_character_line(idx)
	var line_break: int = text_label.text.rfind("\n", idx)
	var font_size: int = text_label.get_theme_font_size("normal_font")
	
	line_break = line_break + 1 if line_break > 0 else 1

	var word_begin_off: Vector2 = text_label.get_theme_font("normal_font").get_string_size(
			text_label.text.substr(line_break, idx - line_break),
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			text_label.justification_flags
		)
	word_begin_off = Vector2(word_begin_off.x + (idx - line_break), (word_begin_off.y + BreakAdd) * line_no)
	
	var word_end_off: Vector2 = text_label.get_theme_font("normal_font").get_string_size(
			text_label.text.substr(line_break, (idx + word.length()) - line_break),
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
			text_label.justification_flags
		)
	word_end_off = Vector2(word_end_off.x + (idx + word.length() - line_break), (word_end_off.y + BreakAdd) * line_no)
	
	return Rect2i(word_begin_off, Vector2i(word_end_off.x - word_begin_off.x, font_size)) # font_size = 18?

# Counts one rectangle if at least 70% are black
# Returns ratio of "completed" rectangles VS total rectangles
func _area_percentage(locations: Array[Rect2i]) -> float:
	if locations.is_empty():
		return 0.0

	var good := 0

	for rect in locations:
		var counter := 0

		for y in range(rect.position.y, rect.position.y + rect.size.y):
			for x in range(rect.position.x, rect.position.x + rect.size.x):
				if censoring.get_pixel(x, y) == Color.BLACK:
					counter += 1
		
		var p := rect.get_area() * 70 / 100
		if counter >= p:
			good += 1

	return good / float(locations.size())


# Nur experimentell gefunden, unsauber aber scheinbar hinreichend
const BreakAdd := 4.8

func evaluate(word_groups: Dictionary[StringName, PackedStringArray]): # -> Dictionary[StringName, Dictionary]:
	var eval_text: String = text_label.text.to_lower()
	var found: Dictionary[String, float] = {}
	var result: Dictionary[StringName, Dictionary] = {}
	
	for group: StringName in word_groups:
		result[group] = {}
		
		for word in word_groups[group]:
			
			# Don't recalculate, if we already processed this word
			if found.has(word):
				result[group][word] = found[word]
				break
			
			var idx := 0
			var locations: Array[Rect2i] = []
			
			# Find all occurances of word
			while true:
				idx = text_label.text.findn(word, idx + word.length())
				if idx == -1:
					break
				
				locations.append(_approx_word_boundaries(word, idx))
			
			found[word] = _area_percentage(locations)
			print("%s: %f" % [word, found[word]])
				# for debugging
				# censoring.fill_rect(Rect2i(word_begin_off, Vector2i(word_end_off.x - word_begin_off.x, 18)), Color.YELLOW)
	# For debugging
	# texture_rect.texture.update(censoring)

func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
		elif event.pressed:
			evaluate({first = ["Anteile", "Text", "Absätze"]})
	elif drawing and event is InputEventMouseMotion:
		var mouse_pos := get_local_mouse_position()
		mouse_pos = Vector2i(mouse_pos.x - 12, mouse_pos.y - 12)
		
		censoring.blit_rect(censoring_bar, Rect2i(0, 0, 24, 24), mouse_pos)
		texture_rect.texture.update(censoring)
			
