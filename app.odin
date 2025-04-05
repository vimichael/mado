package main

import "core:c"
import "core:fmt"
import "core:strings"
import "core:thread"
import "utils"
import rl "vendor:raylib"

THUMBNAIL_HEIGHT: f32 = 100
THUMBNAIL_PADDING: f32 = 10

App :: struct {
	loaded_textures:        [dynamic]rl.Texture,
	imgs:                   []string,
	texture_load_ahead_amt: u32,
	active_texture_index:   u32,
	last_loaded_index:      u32,
	font:                   rl.Font,
	zen_mode:               bool,
}

create_app :: proc(app: ^App, args: []string) -> bool {
	if len(args) == 0 {
		fmt.println("no path provided. please provide a path to an image")
		return false
	}

	app.texture_load_ahead_amt = 10

	imgs := utils.get_image_paths(args[1])

	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(1280, 720, strings.clone_to_cstring("window"))
	rl.SetExitKey(rl.KeyboardKey.Q)

	textures: [dynamic]rl.Texture
	for i := 0; i < 1; i += 1 {
		texture := rl.LoadTexture(strings.clone_to_cstring(imgs[i]))
		append(&textures, texture)
	}

	app.loaded_textures = textures
	app.imgs = imgs
	app.active_texture_index = 0
	app.last_loaded_index = app.active_texture_index

	font := rl.LoadFont("IosevkaTerm-Regular.ttf")
	app.font = font

	app.zen_mode = true

	return true
}

load_next_textures :: proc(app: ^App) {
	if int(app.last_loaded_index) < len(app.imgs) - 1 {
		append(
			&app.loaded_textures,
			rl.LoadTexture(strings.clone_to_cstring(app.imgs[app.last_loaded_index + 1])),
		)
		app.last_loaded_index += 1
	}
}

next_texture :: proc(app: ^App) {
	if app.active_texture_index == u32(len(app.imgs) - 1) {
		return
	}
	app.active_texture_index += 1
	app.active_texture_index = min(app.active_texture_index, app.last_loaded_index)
}

prev_texture :: proc(app: ^App) {
	if app.active_texture_index == 0 {
		return
	}
	app.active_texture_index -= 1
}

app_update :: proc(app: ^App) -> bool {
	#partial switch rl.GetKeyPressed() {
	case .H:
		prev_texture(app)
	case .L:
		next_texture(app)
	case .B:
		app.active_texture_index = 0
	case .E:
		app.active_texture_index = app.last_loaded_index
	case .Z:
		app.zen_mode = !app.zen_mode
	}

	load_next_textures(app)

	return true
}

app_render :: proc(app: ^App) {
	render_active_texture(app)
	if !app.zen_mode {
		render_thumbnails(app)
		render_img_text(app)
	}
}

render_img_text :: proc(app: ^App) {
	rl.DrawTextEx(
		app.font,
		strings.clone_to_cstring(app.imgs[app.active_texture_index]),
		{THUMBNAIL_PADDING, THUMBNAIL_PADDING},
		32.0,
		1.0,
		rl.RAYWHITE,
	)
}

render_thumbnails :: proc(app: ^App) {
	scrw := rl.GetScreenWidth()
	scrh := rl.GetScreenHeight()

	rl.DrawRectangle(
		0.0,
		scrh - i32(THUMBNAIL_HEIGHT + (THUMBNAIL_PADDING * 2)),
		scrw,
		i32(THUMBNAIL_HEIGHT + (THUMBNAIL_PADDING * 2)),
		rl.Color{20, 20, 20, 255},
	)

	y: f32 = f32(scrh) - THUMBNAIL_HEIGHT - THUMBNAIL_PADDING
	x: f32 = THUMBNAIL_PADDING
	texture_index := app.active_texture_index


	for x < f32(scrh) && texture_index < u32(len(app.loaded_textures)) {
		texture := app.loaded_textures[texture_index]

		srect := rl.Rectangle {
			x      = 0,
			y      = 0,
			width  = f32(texture.width),
			height = f32(texture.height),
		}

		drect := rl.Rectangle {
			x      = x,
			y      = y,
			width  = f32(texture.width) * (f32(THUMBNAIL_HEIGHT) / f32(texture.height)),
			height = THUMBNAIL_HEIGHT,
		}

		rl.DrawTexturePro(texture, srect, drect, {0, 0}, 0.0, rl.RAYWHITE)

		if texture_index == app.active_texture_index {
			rl.DrawRectangleLinesEx(drect, 2.0, rl.RAYWHITE)
		}

		x += f32(drect.width) + THUMBNAIL_PADDING
		texture_index += 1
	}
}

render_active_texture :: proc(app: ^App) {
	active_texture := app.loaded_textures[app.active_texture_index]

	w := rl.GetScreenWidth()
	h := rl.GetScreenHeight()
	scale := min(f32(w) / f32(active_texture.width), f32(h) / f32(active_texture.height))
	dest_w := f32(active_texture.width) * scale
	dest_h := f32(active_texture.height) * scale

	srect := rl.Rectangle {
		x      = 0,
		y      = 0,
		width  = f32(active_texture.width),
		height = f32(active_texture.height),
	}

	drect := rl.Rectangle {
		x      = f32((f32(w) - dest_w) / 2.0),
		y      = f32((f32(h) - dest_h) / 2.0),
		width  = f32(dest_w),
		height = f32(dest_h),
	}

	rl.DrawTexturePro(active_texture, srect, drect, {0, 0}, 0.0, rl.RAYWHITE)
}


app_shutdown :: proc(app: ^App) {
	for texture in app.loaded_textures {
		rl.UnloadTexture(texture)
	}
	rl.UnloadFont(app.font)

	delete(app.loaded_textures)
	delete(app.imgs)

	rl.CloseWindow()
}
