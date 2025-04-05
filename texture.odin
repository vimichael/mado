package main

import sdl "vendor:sdl3"

Texture_Desc :: struct {
	handle:       ^sdl.Texture,
	width:        f32,
	height:       f32,
	aspect_ratio: f32,
}


create_texture_desc :: proc(texture: ^sdl.Texture) -> Texture_Desc {
	w, h: f32
	sdl.GetTextureSize(texture, &w, &h)
	return Texture_Desc{handle = texture, width = w, height = h, aspect_ratio = w / h}
}

free_texture_desc :: proc(self: ^Texture_Desc) {
	sdl.DestroyTexture(self.handle)
	self.width = 0
	self.height = 0
	self.aspect_ratio = 0.0
}
