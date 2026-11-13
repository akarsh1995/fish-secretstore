# Function to complete secrets for autocompletion
function __fish_complete_secrets
    # Decrypt secrets directly to memory and extract keys (secret names)
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    if test -f $encrypted_json_path
        # Get the list of secret names
        set -l gpg_recipient (_secret_get_gpg_recipient)
        set -l decrypted_content (gpg --quiet --decrypt --local-user $gpg_recipient $encrypted_json_path 2>/dev/null)
        if test $status -eq 0
            # Extract and output the keys
            echo $decrypted_content | jq -r 'keys[]'
        end
    end
end
