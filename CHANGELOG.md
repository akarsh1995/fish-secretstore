# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-05-25

### Added
- Initial release of fish-secretstore
- Core secret management functionality:
  - `secret add` - Add or update secrets with descriptions
  - `secret get` - Retrieve secret values with multiple output formats
  - `secret list` - List all secrets with optional masked values
  - `secret delete` - Remove secrets
  - `secret edit` - Interactive editing of secrets
  - `secret export` - Export environment variables as secrets
  - `secret load` - Load all secrets as environment variables
  - `secret version` - Show version information
  - `secret help` - Display help information
- GPG-based encryption for secure storage
- JSON-based secret organization with descriptions
- Comprehensive tab completion system
- Fisher plugin compliance with proper event handlers
- Automatic secrets loading at shell startup
- Secure directory permissions (700)
- In-memory secret processing for enhanced security

### Security
- All secrets encrypted using GPG
- No plaintext storage of sensitive data
- Restrictive file and directory permissions
- Secure memory handling during decryption

### Documentation
- Complete README with installation and usage instructions
- Comprehensive help system
- Code comments and examples
- Fisher plugin best practices compliance
