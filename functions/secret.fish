# A comprehensive secret management tool for fish shell
function secret
    # Set XDG_CONFIG_HOME if not already set
    if not set -q XDG_CONFIG_HOME
        set -gx XDG_CONFIG_HOME $HOME/.config
    end

    # Check if a subcommand is provided
    if test (count $argv) -lt 1
        _secret_help
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
        case config
            # Call the config function
            _secret_config $subcommand_args
        case version
            echo "fish-secretstore v1.0.1"
        case help --help -h
            _secret_help
        case '*'
            echo "Unknown subcommand: $subcommand"
            _secret_help
            return 1
    end
end
