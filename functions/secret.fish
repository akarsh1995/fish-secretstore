# A comprehensive secret management tool for fish shell
function secret
    # Check if a subcommand is provided
    if test (count $argv) -lt 1
        echo "Usage: secret [add|delete|edit|export|get|list|load] [arguments...]"
        return 1
    end

    set -l subcommand $argv[1]
    set -l subcommand_args $argv[2..-1]

    switch $subcommand
        case add
            # Call the add function
            _secret_add $subcommand_args
        case delete
            # Call the delete function
            _secret_delete $subcommand_args
        case edit
            # Call the edit function
            _secret_edit $subcommand_args
        case export
            # Call the export function
            _secret_export $subcommand_args
        case get
            # Call the get function
            _secret_get $subcommand_args
        case list
            # Call the list function
            _secret_list $subcommand_args
        case load
            # Call the load function
            _secret_load $subcommand_args
        case '*'
            echo "Unknown subcommand: $subcommand"
            echo "Available subcommands: add, delete, edit, export, get, list, load"
            return 1
    end
end

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
        set json_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
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
    echo $json_content | jq --arg key "$argv[1]" --arg value "$argv[2]" --arg desc "$description" \
        '.[$key] = {"value": $value, "description": $desc}' | gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $encrypted_json_path

    if test $status -ne 0
        echo "Failed to encrypt secrets file"
        return 1
    end

    # Check if the secret was added/updated successfully
    set -l new_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if not echo $new_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        echo "Failed to add/update secret"
        return 1
    end

    # Set the variable in the current environment
    set -gx $argv[1] $argv[2]

    echo "Secret added/updated successfully"
end

# Function to delete a secret
function _secret_delete
    # Define paths for secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide the secret name to delete"
        return 1
    end

    # Check if the encrypted file exists
    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found."
        return 1
    end

    # Decrypt the secrets file directly to memory (using command substitution)
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end

    # Check if the secret exists
    if not echo $decrypted_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        echo "Secret '$argv[1]' does not exist"
        return 1
    end

    # Delete the secret and encrypt directly from memory to file
    echo $decrypted_content | jq --arg key "$argv[1]" 'del(.[$key])' | gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $encrypted_json_path

    if test $status -ne 0
        echo "Failed to encrypt secrets file"
        return 1
    end

    # Remove the variable from the environment
    set -e $argv[1]

    echo "Secret '$argv[1]' deleted successfully"
end

# Function to edit a secret using a text editor
function _secret_edit
    # Define paths for secrets
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    # check if the first argument is empty
    if test -z "$argv[1]"
        echo "Please provide the secret name to edit"
        return 1
    end

    # Check if the encrypted file exists
    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found."
        return 1
    end

    # Decrypt the secrets file directly to memory
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if test $status -ne 0
        echo "Failed to decrypt secrets file"
        return 1
    end

    # Check if the secret exists
    if not echo $decrypted_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        echo "Secret '$argv[1]' does not exist"
        return 1
    end

    # Get the current value and description
    set -l current_value (echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].value')
    set -l current_description (echo $decrypted_content | jq -r --arg key "$argv[1]" '.[$key].description')

    # Create a temporary file with the secret content
    set -l temp_file (mktemp)

    # Add a comment at the top explaining the file and instructions
    echo "# Editing secret: $argv[1]" >$temp_file
    echo "# Description: $current_description" >>$temp_file
    echo "# " >>$temp_file
    echo "# Lines starting with # will be ignored." >>$temp_file
    echo "# Save and exit the editor to update the secret." >>$temp_file
    echo "# To cancel, delete all content and save an empty file." >>$temp_file
    echo "# " >>$temp_file
    echo "$current_value" >>$temp_file

    # Open the file in the default editor
    set -l editor $EDITOR
    if test -z "$editor"
        set editor vim
    end

    $editor $temp_file

    # Check if editing was successful
    if test $status -ne 0
        rm $temp_file
        echo "Editor exited with an error"
        return 1
    end

    # Read the edited content, filtering out comment lines
    set -l new_content (grep -v "^#" $temp_file | string collect)

    # Clean up the temporary file
    rm $temp_file

    # Check if the file is empty (which means cancel the operation)
    if test -z "$new_content"
        echo "Edit cancelled"
        return 0
    end

    # Update the JSON with the new secret and encrypt directly from memory to file
    echo $decrypted_content | jq --arg key "$argv[1]" --arg value "$new_content" --arg desc "$current_description" \
        '.[$key] = {"value": $value, "description": $desc}' | gpg --quiet --yes --recipient "Akarsh Jain" --encrypt --output $encrypted_json_path

    if test $status -ne 0
        echo "Failed to encrypt secrets file"
        return 1
    end

    # Check if the secret was updated successfully
    set -l verification_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
    if not echo $verification_content | jq -e --arg key "$argv[1]" 'has($key)' >/dev/null
        echo "Failed to update secret"
        return 1
    end

    # Set the variable in the current environment
    set -gx $argv[1] $new_content

    echo "Secret '$argv[1]' updated successfully"
end

# Function to export an existing environment variable as a secret
function _secret_export
    # Check if arguments are provided
    if test (count $argv) -lt 2
        echo "Usage: secret export ENV_VAR_NAME description"
        return 1
    end

    # Get the environment variable name
    set -l env_var_name $argv[1]

    # Check if the environment variable exists
    if not set -q $env_var_name
        echo "Environment variable $env_var_name does not exist"
        return 1
    end

    # Get the description
    set -l description $argv[2]

    # Get the value of the environment variable
    set -l env_var_value $$env_var_name

    # Add as secret
    _secret_add $env_var_name $env_var_value $description

    echo "Environment variable $env_var_name exported as a secret"
end

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
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
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
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
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

# Function to load all secrets from the encrypted JSON file
function _secret_load
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    if test ! -f $encrypted_json_path
        echo "No encrypted secrets file found. Use secret add to create one."
        return 1
    end

    # Decrypt the secrets file directly to memory (using command substitution)
    set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
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

# Function to complete secrets for autocompletion
function __fish_complete_secrets
    # Decrypt secrets directly to memory and extract keys (secret names)
    set -l encrypted_json_path $XDG_CONFIG_HOME/fish/secure/secrets/secrets.json.gpg

    if test -f $encrypted_json_path
        # Get the list of secret names
        set -l decrypted_content (gpg --quiet --decrypt $encrypted_json_path 2>/dev/null)
        if test $status -eq 0
            # Extract and output the keys
            echo $decrypted_content | jq -r 'keys[]'
        end
    end
end
