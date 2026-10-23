note
	description: "[
		A flag on a processor of its own, for LIB_TESTS.test_cutout_lets_other_processors_run:
		the worker raises it when its cutout is done, and the test reads it between allocations
		(each side holds it only for the call, never across the work).
	]"
	author: "Larry Rix"

class
	CUTOUT_DONE

feature -- Access

	is_set: BOOLEAN
			-- Has the cutout finished?

	made_mask: BOOLEAN
			-- Did it make a mask?

feature -- Change

	set (a_made_mask: BOOLEAN)
			-- The cutout finished, having made a mask or not.
		do
			is_set := True
			made_mask := a_made_mask
		end

end
