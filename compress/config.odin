package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:strings"

default_capture_folder: string = "Desktop/Screenshots"
default_encoder: string = "/opt/homebrew/bin/ffmpeg"

Config :: struct {
	captureStore: string `json:"store"`,
	encoder:      string `json:"encoder"`,
}

// check for ~/.compress.json  or use default config
get_config :: proc(dir: string) -> (conf: Config, valid: bool) {
	conf_file := filepath.join({get_home_folder(), ".config/compress/compress.json"})

	// set default config
	if !is_valid_file(conf_file) {
		conf.captureStore = dir
		conf.encoder = default_encoder

		valid = verify_config(&conf)
		return conf, !valid
	}

	data, err := os2.read_entire_file_from_path(conf_file, context.temp_allocator)
	if err != nil {
		fmt.eprintf("error read config from build folder, %w\n", err)
		return conf, false
	}
	json.unmarshal(data, &conf)
	fmt.eprintf(
		"found config file:\n\tstore:\t%s\n\tffmpeg:\t%s\n\n",
		conf.captureStore,
		conf.encoder,
	)

	isValid := verify_config(&conf)
	return conf, !isValid
}

get_home_folder :: proc() -> string {
	if ODIN_OS == .Windows {
		return os.get_env("USERPROFILE")
	}
	return os.get_env("HOME")
}

verify_config :: proc(cfg: ^Config) -> bool {
	movie_store := cfg.captureStore
	if len(movie_store) == 0 {
		movie_store = default_capture_folder
	}

	dir, is_valid := check_is_valid_folder(movie_store)
	if (!is_valid) {
		fmt.eprintf("invalid folder %s\n", movie_store)
		return false
	}
	movie_store = dir

	cfg.captureStore = movie_store

	encoder := cfg.encoder
	if len(encoder) == 0 {
		encoder = default_encoder
	}
	if is_valid_file(encoder) {
		if encoder != cfg.encoder {
			cfg.encoder = encoder
		}
		return true
	}

	fmt.eprintf("encoder missing or wrong path %q\n\n", encoder)

	return false
}

// try as absolute or relative to home directory
check_is_valid_folder :: proc(dir: string) -> (string, bool) {
	loc_dir := strings.trim_space(dir)

	if loc_dir[0] == '~' {
		loc_dir = loc_dir[1:]
	}
	if is_valid_folder(loc_dir) {
		return dir, true
	}

	checkDir, err := filepath.join({get_home_folder(), loc_dir})
	if is_valid_folder(checkDir) || err != nil {
		return checkDir, true
	}
	fmt.eprintf("folder %q not found\n", checkDir)
	return "", false
}

is_valid_folder :: proc(dir: string) -> bool {
	return is_valid(dir, .Directory)
}


is_valid_file :: proc(bin: string) -> bool {
	return is_valid(bin, .Regular)
}

is_valid :: proc(dir: string, ft: os2.File_Type) -> bool {
	stat, file_error := os2.stat(dir, context.temp_allocator)
	if file_error == .Not_Exist {
		return false
	}
	if file_error != nil {
		fmt.eprintf("%s does not exist, %w", dir, file_error)
		return false
	}
	return stat.type == ft
}
