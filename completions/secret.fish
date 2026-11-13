# Completions for the secret command

# Define subcommands with descriptions
set -l subcommands "add delete edit export get list load config version help"

# Complete subcommands
complete -c secret -f -n __fish_use_subcommand -a add -d "Add or update a secret"
complete -c secret -f -n __fish_use_subcommand -a delete -d "Delete a secret"
complete -c secret -f -n __fish_use_subcommand -a edit -d "Edit a secret value in a text editor"
complete -c secret -f -n __fish_use_subcommand -a export -d "Export an environment variable as a secret"
complete -c secret -f -n __fish_use_subcommand -a get -d "Retrieve a secret value"
complete -c secret -f -n __fish_use_subcommand -a list -d "List all available secrets"
complete -c secret -f -n __fish_use_subcommand -a load -d "Load all secrets into environment variables"
complete -c secret -f -n __fish_use_subcommand -a config -d "Configure GPG recipient and settings"
complete -c secret -f -n __fish_use_subcommand -a version -d "Show version information"
complete -c secret -f -n __fish_use_subcommand -a help -d "Show help message"

# Global options
complete -c secret -f -l help -d "Show help message"
complete -c secret -f -s h -d "Show help message"

# Function to list all available environment variables for export
function __fish_complete_env_vars
    set -ng | sed 's/=.*//' | sort
end

# Completions for specific subcommands
# For 'add' subcommand - complete with existing secrets for updating
complete -c secret -f -n "__fish_seen_subcommand_from add" -a "(_secret_complete)" -d "Update existing secret"

# For 'delete' subcommand - complete with existing secrets
complete -c secret -f -n "__fish_seen_subcommand_from delete" -a "(_secret_complete)" -d "Delete this secret"

# For 'edit' subcommand - complete with existing secrets
complete -c secret -f -n "__fish_seen_subcommand_from edit" -a "(_secret_complete)" -d "Edit this secret"

# For 'export' subcommand - complete with environment variables
complete -c secret -f -n "__fish_seen_subcommand_from export" -a "(__fish_complete_env_vars)" -d "Environment variable to export"

# For 'get' subcommand - complete with existing secrets and options
complete -c secret -f -n "__fish_seen_subcommand_from get" -a "(_secret_complete)" -d "Get this secret"
complete -c secret -f -n "__fish_seen_subcommand_from get; and __fish_seen_subcommand_from (_secret_complete)" -l with-description -d "Show secret with description"
complete -c secret -f -n "__fish_seen_subcommand_from get; and __fish_seen_subcommand_from (_secret_complete)" -l with-name -d "Show secret with name"
complete -c secret -f -n "__fish_seen_subcommand_from get; and __fish_seen_subcommand_from (_secret_complete)" -l json -d "Output secret as JSON"

# For 'list' subcommand - complete with options
complete -c secret -f -n "__fish_seen_subcommand_from list" -l with-masked-values -d "Show masked values for secrets"

# For 'config' subcommand - complete with config options
complete -c secret -f -n "__fish_seen_subcommand_from config" -a set-recipient -d "Set GPG recipient for encryption"

# For 'load' subcommand - no additional completions needed
