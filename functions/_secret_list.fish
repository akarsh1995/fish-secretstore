# Function to list all available secrets with optional masked values
function _secret_list
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg
    set -l show_masked false

    # Parse arguments
    for arg in $argv
        switch $arg
            case --with-masked-values
                set show_masked true
        end
    end

    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found."
        return 1
    end

    # Decrypt the secrets file directly to memory (using command substitution)
    set -l gpg_recipient (_secret_get_gpg_recipient)
    set -l decrypted_content (gpg --quiet --decrypt --local-user $gpg_recipient $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end

    # Create a formatted list of secrets and their descriptions
    echo "Available Secrets:"
    echo --------------------------------------------------------------------------------

    if $show_masked
        # Show secrets with masked values
        for key in (echo $decrypted_content | jq -r 'keys[]' | sort)
            set -l description (echo $decrypted_content | jq -r --arg key "$key" '.[$key].description')
            set -l value (echo $decrypted_content | jq -r --arg key "$key" '.[$key].value')
            set -l value_length (string length $value)
            set -l masked_value (string repeat -n 4 "*")"..."(string repeat -n 2 "*")

            # Show the last 2 characters if value is long enough
            if test $value_length -gt 6
                set masked_value $masked_value(string sub -s (math $value_length - 1) $value)
            end

            echo "$key - $description ($masked_value)"
        end
    else
        # Show only secret names and descriptions (no values)
        echo $decrypted_content | jq -r 'to_entries | .[] | "\(.key) - \(.value.description)"' | sort
    end
end
