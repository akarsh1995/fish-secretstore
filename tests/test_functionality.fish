#!/usr/bin/env fish

# Functional test script for fish-secretstore plugin
# Tests all secret management functionality

# Get plugin directory before changing directories
set -x plugin_dir (dirname (status --current-filename))/..

# Source the secretstore function from the plugin directory
source $plugin_dir/functions/secret.fish

# Global test variables
set -g test_dir ""
set -g total_errors 0

function setup_test_environment
    echo "🔧 Setting up test environment..." >&2

    # Set up test directory - use absolute path to avoid /tmp vs /private/tmp issues
    set -g test_dir (mktemp -d)
    cd $test_dir

    # Set test XDG_CONFIG_HOME
    set -gx XDG_CONFIG_HOME $test_dir/.config
    mkdir -p $XDG_CONFIG_HOME/fish/secure/secrets

    # Set up test GPG environment
    set -gx GNUPGHOME $test_dir/.gnupg
    mkdir -p $GNUPGHOME
    chmod 700 $GNUPGHOME

    echo "Test environment set up at: $test_dir" >&2
    echo "XDG_CONFIG_HOME: $XDG_CONFIG_HOME" >&2
    echo "GNUPGHOME: $GNUPGHOME" >&2
    echo >&2
end

function cleanup_test_environment
    echo >&2
    echo "🧹 Cleaning up test environment..." >&2

    # Clean up test directory
    if test -n "$test_dir" -a -d "$test_dir"
        rm -rf $test_dir
        echo "Test directory removed: $test_dir" >&2
    end

    # Reset environment variables
    set -e GNUPGHOME
    echo "Test environment cleaned up" >&2
end

function test_gpg_setup
    echo "📋 Testing GPG setup..." >&2

    # Create GPG key for testing
    echo "Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: Test User
Name-Email: test@example.com
Expire-Date: 0
%no-protection
%commit" >gpg_key_details.txt

    if gpg --batch --gen-key gpg_key_details.txt >/dev/null 2>&1
        echo "✓ GPG key created successfully" >&2
        rm gpg_key_details.txt

        # Configure the secret store to use our test key
        set -gx SECRETSTORE_GPG_RECIPIENT "test@example.com"
        echo "✓ Configured secretstore GPG recipient: test@example.com" >&2
        return 0
    else
        echo "✗ Failed to create GPG key" >&2
        rm -f gpg_key_details.txt
        return 1
    end
end

function test_secret_add
    echo "📋 Testing secret add functionality..." >&2
    set -l errors 0

    # Test basic secret addition
    if secret add TEST_SECRET test_value_123 "Test secret description" >/dev/null 2>&1
        echo "✓ Basic secret addition works" >&2
    else
        echo "✗ Failed to add basic secret" >&2
        set errors (math $errors + 1)
    end

    # Test secret addition without description (should fail)
    if secret add NEW_SECRET value_without_desc 2>/dev/null
        echo "✗ Secret addition without description should fail" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Secret addition properly requires description for new secrets" >&2
    end

    # Test updating existing secret (description should be preserved)
    if secret add TEST_SECRET updated_value_456 >/dev/null 2>&1
        echo "✓ Secret update works" >&2
    else
        echo "✗ Failed to update existing secret" >&2
        set errors (math $errors + 1)
    end

    return $errors
end

