# Contribution Guidelines

To contribute to this repository, please follow these guidelines:

## Git Configuration

You must configure your local Git environment with a GPG key and use conventional commits.

### 1. Install GPG

First, ensure you have GPG installed:

```shell
# Mac OS
brew install gnupg

# Linux (Debian/Ubuntu)
sudo apt-get install gnupg

# Windows (via Chocolatey)
choco install gpg4win
```

### 2. Generate GPG Key

If you don't have a GPG key, generate one:

```shell
gpg --full-generate-key
```

Follow the prompts to create your key. Make sure to use your EKG email address.

### 3. Configure Git to Use GPG

Add your GPG key to Git:

```shell
# List your GPG keys
gpg --list-secret-keys --keyid-format LONG

# Copy the key ID (after sec rsa4096/ or rsa3072/)
git config user.signingkey YOUR_KEY_ID
git config commit.gpgsign true
```

### 4. Install Cocogitto (for Conventional Commits)

We use conventional commits for consistent commit messages. Install Cocogitto:

```shell
cargo install cocogitto
```

### 5. Commit Using Conventional Format

When committing changes, use Cocogitto:

```shell
cog commit <type> "<message>" [scope]
```

Cocogitto supports the following commit types: `feat`, `fix`, `style`, `build`, `refactor`, `ci`, `test`, `perf`, `chore`, `revert`, `docs`.

Example:

```shell
cog commit feat "add new feature"
cog commit fix "resolve issue with login" auth
```

For breaking changes, use the `-B` flag:

```shell
cog commit fix -B "remove deprecated API"
```

Cocogitto will ensure your commits follow the conventional commit specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 6. Verify Configuration

Check your Git configuration:

```shell
git config --local --list | grep gpg
```

You should see:

```
user.signingkey=YOUR_KEY_ID
commit.gpgsign=true
```

### 7. Optional: Set Up Repository-Specific User Info

If you want to use different user information for this repository:

```shell
git config user.name "Your Name"
git config user.email "your.email@ekgf.org"
```

## Code Style

Please follow the existing code style and patterns in the repository.

## Pull Requests

1. Create a new branch for your changes
2. Make sure all tests pass
3. Submit a pull request with a clear description of your changes
