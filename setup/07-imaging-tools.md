# 07 - Imaging Tools

CLI and scriptable image tools for icons, screenshots, asset generation, and conversions.

## Prerequisites

- Completed `03-dev-environment.md` (Node.js/npm for sharp/resvg)
- Package manager available (apt, npm)

---

## 1. ImageMagick (apt)

ImageMagick provides `magick` and legacy `convert` for resizing, cropping, format conversion, and inspection.

```bash
sudo apt install -y imagemagick
```

**Verify:**

```bash
magick -version | head -1
```

Expected output: `Version: ImageMagick 6.x.x` or similar

---

## 2. Node-based Tooling (npm global)

Install sharp and resvg for programmatic image processing and SVG→PNG rendering:

```bash
npm install -g sharp sharp-cli @resvg/resvg-js
```

- `sharp` / `sharp-cli` — PNG compositing, resizing, padding, rounded-corner masks
- `@resvg/resvg-js` — High-quality SVG to PNG rendering from Node scripts

**Verify (Node must be on PATH; use `nvm use` or `source ~/.nvm/nvm.sh` if needed):**

```bash
sharp --help 2>/dev/null | head -1
NODE_PATH="$(npm root -g 2>/dev/null)" node -e "require('sharp'); console.log('sharp OK')"
NODE_PATH="$(npm root -g 2>/dev/null)" node -e "require('@resvg/resvg-js'); console.log('resvg OK')"
```

Expected output: help line and `sharp OK`, `resvg OK`

---

## 3. Additional CLI Tools (apt)

Install required and optional tools; all provide global CLI commands:

| Tool | Package | Use case |
|-------------|----------------------|-----------------------------------|
| ffmpeg | `ffmpeg` | Animated images, GIFs, thumbnails |
| Inkscape | `inkscape` | SVG editing, `inkscape --export-type=png` |
| GraphicsMagick | `graphicsmagick` | ImageMagick alternative, sometimes faster |
| pngquant | `pngquant` | Lossy PNG compression |
| optipng | `optipng` | Lossless PNG optimization |
| exiftool | `libimage-exiftool-perl` | Read/write image metadata |

```bash
# Required imaging CLIs
sudo apt install -y ffmpeg inkscape graphicsmagick

# Recommended extras
sudo apt install -y pngquant optipng libimage-exiftool-perl
```

**Verify installed tools:**

```bash
command -v pngquant && pngquant --version
command -v optipng && optipng -v 2>&1 | head -1
command -v exiftool && exiftool -ver
command -v ffmpeg && ffmpeg -version 2>&1 | head -1
command -v inkscape && inkscape --version | head -1
command -v gm && gm version
```

---

## Complete Verification

Run the verification script:

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh
```

Or manually:

```bash
echo "=== Imaging Tools ==="
magick -version 2>/dev/null | head -1 || echo "ImageMagick missing"
sharp --help 2>/dev/null | head -1 || echo "sharp-cli missing"
NODE_PATH="$(npm root -g 2>/dev/null)" node -e "require('sharp'); console.log('sharp OK')" 2>/dev/null || echo "sharp module missing"
NODE_PATH="$(npm root -g 2>/dev/null)" node -e "require('@resvg/resvg-js'); console.log('resvg OK')" 2>/dev/null || echo "resvg missing"
command -v ffmpeg >/dev/null && echo "ffmpeg installed" || echo "ffmpeg missing"
command -v inkscape >/dev/null && echo "inkscape installed" || echo "inkscape missing"
command -v gm >/dev/null && echo "graphicsmagick (gm) installed" || echo "graphicsmagick (gm) missing"
command -v pngquant >/dev/null && echo "pngquant: $(pngquant --version 2>&1 | head -1)" || echo "pngquant not installed"
command -v exiftool >/dev/null && echo "exiftool: $(exiftool -ver)" || echo "exiftool not installed"
```

## Verification Checklist

- [ ] ImageMagick: `magick -version` shows version
- [ ] sharp CLI: `sharp --help` prints help
- [ ] sharp module: `NODE_PATH="$(npm root -g)" node -e "require('sharp')"` succeeds
- [ ] resvg module: `NODE_PATH="$(npm root -g)" node -e "require('@resvg/resvg-js')"` succeeds
- [ ] ffmpeg installed: `ffmpeg -version` shows version
- [ ] inkscape installed: `inkscape --version` shows version
- [ ] graphicsmagick installed: `gm version` shows version
- [ ] Optional: pngquant, optipng, exiftool as needed

**Next:** Continue to voice tools (`05-voice-tools-*.md`) or optional tools (`06-optional.md`) as needed.
