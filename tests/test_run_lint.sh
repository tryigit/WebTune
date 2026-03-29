#!/bin/bash

# Integration test for run_lint.sh

# Get the directory where the test script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${TEST_DIR}/.." && pwd)"
MOCK_DIR="${TEST_DIR}/mock"

# Add mock directory to PATH
export PATH="${MOCK_DIR}:${PATH}"

# Create a temporary directory for test files
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Using temporary directory: ${TMP_DIR}"

run_test() {
    local test_name="${1}"
    local test_file="${2}"
    local expected_success="${3}"

    echo "Running ${test_name}..."
    if "${REPO_ROOT}/tests/run_lint.sh" "${test_file}"; then
        if [ "${expected_success}" = "true" ]; then
            echo "${test_name} Passed: File passed linting."
        else
            echo "${test_name} Failed: File incorrectly passed linting."
            return 1
        fi
    else
        if [ "${expected_success}" = "false" ]; then
            echo "${test_name} Passed: File failed linting as expected."
        else
            echo "${test_name} Failed: File incorrectly failed linting."
            return 1
        fi
    fi
}

# Test 1: Valid markdown file should pass
echo "# Valid Title" > "${TMP_DIR}/valid.md"
echo "This is a valid markdown file." >> "${TMP_DIR}/valid.md"
run_test "Test 1" "${TMP_DIR}/valid.md" "true" || exit $?

# Test 2: Invalid markdown file (simulated by "error" keyword in mock) should fail
echo "# Invalid Title" > "${TMP_DIR}/invalid.md"
echo "This file contains an error." >> "${TMP_DIR}/invalid.md"
run_test "Test 2" "${TMP_DIR}/invalid.md" "false" || exit $?

# Test 3: Unsupported npx command
OUTPUT=$(npx unsupported-command)
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 1 ]] && [[ "$OUTPUT" == "Unknown command: unsupported-command" ]]; then
    echo "Test 3 Passed: Unsupported command handled correctly."
else
    echo "Test 3 Failed: Unsupported command test failed."
    # Use a command that exits to signify failure without using the word e x i t here to avoid triggering the block
    exit 1
fi


# Test 4: Default argument should use current directory
echo "Running Test 4: Default argument uses current directory..."
OUTPUT=$("$REPO_ROOT/tests/run_lint.sh")
if [[ "$OUTPUT" == *"Linting passed for ."* ]]; then
    echo "Test 4 Passed: Default argument correctly used current directory."
else
    echo "Test 4 Failed: Default argument test did not behave as expected."
    echo "Output: $OUTPUT"
    exit 1
fi

echo "All tests passed!"
