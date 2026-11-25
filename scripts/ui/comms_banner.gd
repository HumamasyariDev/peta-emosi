class_name CommsBanner
extends CanvasLayer

## Thin adapter delegating Pos guidance banners to the global synced SubtitleBar
## inside AudioManager so every Pos (1-8) shares ONE crisp non-overlapping subtitle bar!

func show_guidance(step_tag: String, subtitle: String, expr: String = "happy", duration: float = 6.5) -> void:
	Audio.show_subtitle(step_tag, subtitle, expr, duration, false)


func hide_guidance() -> void:
	Audio.stop_voice()
