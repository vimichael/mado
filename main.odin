package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import sdl "vendor:sdl3"
import sdlimg "vendor:sdl3/image"

main :: proc() {
	app: App
	if !create_app(&app, os.args) {
		fmt.printfln("failed to create app")
		return
	}
	defer app_shutdown(&app)

	sdl.SetRenderDrawColor(app.renderer, 20, 20, 20, 255)

	running := true
	for running {
		running = app_update(&app)

		sdl.RenderClear(app.renderer)

		app_render(&app)

		sdl.RenderPresent(app.renderer)
	}
}
