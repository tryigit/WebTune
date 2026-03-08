#!/bin/bash

# Integration test for run_lint.sh

# Get the directory where the test script is located
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/.." && pwd)"
MOCK_DIR="$TEST_DIR/mock"

# Add mock directory to PATH
export PATH="$MOCK_DIR:$PATH"

# Create a temporary directory for test files
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Using temporary directory: $TMP_DIR"

# Test 1: Valid markdown file should pass
echo "# Valid Title" > "$TMP_DIR/valid.md"
echo "This is a valid markdown file." >> "$TMP_DIR/valid.md"

echo "Running Test 1: Valid markdown file..."
if "$REPO_ROOT/tests/run_lint.sh" "$TMP_DIR/valid.md"; then
    echo "Test 1 Passed: Valid markdown passed linting."
else
    echo "Test 1 Failed: Valid markdown failed linting."
    exit 1
fi

# Test 2: Invalid markdown file (simulated by "error" keyword in mock) should fail
echo "# Invalid Title" > "$TMP_DIR/invalid.md"
echo "This file contains an error." >> "$TMP_DIR/invalid.md"

echo "Running Test 2: Invalid markdown file..."
if "$REPO_ROOT/tests/run_lint.sh" "$TMP_DIR/invalid.md"; then
    echo "Test 2 Failed: Invalid markdown passed linting."
    exit 1
else
    echo "Test 2 Passed: Invalid markdown failed linting as expected."
fi

echo "All tests passed!"
exit 0
