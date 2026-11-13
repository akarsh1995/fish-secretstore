# Function to retrieve a specific secret value
function _secret_get
    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide the secret name to retrieve"
        return 1
    end

    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found."
        return 1
    end

    # Decrypt the secrets file directly to memory
    set -l gpg_recipient (_secret_get_gpg_recipient)
    set -l decrypted_content (gpg --quiet --decrypt --local-user $gpg_recipient $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end

    # Check if the secret exists
    if not echo $decrypted_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        echo "Secret '$argv[1]' does not exist"
        return 1
    end

    # Output just the secret value (optionally with flags)
    set -l output_mode value # Default to outputting just the value

    if test (count $argv) -gt 1
        switch $argv[2]
            case --with-description
                set output_mode with_description
            case --with-name
                set output_mode with_name
            case --json
                set output_mode json
        end
    end

    switch $output_mode
        case value
            echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].value'
        case with_name
            echo "$argv[1]: "(echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].value')
        case with_description
            echo "$argv[1] ("(echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].description')"): "(echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].value')
        case json
            echo $decrypted_content | jq --arg key "$argv[1]" '.[$key]'
    end
end
