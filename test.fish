#!/usr/bin/env fish

# Test script to validate fish-secretstore plugin structure
# This script checks if all required files are present and properly structured

function test_plugin_structure
    set -l plugin_dir (dirname (status --current-filename))
    set -l errors 0

    echo "Testing fish-secretstore plugin structure..."
    echo "Plugin directory: $plugin_dir"
    echo

    # Check required directories
    set -l required_dirs functions completions conf.d
    for dir in $required_dirs
        if test -d "$plugin_dir/$dir"
            echo "✓ Directory $dir exists"
        else
            echo "✗ Missing directory: $dir"
            set errors (math $errors + 1)
        end
    end

    # Check required files
    set -l required_files functions/secret.fish completions/secret.fish conf.d/secret.fish README.md LICENSE
    for file in $required_files
        if test -f "$plugin_dir/$file"
            echo "✓ File $file exists"
        else
            echo "✗ Missing file: $file"
            set errors (math $errors + 1)
        end
    end

    # Check function definitions
    echo
    echo "Checking function definitions..."

    set -l expected_functions secret _secret_add _secret_delete _secret_edit _secret_export _secret_get _secret_list _secret_load _secret_help __fish_complete_secrets
    for func in $expected_functions
        if grep -q "function $func" $plugin_dir/functions/*.fish $plugin_dir/completions/secret.fish
            if test -f "$plugin_dir/functions/$func.fish"
                echo "✓ Function $func defined in functions/$func.fish"
            else
                echo "✗ Function $func is not in its own file functions/$func.fish"
                set errors (math $errors + 1)
            end
        else
            echo "✗ Missing function: $func"
            set errors (math $errors + 1)
        end
    end

    # Check event handlers
    echo
    echo "Checking Fisher event handlers..."

    set -l event_handlers _secretstore_install _secretstore_update _secretstore_uninstall
    for handler in $event_handlers
        if grep -q "function $handler --on-event" "$plugin_dir/conf.d/secret.fish"
            echo "✓ Event handler $handler defined"
        else
            echo "✗ Missing event handler: $handler"
            set errors (math $errors + 1)
        end
    end

    # Check completions
    echo
    echo "Checking completions..."

    if grep -q "complete -c secret" "$plugin_dir/completions/secret.fish"
        echo "✓ Completions defined"
    else
        echo "✗ No completions found"
        set errors (math $errors + 1)
    end

    # Check for Fisher compliance
    echo
    echo "Checking Fisher compliance..."

    # Check for proper directory structure
    if test -d "$plugin_dir/functions" -a -d "$plugin_dir/completions" -a -d "$plugin_dir/conf.d"
        echo "✓ Fisher directory structure"
    else
        echo "✗ Invalid Fisher directory structure"
        set errors (math $errors + 1)
    end

    # Check for event system usage
    if grep -q "on-event.*install\|on-event.*update\|on-event.*uninstall" "$plugin_dir/conf.d/secret.fish"
        echo "✓ Fisher event system usage"
    else
        echo "✗ Missing Fisher event handlers"
        set errors (math $errors + 1)
    end

    # Check for version command
    if grep -q version $plugin_dir/functions/*.fish
        echo "✓ Version command available"
    else
        echo "✗ Missing version command"
        set errors (math $errors + 1)
    end

    # Check for help command
    if grep -q "help\|_secret_help" $plugin_dir/functions/*.fish
        echo "✓ Help system available"
    else
        echo "✗ Missing help system"
        set errors (math $errors + 1)
    end

    # Summary
    echo
    if test $errors -eq 0
        echo "🎉 All tests passed! Plugin structure is valid for Fisher."
        echo "✅ Ready for Fisher installation"
        return 0
    else
        echo "❌ $errors error(s) found. Plugin structure needs fixes."
        return 1
    end
end

# Run the test
test_plugin_structure
