# Completions for the secret command

# Define subcommands with descriptions
set -l subcommands "add delete edit export get list load"

# Complete subcommands
complete -c secret -f -n __fish_use_subcommand -a add -d "Add or update a secret"
complete -c secret -f -n __fish_use_subcommand -a delete -d "Delete a secret"
complete -c secret -f -n __fish_use_subcommand -a edit -d "Edit a secret value in a text editor"
complete -c secret -f -n __fish_use_subcommand -a export -d "Export an environment variable as a secret"
complete -c secret -f -n __fish_use_subcommand -a get -d "Retrieve a secret value"
complete -c secret -f -n __fish_use_subcommand -a list -d "List all available secrets"
complete -c secret -f -n __fish_use_subcommand -a load -d "Load all secrets into environment variables"

# Function to list all available environment variables for export
function __fish_complete_env_vars
    set -ng | sed 's/=.*//' | sort
end

# Function to complete secrets - defined in the main script
# Reusing the function from secret.fish

# Completions for specific subcommands
# For 'add' subcommand - complete with existing secrets for updating
complete -c secret -f -n "__fish_seen_subcommand_from add" -a "(__fish_complete_secrets)" -d "Update existing secret"

# For 'delete' subcommand - complete with existing secrets
complete -c secret -f -n "__fish_seen_subcommand_from delete" -a "(__fish_complete_secrets)" -d "Delete this secret"

# For 'edit' subcommand - complete with existing secrets
complete -c secret -f -n "__fish_seen_subcommand_from edit" -a "(__fish_complete_secrets)" -d "Edit this secret"

# For 'export' subcommand - complete with environment variables
complete -c secret -f -n "__fish_seen_subcommand_from export" -a "(__fish_complete_env_vars)" -d "Environment variable to export"

# For 'get' subcommand - complete with existing secrets and options
complete -c secret -f -n "__fish_seen_subcommand_from get" -a "(__fish_complete_secrets)" -d "Get this secret"
complete -c secret -f -n "__fish_seen_subcommand_from get; and __fish_seen_subcommand_from (__fish_complete_secrets)" -l with-description -d "Show secret with description"
complete -c secret -f -n "__fish_seen_subcommand_from get; and __fish_seen_subcommand_from (__fish_complete_secrets)" -l with-name -d "Show secret with name"
complete -c secret -f -n "__fish_seen_subcommand_from get; and __fish_seen_subcommand_from (__fish_complete_secrets)" -l json -d "Output secret as JSON"

# For 'list' subcommand - complete with options
complete -c secret -f -n "__fish_seen_subcommand_from list" -l with-masked-values -d "Show masked values for secrets"

# For 'load' subcommand - no additional completions needed
