# fish-secretstore 🔐

[![GitHub](https://img.shields.io/github/license/akarsh1995/fish-secretstore)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/akarsh1995/fish-secretstore)](https://github.com/akarsh1995/fish-secretstore/releases)

> A comprehensive secret management tool for [Fish shell](https://fishshell.com/), distributed as a [Fisher](https://github.com/jorgebucaran/fisher) plugin.

## Features

- **🔐 GPG encryption**: Secrets are encrypted using GPG with your configured recipient
- **🗃️ JSON-based storage**: Organized secret storage with descriptions
- **🔄 Environment variable integration**: Export and load secrets as environment variables  
- **✏️ Interactive editing**: Edit secrets using your preferred text editor
- **📋 Comprehensive listing**: View secrets with optional masked values
- **🚀 Auto-loading**: Automatically load secrets at shell startup
- **🔍 Smart completions**: Tab completion for all commands and secret names

## Installation

Install using [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install akarsh1995/fish-secretstore
```

## Prerequisites

- **GPG (GNU Privacy Guard)**: For encryption/decryption
- **jq**: For JSON processing
- **Fish shell**: 3.0 or later

## Quick Start

### 1. Add your first secret
```fish
secret add API_KEY "your-secret-api-key" "My application API key"
```

### 2. Retrieve a secret
```fish
secret get API_KEY
# Output: your-secret-api-key
```

### 3. List all secrets
```fish
secret list
# Available Secrets:
# --------------------------------------------------------------------------------
# API_KEY - My application API key
```

### 4. Load all secrets as environment variables
```fish
secret load
# Secrets loaded successfully
echo $API_KEY
# Output: your-secret-api-key
```

## Usage

### Managing Secrets

#### Add or update a secret
```fish
secret add SECRET_NAME "secret_value" "Optional description"
```

#### Get a secret value
```fish
secret get SECRET_NAME                    # Just the value
secret get SECRET_NAME --with-name        # Name: value
secret get SECRET_NAME --with-description # Name (description): value
secret get SECRET_NAME --json             # JSON format
```

#### Edit a secret interactively
```fish
secret edit SECRET_NAME
```

#### Delete a secret
```fish
secret delete SECRET_NAME
```

#### List all secrets
```fish
secret list                        # Names and descriptions only
secret list --with-masked-values   # Include masked values
```

#### Load all secrets as environment variables
```fish
secret load
```

#### Export environment variable as secret
```fish
secret export EXISTING_VAR "Description for this secret"
```

#### Configure GPG recipient
```fish
secret config set-recipient "your.email@example.com"  # Set GPG recipient
secret config                                          # View current settings
```

## Configuration

The plugin automatically sets up the necessary directory structure at:
- `$XDG_CONFIG_HOME/fish/secure/secrets/` (usually `~/.config/fish/secure/secrets/`)

Secrets are stored in an encrypted file: `secrets.json.gpg`

### GPG Setup

Configure your GPG recipient for encryption:

```fish
# Set the GPG recipient (required for first use)
secret config set-recipient "your.email@example.com"

# View current configuration
secret config
```

If no recipient is configured, the plugin will attempt to use your default GPG key. For more reliable operation, it's recommended to explicitly set a recipient.

You can also use a specific GPG key ID:
```fish
secret config set-recipient "0xA1B2C3D4E5F6G7H8"
```

## Security Features

- **🔐 GPG encryption**: All secrets are encrypted at rest
- **🔒 Secure storage**: Secrets directory has restrictive permissions (700)
- **💾 In-memory processing**: Secrets are decrypted directly to memory when possible
- **🚫 No plaintext files**: Never stores secrets in plaintext
- **🛡️ Environment isolation**: Secrets loaded as environment variables are session-specific

## Tab Completion

The plugin provides comprehensive tab completion for:

- All subcommands with descriptions
- Secret names for get, edit, delete operations
- Environment variable names for export operation
- Command-line options and flags

## Plugin Topics

This plugin is tagged with the following GitHub topics for better discoverability:
- `fish-plugin`
- `secrets-management`
- `encryption`
- `security`
- `gpg`
- `environment-variables`

## Troubleshooting

### GPG Issues
- Ensure GPG is properly configured with a valid key pair
- Check that your GPG key is trusted and not expired
- Test GPG functionality: `echo "test" | gpg --encrypt --recipient "your@email.com" | gpg --decrypt`

### JSON Processing Issues
- Ensure `jq` is installed: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- Verify jq functionality: `echo '{"test": "value"}' | jq .`

### Permission Issues
- Check that `$XDG_CONFIG_HOME/fish/secure/secrets/` has proper permissions (700)
- Ensure the secrets file is readable by your user account

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b my-new-feature`
3. Make your changes and add tests
4. Commit your changes: `git commit -am 'Add some feature'`
5. Push to the branch: `git push origin my-new-feature`
6. Submit a pull request

## License

[MIT](LICENSE) © [Akarsh Jain](https://github.com/akarsh1995)

## Related

- [fish-pwstore](https://github.com/akarsh1995/fish-pwstore) - Password manager plugin
- [fish-filecrypt](https://github.com/akarsh1995/fish-filecrypt) - File encryption plugin
- [Fisher](https://github.com/jorgebucaran/fisher) - Fish plugin manager
