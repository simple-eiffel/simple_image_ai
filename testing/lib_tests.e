note
	description: "[
		Tests for simple_image_ai. The photo tests need a local photo of a person at
		data/input/person.png and rembg's mask of it at data/expected/person_mask_rembg.png
		(made by .eiffel-workflow/evidence/rembg_reference.py). Photos are never committed;
		without them those tests say SKIPPED.
	]"
	author: "Larry Rix"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Tests

	test_missing_model_reports
			-- A missing model is reported, not raised.
		local
			l_cutout: IMG_CUTOUT
		do
			create l_cutout.make ("data/input/no_such_model.onnx")
			assert ("not ready", not l_cutout.is_ready)
			assert ("reason: " + l_cutout.last_error, l_cutout.last_error.has_substring ("no model"))
		end

	test_mask_matches_rembg
			-- The Eiffel mask of a real photo against rembg's own mask of it.
		local
			l_images: SIMPLE_IMAGE
			l_t0: REAL_64
			l_stats: MANAGED_POINTER
		do
			create l_images.make
			if attached ready_cutout as al_cutout and then attached l_images.load (Photo) as al_photo
				and then attached l_images.load_mask (Expected_mask) as al_reference
			then
				l_t0 := now_ms
				if attached al_cutout.mask_for (al_photo) as al_mask then
					io.put_string ("    mask of " + al_photo.width.out + "x" + al_photo.height.out + " in "
						+ (now_ms - l_t0).truncated_to_integer.out + " ms%N")
					assert ("same size", al_mask.width = al_reference.width and al_mask.height = al_reference.height)
					create l_stats.make (4 * 8)
					c_compare (al_mask.values, al_reference.values, al_mask.pixel_count, l_stats.item)
					io.put_string ("    vs rembg: largest difference " + l_stats.read_real_64 (0).out
						+ ", mean " + rounded (l_stats.read_real_64 (8)) + ", IoU at 128 " + rounded (l_stats.read_real_64 (16))
						+ " (person pixels: eiffel " + l_stats.read_real_64 (24).truncated_to_integer.out + ")%N")
					assert ("mask written", al_mask.save_png (output_path ("person_mask_eiffel.png")))
					assert ("IoU at least 0.99", l_stats.read_real_64 (16) >= 0.99)
					assert ("mean difference at most 1 level", l_stats.read_real_64 (8) <= 1.0)
				else
					assert ("ran: " + al_cutout.last_error, False)
				end
			else
				io.put_string ("    SKIPPED: needs the model, " + Photo + " and " + Expected_mask + "%N")
			end
		end

	test_thumbnail_from_cutout
			-- Verification queue 4 and 6: cut the person out (color under alpha 0 kept), give them
			-- a glow, place them on a darkened, blurred copy of the frame, title in outlined text.
			-- Writes data/output/thumbnail.jpg (1280x720).
		local
			l_images: SIMPLE_IMAGE
			l_background, l_person, l_result: IMG_IMAGE
			l_glow: IMG_MASK
			l_canvas: IMG_CANVAS
			x, y, l_kept: INTEGER
		do
			create l_images.make
			if attached ready_cutout as al_cutout and then attached l_images.load (Photo) as al_photo then
				if attached al_cutout.cut_out (al_photo) as al_cut then
					from y := 0 until y >= al_cut.height or l_kept > 0 loop
						from x := 0 until x >= al_cut.width or l_kept > 0 loop
							if (al_cut.pixel (x, y) |>> 24) = 0 and (al_cut.pixel (x, y) & 0xFFFFFF) /= 0 then
								if (al_cut.pixel (x, y) & 0xFFFFFF) = (al_photo.pixel (x, y) & 0xFFFFFF) then
									l_kept := l_kept + 1
								end
							end
							x := x + 7
						end
						y := y + 7
					end
					assert ("color kept under alpha 0", l_kept > 0)

					l_background := al_photo.resized (1280, 720)
					l_background.blur (6)
					l_background.enhance_brightness (0.45)
					l_background.vignette (0.6)
					l_person := al_cut.resized (1280, 720)
					l_glow := l_person.alpha
					l_glow.grow (6)
					l_glow.blur (10)

					l_canvas := l_images.canvas_from (l_background)
					l_canvas.fill_through (l_glow, 0xFFFFD34D, 0, 0)
					l_canvas.place (l_person, 0, 0)
					l_canvas.context.select_font ("Impact", l_canvas.context.Slant_normal, l_canvas.context.Weight_normal)
						.set_font_size (130).move_to (60, 660).text_path ("SIMPLE IMAGE").do_nothing
					l_canvas.context.set_color_rgb (0, 0, 0).set_line_width (14).set_line_join (l_canvas.context.Join_round).stroke_preserve
						.set_color_rgb (1, 0.83, 0.3).fill.do_nothing
					l_result := l_canvas.to_image
					l_canvas.destroy
					assert ("opaque", l_result.is_opaque)
					assert ("jpg written", l_result.save_jpg (output_path ("thumbnail.jpg"), 92))
				else
					assert ("cut out: " + al_cutout.last_error, False)
				end
			else
				io.put_string ("    SKIPPED: needs the model and " + Photo + "%N")
			end
		end

