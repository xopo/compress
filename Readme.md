# Compress - monitor and compress \*.mov files

- screen recording is great, sharing uncompressed video is not
- this small utility will check ~/Desktop/screenshots folder for changes,
  compress any new file and delete the original

## Why Odin ?

- because why not, it is small and fast.
- learn to use and familiarize with it

## How to use

- build with

```bash
odin build -o compress.bin
chmod +x compress.bin
mv compress.bin /usr/local/bin # or in /opt/homebrew/bin
```

- edit com.compress.odin.plist to your liking

```bash
launchctl load ~/pathtoprogram/com.compress.odin.plist
```

- go to ~/Desktop/screenshots , watch finder and make a screen recording

- Macos will ask you to confirm allowing compress to access your Desktop data
