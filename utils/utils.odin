package utils

import "core:fmt"
import "core:os"
import "core:path/filepath"

array_contains :: proc(target: $T, arr: []T) -> bool {
	for &item in arr {
		if item == target {
			return true
		}
	}
	return false
}

get_image_paths :: proc(root_dir: string) -> []string {
	handle, err := os.open(root_dir)
	if err != nil {
		fmt.println(err)
		return {}
	}
	defer os.close(handle)

	files, dir_err := os.read_dir(handle, 100, context.allocator)
	if dir_err != nil {
		fmt.println(dir_err)
		return {}
	}

	formats: []string = {".png", ".jpg"}
	imgs: [dynamic]string

	for file in files {
		if array_contains(filepath.ext(file.fullpath), formats) {
			append(&imgs, file.fullpath)
		}
	}

	return imgs[:]
}
