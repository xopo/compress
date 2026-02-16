# Compress - monitor and compress \*.mov files

<https://github.com/user-attachments/assets/bc1c2a5b-b38b-49c2-b03c-c947c72336fe>

- screen recording is great, sharing uncompressed video is not
- this small utility will check ~/Desktop/Screenshots folder for changes,
  convert any new file and delete the original

## Why Odin ?

- because why not, it is small and fast. Is so small you could share it
  on a floppy disk 💾.
- learn to use and familiarize with it

## How to use

- install with homebrew (Apple Sillicon only supported)

```zsh
brew tap xopo/compress
brew install compress
brew services start compress
```

- last one ensure the service starts and will be enable on reboot

- it can also be run manually

```zsh
compress.bin
```

- in order to override the default config, add ~/.config/compress/compress.json
  (check sample_compress.json)
