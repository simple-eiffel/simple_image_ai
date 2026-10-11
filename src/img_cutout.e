note
	description: "[
		Person cutout: a mask of the people in a photo, from the u2net_human_seg model on
		simple_onnx (the model rembg uses), in pure Eiffel.

		Recipe (read from rembg's source): Lanczos to 320x320, divide by the image's largest
		value, per channel (x - mean) / std, channels first; the first output stretched to
		0-255 and resized back. simple_onnx was shown to run the model exactly (debate 01:
		largest difference from Python 5.4e-7, mask IoU 1.0).

		Usage:
			cutout: IMG_CUTOUT
			create cutout.make ((create {SIMPLE_IMAGE_AI}.make).rembg_model_path)
			if cutout.is_ready and then attached cutout.mask_for (photo) as al_mask then
				al_mask.keep_largest_piece (128)   -- optional: drop specks
				photo.set_alpha (al_mask)
			else
				print (cutout.last_error)
			end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	IMG_CUTOUT

create
	make

feature {NONE} -- Initialization

	make (a_model_path: READABLE_STRING_GENERAL)
			-- Load the u2net_human_seg model at `a_model_path' (about 2 seconds; do it once).
		require
			path_not_empty: not a_model_path.is_empty
			narrow_path: a_model_path.is_valid_as_string_8
		do
			create onnx.make
			last_error := ""
			if not (create {RAW_FILE}.make_with_name (a_model_path)).exists then
				last_error := "no model at " + a_model_path.to_string_8
			elseif attached onnx.load_model (a_model_path.to_string_8) as al_model
				and then attached onnx.create_session (al_model) as al_session
				and then al_session.is_loaded
			then
				session := al_session
			else
				last_error := "cannot load the model " + a_model_path.to_string_8
			end
		ensure
			ready_or_reason: is_ready = last_error.is_empty
		end

feature -- Access

	mask_for (a_image: IMG_IMAGE): detachable IMG_MASK
			-- Coverage of the people in `a_image' (same size; 255 = person), or Void (see `last_error').
			-- Alpha in `a_image' is ignored, as rembg ignores it.
		require
			ready: is_ready
			image_usable: a_image.is_usable
		local
			l_opaque, l_small: IMG_IMAGE
			l_full: IMG_MASK
			l_input, l_output: MANAGED_POINTER
			l_tensor: ONNX_TENSOR
			l_small_mask: IMG_MASK
		do
			l_opaque := a_image.twin
			create l_full.make_filled (a_image.width, a_image.height, 255)
			l_opaque.set_alpha (l_full)
			l_small := l_opaque.resized (Side, Side)
			l_opaque.destroy
			l_full.destroy

			create l_input.make (3 * Side * Side * 4)
			c_normalize (l_small.pixels, Side * Side, l_input.item)
			l_small.destroy
			l_tensor := onnx.create_tensor_float32 (onnx.create_shape (<<1, 3, Side, Side>>))
			l_tensor.set_data_from_pointer (l_input.item)

			if attached session as al_session then
				if attached al_session.execute (l_tensor) as al_result and then al_result.is_success
					and then attached al_result.output_tensor as al_out and then al_out.element_count = Side * Side
				then
					create l_output.make (Side * Side * 4)
					al_out.copy_data_to (l_output.item)
					create l_small_mask.make_from_floats (l_output.item, Side, Side)
					Result := l_small_mask.resized (a_image.width, a_image.height)
					l_small_mask.destroy
					last_error := ""
				else
					last_error := "the model run failed"
				end
			end
		ensure
			same_size: attached Result as al_mask implies (al_mask.width = a_image.width and al_mask.height = a_image.height)
			error_when_void: Result = Void implies not last_error.is_empty
		end

	cut_out (a_image: IMG_IMAGE): detachable IMG_IMAGE
			-- A copy of `a_image' with the people kept and the rest transparent (largest piece only),
			-- or Void (see `last_error').
		require
			ready: is_ready
			image_usable: a_image.is_usable
		do
			if attached mask_for (a_image) as al_mask then
				al_mask.keep_largest_piece (128)
				Result := a_image.twin
				Result.set_alpha (al_mask)
				al_mask.destroy
			end
		ensure
			same_size: attached Result as al_image implies (al_image.width = a_image.width and al_image.height = a_image.height)
		end

feature -- Status

	is_ready: BOOLEAN
			-- Was the model loaded?
		do
			Result := attached session as al_session and then al_session.is_loaded
		end

	last_error: STRING
			-- Why the model did not load or the last run failed ("" when all is well).

feature -- Constants

	Side: INTEGER = 320
			-- The model's square input size.

feature {NONE} -- Implementation

	onnx: SIMPLE_ONNX
			-- Runtime.

	session: detachable ONNX_SESSION
			-- The loaded model (create_session returns it loaded; do not call load again).

	c_normalize (a_rgba: POINTER; a_n: INTEGER; a_out: POINTER)
			-- rembg's normalization of `a_n' RGBA pixels into channels-first floats:
			-- divide by the largest R, G or B value, then (x - mean) / std per channel.
		external
			"C inline"
		alias
			"[
				const unsigned char *p = (const unsigned char *) $a_rgba; float *o = (float *) $a_out;
				size_t i, n = (size_t) $a_n; int c; double mx = 0.0;
				const double mean[3] = {0.485, 0.456, 0.406}, sd[3] = {0.229, 0.224, 0.225};
				for (i = 0; i < n; i++) for (c = 0; c < 3; c++) if (p[i * 4 + c] > mx) mx = p[i * 4 + c];
				if (mx < 1e-6) mx = 1e-6;
				for (c = 0; c < 3; c++) for (i = 0; i < n; i++) o[c * n + i] = (float) ((p[i * 4 + c] / mx - mean[c]) / sd[c]);
			]"
		end

invariant
	error_not_void: last_error /= Void

end
