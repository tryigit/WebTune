🎯 What
Added missing integration test in `tests/test_run_lint.sh` to explicitly test that calling `run_lint.sh` with an empty string argument gracefully falls back to linting the current directory (`.`).

📊 Coverage
Covers the edge case scenario of invoking the run_lint script with `""`. It now asserts the fallback logic correctly passes linting and yields a 0 exit status.

✨ Result
Provides higher confidence in script argument handling and guards against regression.
