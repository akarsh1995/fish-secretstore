# fish-secretstore - A secure secret management tool for Fish shell
# Repository: https://github.com/akarsh1995/fish-secretstore

# Only load in interactive sessions or CI environments (speeds up shell startup)
if not status is-interactive && test "$CI" != true
    exit
end

# Set default XDG_CONFIG_HOME if not set
if not set -q XDG_CONFIG_HOME
    set -gx XDG_CONFIG_HOME $HOME/.config
end

# Helper function to initialize secrets directory
function __secretstore_init_dir
    set -l secure_dir $XDG_CONFIG_HOME/fish/secure/secrets
    if not test -d $secure_dir
        mkdir -p $secure_dir
        # Set restrictive permissions on the secure directory
        chmod 700 $secure_dir
    end
end

# Fisher event handlers
function _secretstore_install --on-event secretstore_install
    set_color green
    echo "Installing fish-secretstore..."
    set_color normal

    # Initialize the secrets directory
    __secretstore_init_dir

    # Verify required dependencies
    set -l missing_deps

    if not command -sq gpg
        set missing_deps $missing_deps "gpg"
    end

    if not command -sq jq
        set missing_deps $missing_deps "jq"
    end

    if test (count $missing_deps) -gt 0
        set_color yellow
        echo "Warning: The following dependencies are missing: "(string join ", " $missing_deps)
        echo "Install them for full functionality:"
        for dep in $missing_deps
            switch $dep
                case gpg
                    echo "  - GPG: brew install gnupg (macOS) or apt-get install gnupg (Linux)"
                case jq
                    echo "  - jq: brew install jq (macOS) or apt-get install jq (Linux)"
            end
        end
        set_color normal
    end

    echo "Secrets directory initialized at: $XDG_CONFIG_HOME/fish/secure/secrets"
    echo ""
    echo "Commands are available through the 'secret' function:"
    echo "  secret add NAME VALUE DESCRIPTION  - Add a new secret"
    echo "  secret get NAME                    - Retrieve a secret"
    echo "  secret list                        - List all secrets"
    echo "  secret load                        - Load secrets as environment variables"
    echo ""
    echo "Run 'secret --help' to see all available commands"
end

function _secretstore_update --on-event secretstore_update
    set_color yellow
    echo "Updating fish-secretstore..."
    set_color normal

    # Run initialization again to ensure secrets directory exists
    __secretstore_init_dir

    echo "fish-secretstore updated successfully"
end

function _secretstore_uninstall --on-event secretstore_uninstall
    set_color red
    echo "Uninstalling fish-secretstore..."
    set_color normal

    # Clean up functions (but preserve user data)
    functions --erase (functions --all | string match --entire -r '^_?secret')
    functions --erase __secretstore_init_dir
    functions --erase __fish_complete_secrets

    echo "fish-secretstore plugin uninstalled."
    echo "Note: Your encrypted secrets remain in $XDG_CONFIG_HOME/fish/secure/secrets"
end

# Load secrets from the encrypted JSON file at startup
if type -q secret
    secret load >/dev/null 2>&1
end
