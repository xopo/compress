package main

import "core:os"
import "core:path/filepath"

get_target_folder :: proc() -> string {
	home := os.get_env("HOME")
	return filepath.join([]string{home, default_capture_folder})

}
