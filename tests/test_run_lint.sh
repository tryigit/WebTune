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

assert_command() {
    local test_name="${1}"
    local expected_exit="${2}"
    local expected_substrings="${3}"
    shift 3

    echo "Running ${test_name}..."
    local output
    local exit_code=0
    output=$("$@" 2>&1) || exit_code=$?

    if [[ ${exit_code} -ne ${expected_exit} ]]; then
        echo "${test_name} Failed: Expected exit code ${expected_exit}, got ${exit_code}."
        echo "Output: ${output}"
        exit 1
    fi

    if [[ -n "${expected_substrings}" ]]; then
        IFS='|' read -ra SUBSTRINGS <<< "${expected_substrings}"
        for substr in "${SUBSTRINGS[@]}"; do
            if [[ "${output}" != *"${substr}"* ]]; then
                echo "${test_name} Failed: Expected substring \"${substr}\" not found in output."
                echo "Output: ${output}"
                exit 1
            fi
        done
    fi

    echo "${test_name} Passed."
}

# Test 1: Valid markdown file should pass
echo "# Valid Title" > "${TMP_DIR}/valid.md"
echo "This is a valid markdown file." >> "${TMP_DIR}/valid.md"
assert_command "Test 1" 0 "Linting passed for ${TMP_DIR}/valid.md" \
    "${REPO_ROOT}/tests/run_lint.sh" "${TMP_DIR}/valid.md"

# Test 2: Invalid markdown file (simulated by "error" keyword in mock) should fail
echo "# Invalid Title" > "${TMP_DIR}/invalid.md"
echo "This file contains an error." >> "${TMP_DIR}/invalid.md"
assert_command "Test 2" 1 "Linting error found in ${TMP_DIR}/invalid.md" \
    "${REPO_ROOT}/tests/run_lint.sh" "${TMP_DIR}/invalid.md"

# Test 3: Unsupported npx command
assert_command "Test 3" 1 "Unknown command: unsupported-command" \
    npx unsupported-command

# Test 4: Default argument should use current directory
assert_command "Test 4" 0 "Linting passed for ." \
    "${REPO_ROOT}/tests/run_lint.sh"

# Test 5: Multiple arguments
echo "# Valid" > "${TMP_DIR}/valid2.md"
echo "Valid file." >> "${TMP_DIR}/valid2.md"
assert_command "Test 5" 0 "Linting passed for ${TMP_DIR}/valid.md|Linting passed for ${TMP_DIR}/valid2.md" \
    "${REPO_ROOT}/tests/run_lint.sh" "${TMP_DIR}/valid.md" "${TMP_DIR}/valid2.md"

# Test 6: Multiple arguments with one error
assert_command "Test 6" 1 "Linting passed for ${TMP_DIR}/valid.md|Linting error found in ${TMP_DIR}/invalid.md" \
    "${REPO_ROOT}/tests/run_lint.sh" "${TMP_DIR}/valid.md" "${TMP_DIR}/invalid.md"

# Test 7: Non-existent file should fail
assert_command "Test 7" 1 "File not found: non_existent.md" "${REPO_ROOT}/tests/run_lint.sh" "non_existent.md"

# Test 8: Empty string argument should fall back to current directory
assert_command "Test 8" 0 "Linting passed for ." \
    "${REPO_ROOT}/tests/run_lint.sh" ""

echo "All tests passed!"