feature {NONE} -- Helpers

	Photo: STRING = "data/input/person.png"
			-- Local test photo (never committed).

	Expected_mask: STRING = "data/expected/person_mask_rembg.png"
			-- rembg's mask of `Photo'.

	ready_cutout: detachable IMG_CUTOUT
			-- The model, loaded once, when present.
		local
			l_cutout: IMG_CUTOUT
		once
			l_cutout := (create {SIMPLE_IMAGE_AI}.make).new_cutout ((create {SIMPLE_IMAGE_AI}.make).rembg_model_path)
			if l_cutout.is_ready then
				Result := l_cutout
			end
		end

	rounded (a_value: REAL_64): STRING
			-- `a_value' with four decimals.
		do
			Result := (create {FORMAT_DOUBLE}.make (10, 4)).formatted (a_value)
			Result.left_adjust
		end

	output_path (a_name: STRING): STRING
			-- data/output/`a_name', creating the folder when needed.
		local
			l_dir: DIRECTORY
		do
			create l_dir.make ("data/output")
			if not l_dir.exists then
				l_dir.recursive_create_dir
			end
			Result := "data/output/" + a_name
		end

	c_compare (a_a, a_b: POINTER; a_n: INTEGER; a_out: POINTER)
			-- Largest and mean absolute difference, IoU at 128, and person pixels of `a_a'.
		external
			"C inline"
		alias
			"[
				const unsigned char *a = (const unsigned char *) $a_a, *b = (const unsigned char *) $a_b;
				size_t i, n = (size_t) $a_n; double worst = 0, sum = 0, both = 0, either = 0, mine = 0;
				for (i = 0; i < n; i++) {
					double d = a[i] > b[i] ? a[i] - b[i] : b[i] - a[i];
					if (d > worst) worst = d;
					sum += d;
					if (a[i] >= 128 && b[i] >= 128) both++;
					if (a[i] >= 128 || b[i] >= 128) either++;
					if (a[i] >= 128) mine++;
				}
				((double *) $a_out)[0] = worst; ((double *) $a_out)[1] = sum / (n ? n : 1);
				((double *) $a_out)[2] = either > 0 ? both / either : 1.0; ((double *) $a_out)[3] = mine;
			]"
		end

	now_ms: REAL_64
			-- A millisecond clock.
		external
			"C inline use <windows.h>"
		alias
			"LARGE_INTEGER f, c; QueryPerformanceFrequency (&f); QueryPerformanceCounter (&c); return (EIF_REAL_64) c.QuadPart * 1000.0 / (EIF_REAL_64) f.QuadPart;"
		end

end
