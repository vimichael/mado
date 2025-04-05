package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

main :: proc() {
	app: App
	if !create_app(&app, os.args) {
		fmt.printfln("failed to create app")
		return
	}
	defer app_shutdown(&app)

	running := true
	for running && !rl.WindowShouldClose() {
		running = app_update(&app)
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.Color{20, 20, 20, 255})

		app_render(&app)
	}
}
