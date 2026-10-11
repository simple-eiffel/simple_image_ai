# Changelog

All notable changes to simple_image_ai will be documented in this file.

## [0.2.2] - 2026-10-11

### Added
- `test_cutout_lets_other_processors_run` (with `CUTOUT_WORKER`, `CUTOUT_DONE`): the
  BiRefNet-portrait cutout runs on another processor while the test allocates and times its
  longest stall. With simple_onnx 1.0 it stalled 12,785 ms; with simple_onnx 1.1.0 (ONNX
  calls marked `C blocking`) 627 and 559 ms. simple_prompter's window had frozen the same way.

## [0.2.1] - 2026-10-11

### Added
- IMG_CUTOUT.close: unload the model and free its memory now (BiRefNet holds about a
  gigabyte; simple_prompter's Publish worker lives as long as the app).

## [0.2.0] - 2026-10-11

### Added
- IMG_CUTOUT.make_portrait: the BiRefNet-portrait model (1024x1024, output through a sigmoid),
  which leaves a chair behind the person out. Chosen by measurement over u2net_human_seg,
  birefnet-general-lite and isnet-general-use on three takes with hand-cleared cutouts:
  89-97% of the chair cleared, IoU 0.987 against the hand masks. Against rembg's own
  BiRefNet on a 1920x1080 frame: IoU 0.9998, mean difference 0.07 levels, about 10 seconds.
- SIMPLE_IMAGE_AI: new_portrait_cutout, portrait_model_path, rembg_models.

## [0.1.0] - 2026-10-11

### Added
- IMG_CUTOUT: person mask from u2net_human_seg on simple_onnx, rembg's recipe (Lanczos to
  320x320, divide by the largest value, mean/std per channel, channels first; the first
  output stretched to 0-255 and resized back). `mask_for`, `cut_out`.
- SIMPLE_IMAGE_AI facade: `new_cutout`, `rembg_model_path`.
- Tests: missing model reported; mask against rembg's on a real frame (IoU 0.9997, mean
  difference 0.09 levels, 262 ms); a 1280x720 thumbnail composed from the cutout
  (glow, darkened blurred background, outlined title).
