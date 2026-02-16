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

ScreenCapture :: struct {
	name, target: string,
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

	for {
		time.sleep(pool_interval)
		new_entries := get_movies_from_folder(config.captureStore)

		for mov in new_entries {
			if ok := convert(mov, config); !ok {
				fmt.eprint("error compressing: ", mov)
			}
			time.sleep(time.Millisecond * 100)
		}
		defer delete(new_entries)
	}
}


printSeparator :: proc() {
	fmt.printf("\n\n%s\n\n", strings.repeat("=", 50))
}

convert :: proc(mov: ScreenCapture, config: Config) -> bool {
	input := filepath.join({config.captureStore, mov.name}, context.temp_allocator)
	output := filepath.join({config.captureStore, mov.target}, context.temp_allocator)

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
get_movies_from_folder :: proc(from: string) -> []ScreenCapture {
	res: [dynamic]ScreenCapture
	fis: []os.File_Info

	file, err := os.open(from)
	if err != nil {
		fmt.eprintf("error opening folder %s: %q\n", from, err)
		return res[:]
	}

	// free meme on exit
	defer os.close(file)
	fis, err = os.read_dir(file, 0, context.temp_allocator)
	if err != os.ERROR_NONE {
		fmt.eprintf("Error reading directory %s: %q\n", from, err)
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
				append(&res, ScreenCapture{name = strings.clone(fi.name), target = target})
			}
		}
	}
	return res[:]
}