function test_secret_get
    echo "📋 Testing secret get functionality..." >&2
    set -l errors 0

    # First add a test secret
    secret add GET_TEST get_test_value "Secret for get testing" >/dev/null 2>&1

    # Test basic get
    set -l value (secret get GET_TEST 2>/dev/null)
    if test "$value" = get_test_value
        echo "✓ Basic secret retrieval works" >&2
    else
        echo "✗ Failed to retrieve secret value (got: '$value')" >&2
        set errors (math $errors + 1)
    end

    # Test get with name
    set -l named_output (secret get GET_TEST --with-name 2>/dev/null)
    if string match -q "*GET_TEST:*get_test_value*" $named_output
        echo "✓ Secret retrieval with name works" >&2
    else
        echo "✗ Failed to retrieve secret with name format" >&2
        set errors (math $errors + 1)
    end

    # Test get with description
    set -l desc_output (secret get GET_TEST --with-description 2>/dev/null)
    if string match -q "*GET_TEST*Secret for get testing*get_test_value*" $desc_output
        echo "✓ Secret retrieval with description works" >&2
    else
        echo "✗ Failed to retrieve secret with description format" >&2
        set errors (math $errors + 1)
    end

    # Test JSON output (if jq is available)
    if command -v jq >/dev/null 2>&1
        set -l json_output (secret get GET_TEST --json 2>/dev/null)
        if echo $json_output | jq -e '.value == "get_test_value"' >/dev/null 2>&1
            echo "✓ Secret retrieval in JSON format works" >&2
        else
            echo "✗ Failed to retrieve secret in JSON format" >&2
            set errors (math $errors + 1)
        end
    else
        echo "ℹ Skipping JSON test (jq not available)" >&2
    end

    # Test non-existent secret
    if secret get NON_EXISTENT 2>/dev/null
        echo "✗ Getting non-existent secret should fail" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Getting non-existent secret properly fails" >&2
    end

    return $errors
end

function test_secret_list
    echo "📋 Testing secret list functionality..." >&2
    set -l errors 0

    # Add multiple test secrets
    secret add LIST_TEST_1 value1 "First test secret" >/dev/null 2>&1
    secret add LIST_TEST_2 value2 "Second test secret" >/dev/null 2>&1

    # Test basic list
    set -l list_output (secret list 2>/dev/null | string join "\n")
    if string match -q "*LIST_TEST_1*First test secret*" -- "$list_output"
        echo "✓ Basic secret listing works" >&2
    else
        echo "✗ Failed to list secrets properly" >&2
        set errors (math $errors + 1)
    end

    # Test list with masked values
    set -l masked_output (secret list --with-masked-values 2>/dev/null | string join "\n")
    if string match -q "*LIST_TEST_1*\*\*\*\**" -- "$masked_output"
        echo "✓ Secret listing with masked values works" >&2
    else
        echo "✗ Failed to list secrets with masked values" >&2
        set errors (math $errors + 1)
    end

    return $errors
end

function test_secret_delete
    echo "📋 Testing secret delete functionality..." >&2
    set -l errors 0

    # Add a test secret
    secret add DELETE_TEST delete_value "Secret to be deleted" >/dev/null 2>&1

    # Verify it exists
    if secret get DELETE_TEST >/dev/null 2>&1
        echo "✓ Test secret created for deletion" >&2
    else
        echo "✗ Failed to create test secret for deletion" >&2
        return 1
    end

    # Delete the secret
    if secret delete DELETE_TEST >/dev/null 2>&1
        echo "✓ Secret deletion works" >&2
    else
        echo "✗ Failed to delete secret" >&2
        set errors (math $errors + 1)
    end

    # Verify it's gone
    if secret get DELETE_TEST 2>/dev/null
        echo "✗ Secret still exists after deletion" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Secret properly removed after deletion" >&2
    end

    # Test deleting non-existent secret
    if secret delete NON_EXISTENT 2>/dev/null
        echo "✗ Deleting non-existent secret should fail" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Deleting non-existent secret properly fails" >&2
    end

    return $errors
end

function test_secret_export
    echo "📋 Testing secret export functionality..." >&2
    set -l errors 0

    # Set a test environment variable
    set -gx EXPORT_TEST_VAR export_test_value

    # Export it as a secret
    if secret export EXPORT_TEST_VAR "Exported environment variable" >/dev/null 2>&1
        echo "✓ Environment variable export works" >&2
    else
        echo "✗ Failed to export environment variable" >&2
        set errors (math $errors + 1)
    end

    # Verify the secret was created
    set -l exported_value (secret get EXPORT_TEST_VAR 2>/dev/null)
    if test "$exported_value" = export_test_value
        echo "✓ Exported secret has correct value" >&2
    else
        echo "✗ Exported secret has incorrect value" >&2
        set errors (math $errors + 1)
    end

    return $errors
end

