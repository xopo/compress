#+feature global-context
package main

import "core:fmt"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:slice"
import "core:strings"
import "core:time"

default_capture_folder: string = "Desktop/screenshots"
movie_types: []string = []string{".mov"}
pool_interval := time.Second * 5

ScreenCapture :: struct {
	name, target: string,
}

main :: proc() {

	record_folder := get_target_folder()
	defer delete(record_folder)

	for {
		time.sleep(pool_interval)
		new_entries := get_movies_from_folder(record_folder)

		for mov in new_entries {
			compress(mov, record_folder)
			time.sleep(time.Millisecond * 100)
		}
		defer delete(new_entries)
	}
}

@(init)
startup :: proc() {
	printSeparator()
}

@(fini)
shutdown :: proc() {
	printSeparator()
}

printSeparator :: proc() {
	fmt.printf("\n\n%s\n\n", strings.repeat("=", 50))
}

compress :: proc(mov: ScreenCapture, folder: string, allocator := context.allocator) {
	input := filepath.join({folder, mov.name})
	output := filepath.join({folder, mov.target})
	defer delete(input, allocator)
	defer delete(output, allocator)

	// check input is viable
	_, err := os.stat(input)
	if err != nil {
		return
	}

	cmd: []string = {"ffmpeg -i", input, "-vcodec libx264 -crf 23 -preset medium", output}

	fmt.println("1 - start compression")
	process, proc_err := os2.process_start({command = cmd, working_dir = folder})
	if proc_err != nil {
		fmt.eprintf("error executing cmd: %s\n, with err: %q", cmd, proc_err)
	}

	fmt.println("2 - wait to finish compression")
	code, wait_err := os2.process_wait(process)
	if wait_err != nil {
		fmt.eprintf("FFmpeg failed for %s (exit code: %d)\n", input, code)
		return
	}
	fmt.println("3 - close process ")
	if err := os2.process_close(process); err != nil {
		fmt.eprintf("error closing process %v\n", err)
		return
	}


	fmt.printf("4 - check file exists %s \n ", output)
	// check output is ok
	info, stat_err := os.stat(output)
	if stat_err != nil || info.size <= 0 {
		return
	}


	fmt.printf("5 - delete input %s\n", input)
	if delete_err := os.remove(input); delete_err != nil {
		fmt.eprintf("error deleting %s: %q\n", input, err)
		return
	}
	fmt.println("6 done")
}

// Reads movies from folder path
get_movies_from_folder :: proc(from: string, allocator := context.allocator) -> []ScreenCapture {
	res: [dynamic]ScreenCapture
	fis: []os.File_Info
	// delete all the info when done
	defer os.file_info_slice_delete(fis)

	file, err := os.open(from)
	if err != nil {
		fmt.eprintf("error opening folder %s: %q", from, err)
		return res[:]
	}

	// free meme on exit
	defer os.close(file)
	fis, err = os.read_dir(file, 0, allocator)
	if err != os.ERROR_NONE {
		fmt.eprintf("Error reading directory %s: %q\n", from, err)
		os.exit(2)
	}

	for fi in fis {
		if !fi.is_dir {
			ext := filepath.ext(fi.name)
			if slice.contains(movie_types, ext) {
				if err != nil {
					fmt.eprintf("error creating target from file base: %q", err)
				}
				target, _ := strings.replace(fi.name, ext, ".avi", -1)
				append(&res, ScreenCapture{name = strings.clone(fi.name), target = target})
			}
		}
	}
	return res[:]
}
