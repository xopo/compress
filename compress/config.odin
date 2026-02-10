package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:path/filepath"

default_capture_folder: string = "Desktop/screenshots"
default_encoder: string = "/opt/homebrew/bin/ffmpeg"

Config :: struct {
	captureStore: string `json:"store"`,
	encoder:      string `json:"encoder"`,
}

// check for ~/.compress.json  or use default config
get_config :: proc() -> (Config, bool) {
	conf: Config
	conf_file := filepath.join({get_home_folder(), ".compress.json"})
	if !is_valid_file(conf_file) {
		fmt.eprintf(
			"no config found in ~/ continue with default\n\nstore:\t%s\nffmpeg:\t%s\n",
			default_capture_folder,
			default_encoder,
		)
		valid := verify_config(&conf)
		return conf, !valid
	}
	data, err := os2.read_entire_file_from_path(conf_file, context.temp_allocator)
	if err != nil {
		fmt.eprintf("error read config from build folder, %w\n", err)
		return conf, false
	}
	json.unmarshal(data, &conf)
	fmt.eprintf(
		"found config file\n\nstore:\t%s\nffmpeg:\t%s\n\n",
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
	if !is_valid_folder(movie_store) && movie_store[0] != '/' {
		home_movie_store := filepath.join({get_home_folder(), movie_store})
		if (!is_valid_folder(home_movie_store)) {
			fmt.eprintf("invalid folder %s\n", movie_store)
			return false
		}
		movie_store = home_movie_store
	}
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

	return false
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
