#+feature global-context
package main

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:slice"
import "core:strings"
import "core:time"

movie_types: []string = []string{".mov"}
pool_interval := time.Second * 5

ScreenRecording :: struct {
	input, output: string,
}

on_folder_change :: proc(folder: string) {
	fmt.println("*** folder change %q", folder)
}

main :: proc() {

	args := os.args

	if len(args) < 2 || len(args) > 3 {
		info()
		return
	}

	if args[1] == "-v" || args[1] == "--version" {
		printVersion()
		return
	}

	if args[1] == "-w" || args[1] == "--watch" {
		store_folder := default_capture_folder
		if len(args) == 3 {
			store, is_valid := check_is_valid_folder(args[2])
			if !is_valid {
				fmt.eprintf("[Error] - invalid path %q to watch\n", args[2])
				return
			}
			store_folder = store
		}
		watch(store_folder)
	}

	fmt.eprintln("[Error] - missing or wrong flags\n\n")

	info()
}


watch :: proc(dest: string) {
	config, err := get_config(dest)
	if err {
		fmt.eprintln("config problem, exiting\n")
		os2.exit(1)
	}

	when ODIN_OS == .Darwin {
		fmt.printf("darwin detected, start watching %q\n", dest)
		stream := start_watching(dest, on_folder_change)
		defer stop_watching(stream)
		fmt.println("config", config)

		// Run the event loop (bloks until intrerrupted)
		CFRunLoopRun()
	} else {

		for {
			time.sleep(pool_interval)
			new_entries := get_movies_from_folder(&config)

			for mov in new_entries {
				if ok := convert(mov, config); !ok {
					fmt.eprint("error compressing: ", mov)
				}
				time.sleep(time.Millisecond * 100)
			}
			defer delete(new_entries)
		}
	}
}


printSeparator :: proc() {
	fmt.printf("\n\n%s\n\n", strings.repeat("=", 50))
}

convert :: proc(mov: ScreenRecording, config: Config) -> bool {
	input := filepath.join({config.captureStore, mov.input}, context.temp_allocator)
	output := filepath.join({config.captureStore, mov.output}, context.temp_allocator)

	// check input is viable
	_, err := os.stat(input)
	if err != nil {
		fmt.eprintf("input file %s doesn't exist\n", input)
		return false
	}

	cmd: []string = {
		config.encoder,
		"-i",
		input,
		"-vcodec",
		"libx264",
		"-acodec",
		"aac",
		"-movflags",
		"+faststart",
		output,
	}

	fmt.println("\n1 found new file")
	process, proc_err := os2.process_start({command = cmd, working_dir = config.captureStore})
	if proc_err != nil {
		fmt.eprintf("error executing cmd: %s\n, with err: %q\n", cmd, proc_err)
		return false
	}

	fmt.println("2 wait for ffmpeg to complete")
	code, wait_err := os2.process_wait(process)
	if wait_err != nil {
		fmt.eprintf("FFmpeg failed for %s (exit code: %d)\n", input, code)
		return false
	}

	fmt.println("3 conversion completed")
	if err := os2.process_close(process); err != nil {
		fmt.eprintf("error closing process %v\n", err)
		return false
	}

	fmt.printf("4 check new file exists %s\n", output)
	// check output is ok
	info, stat_err := os.stat(output)
	if stat_err != nil || info.size <= 0 {
		fmt.eprintf("output file %s doesn't exist\n", output)
		return false
	}

	fmt.printf("5 delete input file %s\n", input)
	if delete_err := os.remove(input); delete_err != nil {
		fmt.eprintf("error deleting %s: %q\n", input, err)
		return false
	}
	fmt.println("6 done\n")
	return true
}

// Reads movies from folder path
get_movies_from_folder :: proc(conf: ^Config) -> []ScreenRecording {
	res: [dynamic]ScreenRecording
	fis: []os.File_Info

	stat, acces_err := os.stat(conf.captureStore)
	if acces_err != nil {
		fmt.eprintf("error accessing folder %q, with error %q\n", conf.captureStore, acces_err)
	}

	last_access, exists := access_exist(conf)
	if exists && last_access == stat.modification_time {
		return res[:]
	}

	target_dir, err := os.open(conf.captureStore)
	if err != nil {
		fmt.eprintf("error opening folder %s: %q\n", conf.captureStore, err)
		return res[:]
	}

	// free meme on exit
	defer os.close(target_dir)
	fis, err = os.read_dir(target_dir, 0, context.temp_allocator)
	if err != os.ERROR_NONE {
		fmt.eprintf("Error reading directory %s: %q\n", conf.captureStore, err)
		os.exit(2)
	}

	for fi in fis {
		if !fi.is_dir {
			ext := filepath.ext(fi.name)
			if slice.contains(movie_types, ext) {
				if err != nil {
					fmt.eprintf("error creating target from file base: %q\n", err)
				}
				target, _ := strings.replace(fi.name, ext, ".mp4", -1)
				append(&res, ScreenRecording{input = strings.clone(fi.name), output = target})
			}
		}
	}

	if len(res) == 0 {
		// no file to process? keep the modification_time
		add_access(conf, stat.modification_time)
	}
	return res[:]
}
