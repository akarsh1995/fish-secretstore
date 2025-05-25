#!/usr/bin/env fish

# Functional test script for fish-secretstore plugin
# Tests basic encrypt/decrypt functionality

# Get plugin directory before changing directories
set -x plugin_dir (dirname (status --current-filename))/..

# Source the secretstore function from the plugin directory
source $plugin_dir/functions/secret.fish
source $plugin_dir/tests/setup_test_gpg_key.fish

function run_all_tests
    echo "🔒 Starting fish-secretstore functional tests"
    echo "=========================================="
    echo

    set -l total_errors 0

    # Set up environment
    setup_test_environment

    # Clean up
    cleanup_test_environment

    # Summary
    echo "=========================================="
    if test $total_errors -eq 0
        echo "🎉 All functional tests passed!"
        echo "✅ fish-secretstore is working correctly"
        return 0
    else
        echo "❌ $total_errors error(s) found in functional tests"
        echo "🔧 fish-secretstore needs fixes"
        return 1
    end
end

# Run the tests if script is executed directly
if test (basename (status --current-filename)) = "test_functionality.fish"
    run_all_tests
end
