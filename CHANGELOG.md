# Changelog

All notable changes to simple_image_ai will be documented in this file.

## [0.1.0] - 2026-10-11

### Added
- IMG_CUTOUT: person mask from u2net_human_seg on simple_onnx, rembg's recipe (Lanczos to
  320x320, divide by the largest value, mean/std per channel, channels first; the first
  output stretched to 0-255 and resized back). `mask_for`, `cut_out`.
- SIMPLE_IMAGE_AI facade: `new_cutout`, `rembg_model_path`.
- Tests: missing model reported; mask against rembg's on a real frame (IoU 0.9997, mean
  difference 0.09 levels, 262 ms); a 1280x720 thumbnail composed from the cutout
  (glow, darkened blurred background, outlined title).
