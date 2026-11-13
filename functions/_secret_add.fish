# Function that adds a secret to the secrets file
function _secret_add
    # Define paths for secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide a secret name"
        return 1
    end

    # check if the second argument is empty
    if test -z "$argv[2]"
        echo "Please provide a secret value"
        return 1
    end

    # Prepare current JSON content
    set -l json_content "{}"

    # If we have an encrypted file, decrypt it to memory
    if test -f $encrypted_json_path
        set -l gpg_recipient (_secret_get_gpg_recipient)
        set json_content (gpg --quiet --decrypt --local-user $gpg_recipient $encrypted_json_path 2>/dev/null)
        if test $status -ne 0
            echo "Failed to decrypt secrets file"
            return 1
        end
    end

    # Check if a description is provided for new secrets
    if not echo $json_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        if test (count $argv) -lt 3 -o -z "$argv[3]"
            echo "Please provide a description when adding a new secret"
            return 1
        end
    end

    # Read the description, either new or existing
    set -l description ""
    if test (count $argv) -ge 3
        set description $argv[3]
    else
        # Try to get the existing description
        set -l existing (echo $json_content | jq -r --arg key "$argv[1]" '.[$key].description // empty')
        if test -n "$existing"
            set description $existing
        end
    end

    # Update the JSON with the new secret and encrypt directly from memory to file
    set -l gpg_recipient (_secret_get_gpg_recipient)
    if test $status -ne 0
        return 1
    end

    echo $json_content | jq --arg key "$argv[1]" --arg value "$argv[2]" --arg desc "$description" \
        '.[$key] = {"value": $value, "description": $desc}' | gpg --quiet --yes --recipient "$gpg_recipient" --encrypt --output $encrypted_json_path

    if test $status -ne 0
        echo "Failed to encrypt secrets file"
        return 1
    end

    # Check if the secret was added/updated successfully
    set -l gpg_recipient (_secret_get_gpg_recipient)
    set -l new_content (gpg --quiet --decrypt --local-user $gpg_recipient $encrypted_json_path 2>/dev/null)
    if not echo $new_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        echo "Failed to add/update secret"
        return 1
    end

    # Set the variable in the current environment
    set -gx $argv[1] $argv[2]

    echo "Secret added/updated successfully"
end