function test_secret_load
    echo "📋 Testing secret load functionality..." >&2
    set -l errors 0

    # Add test secrets
    secret add LOAD_TEST_1 load_value_1 "First load test" >/dev/null 2>&1
    secret add LOAD_TEST_2 load_value_2 "Second load test" >/dev/null 2>&1

    # Clear environment variables first
    set -e LOAD_TEST_1 LOAD_TEST_2

    # Load secrets
    if secret load >/dev/null 2>&1
        echo "✓ Secret loading works" >&2
    else
        echo "✗ Failed to load secrets" >&2
        set errors (math $errors + 1)
    end

    # Verify environment variables are set
    if test "$LOAD_TEST_1" = load_value_1
        echo "✓ First loaded secret is correct" >&2
    else
        echo "✗ First loaded secret is incorrect (got: '$LOAD_TEST_1')" >&2
        set errors (math $errors + 1)
    end

    if test "$LOAD_TEST_2" = load_value_2
        echo "✓ Second loaded secret is correct" >&2
    else
        echo "✗ Second loaded secret is incorrect (got: '$LOAD_TEST_2')" >&2
        set errors (math $errors + 1)
    end

    return $errors
end

function test_secret_help_and_version
    echo "📋 Testing help and version commands..." >&2
    set -l errors 0

    # Test version command
    set -l version_output (secret version 2>&1)
    if string match -q "*fish-secretstore*v*" $version_output
        echo "✓ Version command works" >&2
    else
        echo "✗ Version command failed" >&2
        set errors (math $errors + 1)
    end

    # Test help command
    set -l help_output (secret help 2>&1 | string join " ")
    if string match -q "*USAGE:*COMMANDS:*" -- "$help_output"
        echo "✓ Help command works" >&2
    else
        echo "✗ Help command failed" >&2
        set errors (math $errors + 1)
    end

    # Test no arguments (should show help)
    set -l no_args_output (secret 2>&1 | string join " ")
    if string match -q "*USAGE:*COMMANDS:*" -- "$no_args_output"
        echo "✓ No arguments shows help" >&2
    else
        echo "✗ No arguments should show help" >&2
        set errors (math $errors + 1)
    end

    return $errors
end

function test_error_handling
    echo "📋 Testing error handling..." >&2
    set -l errors 0

    # Test invalid command
    if secret invalid_command >/dev/null 2>&1
        echo "✗ Invalid command should fail" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Invalid command properly fails" >&2
    end

    # Test add without arguments
    if secret add >/dev/null 2>&1
        echo "✗ Add without arguments should fail" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Add without arguments properly fails" >&2
    end

    # Test get without arguments
    if secret get >/dev/null 2>&1
        echo "✗ Get without arguments should fail" >&2
        set errors (math $errors + 1)
    else
        echo "✓ Get without arguments properly fails" >&2
    end

    return $errors
end

function run_all_tests
    echo "🔒 Starting fish-secretstore functional tests" >&2
    echo "==========================================" >&2
    echo >&2

    set -g total_errors 0

    # Set up environment
    setup_test_environment

    # Set up GPG for testing
    if test_gpg_setup
        echo >&2

        # Run all functionality tests
        test_secret_add
        set total_errors (math $total_errors + $status)

        test_secret_get
        set total_errors (math $total_errors + $status)

        test_secret_list
        set total_errors (math $total_errors + $status)

        test_secret_delete
        set total_errors (math $total_errors + $status)

        test_secret_export
        set total_errors (math $total_errors + $status)

        test_secret_load
        set total_errors (math $total_errors + $status)

        test_secret_help_and_version
        set total_errors (math $total_errors + $status)

        test_error_handling
        set total_errors (math $total_errors + $status)
    else
        echo "⚠️  Skipping functionality tests due to GPG setup failure" >&2
        set total_errors 1
    end

    # Clean up
    cleanup_test_environment

    # Summary
    echo "==========================================" >&2
    if test $total_errors -eq 0
        echo "🎉 All functional tests passed!" >&2
        echo "✅ fish-secretstore is working correctly" >&2
        return 0
    else
        echo "❌ $total_errors error(s) found in functional tests" >&2
        echo "🔧 fish-secretstore needs fixes" >&2
        return 1
    end
end

# Run the tests if script is executed directly
if test (basename (status --current-filename)) = "test_functionality.fish"
    run_all_tests
end
