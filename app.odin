package main

import "core:fmt"
import "core:strings"
import "core:thread"
import "utils"
import sdl "vendor:sdl3"
import sdlimg "vendor:sdl3/image"

THUMBNAIL_HEIGHT: f32 = 100
THUMBNAIL_PADDING: f32 = 10

App :: struct {
	window:                 ^sdl.Window,
	renderer:               ^sdl.Renderer,
	loaded_surfaces:        [dynamic]^sdl.Surface,
	loaded_textures:        [dynamic]Texture_Desc,
	imgs:                   []string,
	texture_load_ahead_amt: u32,
	active_texture_index:   u32,
	last_loaded_index:      u32,
}

create_app :: proc(app: ^App, args: []string) -> bool {
	if len(args) == 0 {
		fmt.println("no path provided. please provide a path to an image")
		return false
	}

	app.texture_load_ahead_amt = 10

	imgs := utils.get_image_paths(args[1])

	init_success := sdl.Init(sdl.INIT_VIDEO)
	if !init_success {
		fmt.printfln("failed to initialize sdl")
		return false
	}

	creation_success := sdl.CreateWindowAndRenderer(
		"window",
		1280,
		720,
		sdl.WINDOW_RESIZABLE,
		&app.window,
		&app.renderer,
	)

	if !creation_success {
		fmt.printfln("failed to create window and renderer: %s", sdl.GetError())
		sdl.Quit()
		return false
	}

	texture := sdlimg.LoadTexture(app.renderer, strings.clone_to_cstring(imgs[0]))
	if texture == nil {
		fmt.println("failed to load image")
		sdl.DestroyRenderer(app.renderer)
		sdl.DestroyWindow(app.window)
		sdl.Quit()
		return false
	}

	textures: [dynamic]Texture_Desc
	for i := 0; i < 1; i += 1 {
		texture := sdlimg.LoadTexture(app.renderer, strings.clone_to_cstring(imgs[i]))
		if texture != nil {
			append(&textures, create_texture_desc(texture))
		}
	}

	app.loaded_textures = textures
	app.imgs = imgs
	app.active_texture_index = 0
	app.last_loaded_index = app.active_texture_index

	t := thread.create(load_next_textures_async)
	t.data = app
	thread.start(t)

	return true
}

load_next_textures_async :: proc(t: ^thread.Thread) {
	data := (^App)(t.data)
	load_next_textures(data)
}

load_next_textures :: proc(app: ^App) {
	for i := 0; i < len(app.imgs); i += 1 {
		surf := sdlimg.Load(strings.clone_to_cstring(app.imgs[i]))
		if surf != nil {
			append(&app.loaded_surfaces, surf)
		}
		app.last_loaded_index += 1
	}
}

// load_next_textures :: proc(app: ^App) {
// 	if app.last_loaded_index < u32(len(app.imgs) - 1) &&
// 	   app.last_loaded_index <= app.active_texture_index + app.texture_load_ahead_amt {
// 		fmt.printfln("loading texture: %s", app.imgs[app.last_loaded_index + 1])
// 		texture := sdlimg.LoadTexture(
// 			app.renderer,
// 			strings.clone_to_cstring(app.imgs[app.last_loaded_index + 1]),
// 		)
// 		if texture != nil {
// 			append(&app.loaded_textures, create_texture_desc(texture))
// 		}
// 		app.last_loaded_index += 1
// 	}
// }

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
	event: sdl.Event
	for sdl.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			return false
		case .KEY_DOWN:
			#partial switch event.key.scancode {
			case .Q:
				return false
			case .H:
				prev_texture(app)
			case .L:
				next_texture(app)
			case .B:
				app.active_texture_index = 0
			case .E:
				app.active_texture_index = app.last_loaded_index - 1
			}
		}
	}

	for i := len(app.loaded_textures); i < len(app.loaded_surfaces); i += 1 {
		texture := sdl.CreateTextureFromSurface(app.renderer, app.loaded_surfaces[i])
		append(&app.loaded_textures, create_texture_desc(texture))
		// free unnecessary data but keep the junk ptr (bad practice ik)
		sdl.DestroySurface(app.loaded_surfaces[i])
	}

	return true
}

app_render :: proc(app: ^App) {
	render_active_texture(app)
	render_thumbnails(app)
}

render_thumbnails :: proc(app: ^App) {
	scrw, scrh: i32
	sdl.GetWindowSize(app.window, &scrw, &scrh)

	y: f32 = f32(scrh) - THUMBNAIL_HEIGHT - THUMBNAIL_PADDING
	x: f32 = THUMBNAIL_PADDING
	texture_index := app.active_texture_index


	for x < f32(scrh) && texture_index < u32(len(app.loaded_textures)) {
		texture := &app.loaded_textures[texture_index]

		srect := sdl.FRect {
			x = 0,
			y = 0,
			w = texture.width,
			h = texture.height,
		}

		drect := sdl.FRect {
			x = x,
			y = y,
			w = texture.width * (f32(THUMBNAIL_HEIGHT) / texture.height),
			h = THUMBNAIL_HEIGHT,
		}

		sdl.RenderTexture(app.renderer, texture.handle, &srect, &drect)

		if texture_index == app.active_texture_index {
			render_box(app, drect)
		}

		x += drect.w + THUMBNAIL_PADDING
		texture_index += 1
	}


}

render_box :: proc(app: ^App, rect: sdl.FRect) {
	THICKNESS: f32 = 2.0
	r, g, b, a: u8
	sdl.GetRenderDrawColor(app.renderer, &r, &g, &b, &a)
	sdl.SetRenderDrawColor(app.renderer, 255, 255, 255, 255)

	sdl.RenderRect(app.renderer, &sdl.FRect{x = rect.x, y = rect.y, w = rect.w, h = THICKNESS})
	sdl.RenderRect(
		app.renderer,
		&sdl.FRect{x = rect.x, y = rect.y + rect.h - THICKNESS, w = rect.w, h = THICKNESS},
	)
	sdl.RenderRect(app.renderer, &sdl.FRect{x = rect.x, y = rect.y, w = THICKNESS, h = rect.h})
	sdl.RenderRect(
		app.renderer,
		&sdl.FRect{x = rect.x + rect.w - THICKNESS, y = rect.y, w = THICKNESS, h = rect.h},
	)

	sdl.SetRenderDrawColor(app.renderer, r, g, b, a)
}

render_active_texture :: proc(app: ^App) {
	active_texture := app.loaded_textures[app.active_texture_index]

	w, h: i32
	sdl.GetWindowSize(app.window, &w, &h)
	scale := min(f32(w) / active_texture.width, f32(h) / active_texture.height)
	dest_w := active_texture.width * scale
	dest_h := active_texture.height * scale

	srect := sdl.FRect {
		x = 0,
		y = 0,
		w = active_texture.width,
		h = active_texture.height,
	}

	drect := sdl.FRect {
		x = (f32(w) - dest_w) / 2.0,
		y = (f32(h) - dest_h) / 2.0,
		w = dest_w,
		h = dest_h,
	}

	sdl.RenderTexture(app.renderer, active_texture.handle, &srect, &drect)
}


app_shutdown :: proc(app: ^App) {
	delete(app.loaded_textures)
	delete(app.imgs)

	sdl.DestroyRenderer(app.renderer)
	sdl.DestroyWindow(app.window)
	sdl.Quit()

	for &desc in app.loaded_textures {
		free_texture_desc(&desc)
	}
	for &surf in app.loaded_surfaces {
		sdl.DestroySurface(surf)
	}
}
