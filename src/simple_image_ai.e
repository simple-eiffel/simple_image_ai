note
	description: "[
		simple_image_ai - AI helpers for simple_image, on simple_onnx.

		IMG_CUTOUT: a mask of the people in a photo, with rembg's models: u2net_human_seg (fast)
		or BiRefNet-portrait (slower; leaves a chair behind the person out).

		Usage:
			ai: SIMPLE_IMAGE_AI
			create ai.make
			cutout := ai.new_portrait_cutout (ai.portrait_model_path)
			if cutout.is_ready and then attached cutout.cut_out (photo) as al_person then ... end
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_IMAGE_AI

create
	make

feature {NONE} -- Initialization

	make
			-- Ready.
		do
		end

feature -- Helpers

	new_cutout (a_model_path: READABLE_STRING_GENERAL): IMG_CUTOUT
			-- A person cutout running the u2net_human_seg model at `a_model_path'
			-- (check `is_ready'; loading takes about 2 seconds, so keep it).
		require
			path_not_empty: not a_model_path.is_empty
			narrow_path: a_model_path.is_valid_as_string_8
		do
			create Result.make (a_model_path)
		end

	new_portrait_cutout (a_model_path: READABLE_STRING_GENERAL): IMG_CUTOUT
			-- A person cutout running the BiRefNet-portrait model at `a_model_path'
			-- (check `is_ready'; loading takes several seconds, so keep it).
		require
			path_not_empty: not a_model_path.is_empty
			narrow_path: a_model_path.is_valid_as_string_8
		do
			create Result.make_portrait (a_model_path)
		end

feature -- Model files

	rembg_model_path: STRING_32
			-- Where rembg keeps u2net_human_seg: %USERPROFILE%\.rembg\models\u2net_human_seg\.
		do
			Result := rembg_models + {STRING_32} "\u2net_human_seg\u2net_human_seg.onnx"
		ensure
			names_the_model: Result.ends_with ({STRING_32} "u2net_human_seg.onnx")
		end

	portrait_model_path: STRING_32
			-- Where rembg keeps BiRefNet-portrait: %USERPROFILE%\.rembg\models\birefnet-portrait\.
		do
			Result := rembg_models + {STRING_32} "\birefnet-portrait\birefnet-portrait.onnx"
		ensure
			names_the_model: Result.ends_with ({STRING_32} "birefnet-portrait.onnx")
		end

	rembg_models: STRING_32
			-- rembg's model folder: %USERPROFILE%\.rembg\models.
		do
			if attached (create {EXECUTION_ENVIRONMENT}).item ("USERPROFILE") as al_home then
				Result := al_home.to_string_32
			else
				create Result.make_empty
			end
			Result.append ({STRING_32} "\.rembg\models")
		end

	version: STRING = "0.2.2"
			-- Library version.

end
