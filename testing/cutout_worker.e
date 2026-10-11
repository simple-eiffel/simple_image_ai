note
	description: "[
		Loads BiRefNet-portrait and cuts the test photo out, on a processor of its own, for
		LIB_TESTS.test_cutout_lets_other_processors_run; raises `done' when it finishes.
	]"
	author: "Larry Rix"

class
	CUTOUT_WORKER

create
	make

feature {NONE} -- Initialization

	make (a_done: separate CUTOUT_DONE)
			-- A worker that raises `a_done' when its cutout is done.
		do
			done := a_done
		end

feature -- Work

	run
			-- Load the model, cut the photo out, unload, raise `done'.
			-- (No postcondition: one on a separate call makes the caller wait for it.)
		local
			l_ai: SIMPLE_IMAGE_AI
			l_images: SIMPLE_IMAGE
			l_cutout: IMG_CUTOUT
			l_made: BOOLEAN
		do
			create l_ai.make
			l_cutout := l_ai.new_portrait_cutout (l_ai.portrait_model_path)
			create l_images.make
			if l_cutout.is_ready and then attached l_images.load (Photo) as al_photo then
				l_made := attached l_cutout.mask_for (al_photo)
			end
			l_cutout.close
			raise (done, l_made)
		end

feature {NONE} -- Implementation

	done: separate CUTOUT_DONE
			-- Raised when the cutout is done.

	raise (a_done: separate CUTOUT_DONE; a_made: BOOLEAN)
		do
			a_done.set (a_made)
		end

	Photo: STRING = "data/input/person.png"
			-- The local test photo (never committed).

end
