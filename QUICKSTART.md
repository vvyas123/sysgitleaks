# Gitleaks Quick Start

> Prevent committing blockchain private keys to git repositories

## Installation (2 Commands)

### Step 1: Install Globally
```bash
chmod +x install-gitleaks-global.sh
./install-gitleaks-global.sh
```

### Step 2: Update Existing Repos
```bash
chmod +x update-all-repos.sh
./update-all-repos.sh ~
```

Done! All repos now protected ✓

---

## Test Installation

```bash
mkdir /tmp/test-gitleaks && cd /tmp/test-gitleaks
git init
echo 'const key = "abc"' > test.js
git add test.js
git commit -m "test"
# Note: Add a blockchain private key to test blocking
```

Expected: `✗ Secrets detected! Commit blocked.` ✓

---

## What Gets Blocked

- Ethereum/EVM private keys
- Bitcoin private keys  
- Solana private keys
- BIP39 seed phrases
- Tezos, Cardano, Ripple, Stellar, NEAR keys

---

## How It Works

**New repos**: Hooks auto-install on `git init` or `git clone`

**Existing repos**: Run `./update-all-repos.sh` to add hooks

**On commit**: Scans staged files → blocks if secrets found

---

## Uninstall

```bash
chmod +x uninstall-gitleaks-global.sh
./uninstall-gitleaks-global.sh
```

---
