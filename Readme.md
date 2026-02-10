# Compress - monitor and compress \*.mov files

<!--toc:start-->

- [Compress - monitor and compress \*.mov files](#compress-monitor-and-compress-mov-files)
  - [Why Odin ?](#why-odin)
  - [How to use](#how-to-use)
    - [using Makefile](#using-makefile)
    - [manual build](#manual-build)
    - [want to keep it ?](#want-to-keep-it)
    - [troubleshooting](#troubleshooting)
    <!--toc:end-->


https://github.com/user-attachments/assets/bc1c2a5b-b38b-49c2-b03c-c947c72336fe


- screen recording is great, sharing uncompressed video is not
- this small utility will check ~/Desktop/screenshots folder for changes,
  compress any new file and delete the original

## Why Odin ?

- because why not, it is small and fast. 
- learn to use and familiarize with it

## How to use

- build binary or use released one
- by default it will monitor ~/Desktop/screenshots folder
- it assumes ffmpeg is installed with homebrew in /opt/homebrew/bin/ffmpeg
- default configuration can be changed by modifying sample_compress.bin, move it to ~/.compress.bin
- move the compress.bin to /opt/homebrew/bin/compress.bin and make it executable
- edit com.compress.odin.plist and move it to ~/Library/LaunchAgents
- use launchctl to load the plist

### using Makefile

- includes binary optimisation

```zsh
make
```

### manual build

```zsh
odin build compress -o compress.bin
chmod +x compress.bin
mv compress.bin /usr/local/bin # or in /opt/homebrew/bin
```

- edit `com.compress.odin.plist` to your liking

```zsh
launchctl load ~/pathtoprogram/com.compress.odin.plist
```

- go to ~/Desktop/screenshots , watch finder and make a screen recording

- the OS will ask you to confirm allowing compress to access your Desktop data

### Want to keep it ?

- move the plist file to user launch agents and run the commands
- register

```zsh
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.compress.odin.plist
```
- load if it was unloaded
```zsh
launchctl enable gui/$(id -u)/com.compress.odin.plist
```

- if one need to remove it

```zsh
launchctl bootout gui/$(id -u)/com.compress.odin
```

### Troubleshooting

- check your plist is corect

```zsh
 plutil -lint com.compress.odin.plist

```

- check program is loaded

```zsh
launchctl print gui/$(id -u) | grep compress
```
