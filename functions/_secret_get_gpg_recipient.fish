# Function to get the configured GPG recipient
function _secret_get_gpg_recipient
    set -l gpg_recipient "$SECRETSTORE_GPG_RECIPIENT"
    if test -z "$gpg_recipient"
        # Try to get default GPG key
        set gpg_recipient (gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2)
        if test -z "$gpg_recipient"
            echo "Error: No GPG recipient configured. Set SECRETSTORE_GPG_RECIPIENT or configure a default GPG key." >&2
            echo "Example: secret config set-recipient 'your.email@example.com'" >&2
            return 1
        end
    end
    echo $gpg_recipient
end
