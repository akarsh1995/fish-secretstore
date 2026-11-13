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
