# Ruby Dependencies

This project includes Ruby dependencies to support GitHub tooling and integrations.

## Faraday and Retry Middleware

The repository includes a `Gemfile` with the following gems:

- **faraday** (~> 2.0): HTTP client library
- **faraday-retry** (~> 2.0): Retry middleware for Faraday v2.0+

### Why These Dependencies?

Starting with Faraday v2.0, the retry middleware was extracted into a separate gem called `faraday-retry`. This is required when using tools like:

- GitHub Octokit (Ruby SDK for GitHub API)
- Dependabot
- Other GitHub automation tools

Without the `faraday-retry` gem, you may see warnings like:
```
To use retry middleware with Faraday v2.0+, install `faraday-retry` gem
```

### Installation

To install the Ruby dependencies:

```bash
# Install bundler (if not already installed)
gem install bundler

# Install gems
bundle install
```

### Usage

The gems are automatically available when using Ruby-based GitHub tools. No additional configuration is needed.

### Files

- `Gemfile`: Specifies the required Ruby gems
- `Gemfile.lock`: Locks gem versions for reproducible builds
- `.ruby-version`: Specifies the Ruby version (3.1.0)
- `.gitignore`: Updated to exclude `vendor/bundle` directory

## Development

If you need to update the gems:

```bash
bundle update faraday faraday-retry
```

To verify the installation:

```bash
bundle exec ruby -e "require 'faraday'; require 'faraday/retry'; puts 'OK'"
```
