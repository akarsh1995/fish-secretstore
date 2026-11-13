# Function to load all secrets from the encrypted JSON file
function _secret_load
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found. Use secret add to create one."
        return 1
    end

    # Decrypt the secrets file directly to memory (using command substitution)
    set -l gpg_recipient (_secret_get_gpg_recipient)
    set -l decrypted_content (gpg --quiet --decrypt --local-user $gpg_recipient $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end

    # Load each secret as an environment variable
    for key in (echo $decrypted_content | jq -r 'keys[]')
        set -l value (echo $decrypted_content | jq -r --arg key "$key" '.[$key].value')
        set -gx $key $value
    end

    echo "Secrets loaded successfully"
end
