#!/usr/bin/env bash
set -euo pipefail

# Snapshot the current Raspberry Pi 3 Yocto image artifacts and build metadata.
#
# Usage:
#   ./snapshot-rpi3-image.sh
#   ./snapshot-rpi3-image.sh my-release-name

BUILD_DIR="${BUILD_DIR:-$HOME/yocto-rpi3/build-rpi3}"
YOCTO_ROOT="${YOCTO_ROOT:-$HOME/yocto-rpi3}"
MACHINE="${MACHINE:-raspberrypi3}"
IMAGE_NAME="${IMAGE_NAME:-core-image-base}"

RELEASE_NAME="${1:-rpi3-poc-snapshot-$(date +%Y%m%d-%H%M%S)}"

IMGDIR="$BUILD_DIR/tmp/deploy/images/$MACHINE"
REL="$YOCTO_ROOT/releases/$RELEASE_NAME"

WIC_BZ2="$IMGDIR/${IMAGE_NAME}-${MACHINE}.wic.bz2"
BMAP="$IMGDIR/${IMAGE_NAME}-${MACHINE}.wic.bmap"
MANIFEST="$IMGDIR/${IMAGE_NAME}-${MACHINE}.manifest"

echo "Creating Yocto image snapshot..."
echo "Build dir:      $BUILD_DIR"
echo "Image dir:      $IMGDIR"
echo "Release dir:    $REL"
echo

mkdir -p "$REL"

# Basic sanity checks
for f in "$WIC_BZ2" "$BMAP" "$MANIFEST" "$BUILD_DIR/conf/local.conf" "$BUILD_DIR/conf/bblayers.conf"; do
  if [ ! -e "$f" ]; then
    echo "ERROR: Required file not found: $f" >&2
    exit 1
  fi
done

# Copy image artifacts. Use -L so symlinks are resolved to real files.
cp -L "$WIC_BZ2" "$REL/${IMAGE_NAME}-${MACHINE}.wic.bz2"
cp -L "$BMAP" "$REL/${IMAGE_NAME}-${MACHINE}.wic.bmap"
cp -L "$MANIFEST" "$REL/${IMAGE_NAME}-${MACHINE}.manifest"

# Copy build configuration.
cp "$BUILD_DIR/conf/local.conf" "$REL/local.conf"
cp "$BUILD_DIR/conf/bblayers.conf" "$REL/bblayers.conf"

# Capture layer list if available.
if command -v bitbake-layers >/dev/null 2>&1; then
  (
    cd "$BUILD_DIR"
    bitbake-layers show-layers
  ) > "$REL/layers.txt"
else
  echo "bitbake-layers not found in PATH. Source oe-init-build-env before running for layer metadata." \
    > "$REL/layers.txt"
fi

# Capture Git revisions.
{
  for repo in poky meta-openembedded meta-raspberrypi; do
    if git -C "$YOCTO_ROOT/$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "$repo: $(git -C "$YOCTO_ROOT/$repo" rev-parse HEAD)"
      echo "$repo branch: $(git -C "$YOCTO_ROOT/$repo" rev-parse --abbrev-ref HEAD)"
    else
      echo "$repo: not found"
    fi
  done
} > "$REL/git-revisions.txt"

# Add restore instructions.
cat > "$REL/README-RESTORE.md" <<EOF
# Yocto Raspberry Pi 3 Image Snapshot

Snapshot created: $(date)
Machine: $MACHINE
Image: $IMAGE_NAME

## Contents

- \`${IMAGE_NAME}-${MACHINE}.wic.bz2\` — compressed flashable SD-card image
- \`${IMAGE_NAME}-${MACHINE}.wic.bmap\` — bmap file for faster flashing
- \`${IMAGE_NAME}-${MACHINE}.manifest\` — package manifest
- \`local.conf\` — build local configuration at snapshot time
- \`bblayers.conf\` — layer configuration at snapshot time
- \`layers.txt\` — layer list
- \`git-revisions.txt\` — source layer Git revisions
- \`SHA256SUMS\` — checksums for verification

## Verify Snapshot

\`\`\`bash
sha256sum -c SHA256SUMS
\`\`\`

## Reflash SD Card

Replace \`/dev/mmcblk0\` with the correct SD-card device.

\`\`\`bash
sudo bmaptool copy \\
  --bmap ${IMAGE_NAME}-${MACHINE}.wic.bmap \\
  ${IMAGE_NAME}-${MACHINE}.wic.bz2 \\
  /dev/mmcblk0

sync
\`\`\`
EOF

# Generate checksums last, excluding the checksum file itself.
(
  cd "$REL"
  find . -maxdepth 1 -type f ! -name SHA256SUMS -print0 \
    | sort -z \
    | xargs -0 sha256sum
) > "$REL/SHA256SUMS"

echo
echo "Snapshot complete:"
ls -lh "$REL"
echo
echo "Verify with:"
echo "  cd \"$REL\" && sha256sum -c SHA256SUMS"
