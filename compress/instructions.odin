package main

import "core:fmt"

info :: proc() {
	fmt.println(
		`
compress — Watch and compress .mov recordings

Usage:
  compress --watch <path>   Watch path for .mov and compress to .mp4
  compress --version        Show version

Options:
  -w, --watch <path>        Directory to watch
  -v, --version             Print version

Default: 
  If no directory is specified, compress watches: 
    ~/Desktop/Screenshot

Configuration:
  To override default config, create a config json file at: 
    ~/.config/compress/compress.json

Example config:
  {
    "store": "/full/path/to/screenshots",
    "encoder": "/full/path/to/ffmpeg"
  } 

  - store: Directory where the recordings are stored
  - encoder: Path to ffmpeg executable
`,
	)
}

printVersion :: proc() {
	fmt.println("compress v0.2.beta")
}
