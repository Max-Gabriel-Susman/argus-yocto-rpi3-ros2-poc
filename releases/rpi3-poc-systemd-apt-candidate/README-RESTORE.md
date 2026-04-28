# Yocto Raspberry Pi 3 Image Snapshot

Snapshot created: Sun Apr 26 02:24:08 PM MDT 2026
Machine: raspberrypi3
Image: core-image-base

## Contents

- `core-image-base-raspberrypi3.wic.bz2` — compressed flashable SD-card image
- `core-image-base-raspberrypi3.wic.bmap` — bmap file for faster flashing
- `core-image-base-raspberrypi3.manifest` — package manifest
- `local.conf` — build local configuration at snapshot time
- `bblayers.conf` — layer configuration at snapshot time
- `layers.txt` — layer list
- `git-revisions.txt` — source layer Git revisions
- `SHA256SUMS` — checksums for verification

## Verify Snapshot

```bash
sha256sum -c SHA256SUMS
```

## Reflash SD Card

Replace `/dev/mmcblk0` with the correct SD-card device.

```bash
sudo bmaptool copy \
  --bmap core-image-base-raspberrypi3.wic.bmap \
  core-image-base-raspberrypi3.wic.bz2 \
  /dev/mmcblk0

sync
```
