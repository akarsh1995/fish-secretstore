#!/usr/bin/env fish

# Test runner for fish-secretstore plugin
# Runs both structure validation and functional tests

set -l plugin_dir (dirname (status --current-filename))

echo "🧪 Running fish-secretstore test suite"
echo "======================================"
echo

# Initialize test result variables
set -l structure_passed false
set -l functional_passed false

# Run structure validation tests
echo "📁 Running plugin structure validation..."
if fish $plugin_dir/test.fish
    echo "✅ Plugin structure tests passed"
    set structure_passed true
else
    echo "❌ Plugin structure tests failed"
    set structure_passed false
end

echo
echo "🔒 Running functional tests..."

# Run functional tests
if fish $plugin_dir/tests/test_functionality.fish
    echo "✅ Functional tests passed"
    set functional_passed true
else
    echo "❌ Functional tests failed"
    set functional_passed false
end

echo
echo "======================================"
echo "📊 Test Results Summary:"

if test "$structure_passed" = true
    echo "✅ Plugin Structure: PASSED"
else
    echo "❌ Plugin Structure: FAILED"
end

if test "$functional_passed" = true
    echo "✅ Functionality: PASSED"
else
    echo "❌ Functionality: FAILED"
end

echo

if test "$structure_passed" = true -a "$functional_passed" = true
    echo "🎉 All tests passed! fish-secretstore is ready for production."
    exit 0
else
    echo "🔧 Some tests failed. Please review and fix the issues."
    exit 1
end
