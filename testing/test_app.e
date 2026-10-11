note
	description: "Test application runner for simple_image_ai (run from the library root)"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run all tests.
		local
			l_tests: LIB_TESTS
		do
			create l_tests
			io.put_string ("simple_image_ai test runner%N")
			io.put_string ("========================%N%N")

			run_test (agent l_tests.test_missing_model_reports, "test_missing_model_reports")
			run_test (agent l_tests.test_mask_matches_rembg, "test_mask_matches_rembg")
			run_test (agent l_tests.test_thumbnail_from_cutout, "test_thumbnail_from_cutout")

			io.put_string ("%N========================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				io.put_string ("TESTS FAILED%N")
			else
				io.put_string ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
			-- Number of passed tests

	failed: INTEGER
			-- Number of failed tests

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
			l_exc: detachable EXCEPTION
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			l_exc := (create {EXCEPTION_MANAGER}).last_exception
			if attached l_exc as al_exc then
				io.put_string ("  FAIL: " + a_name + " [" + al_exc.generator + ": " + al_exc.tag.out + "]%N")
			else
				io.put_string ("  FAIL: " + a_name + " [unknown]%N")
			end
			failed := failed + 1
			l_retried := True
			retry
		end

end
