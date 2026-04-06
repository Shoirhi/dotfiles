# Sandbox Package Installation Rules

## CRITICAL: Package Install Failure Handling

When a package installation command fails (npm install, pip install, yarn add, pnpm install, pip3 install, brew install, cargo install, gem install, composer install, etc.), you MUST follow this protocol:

### Step 1: STOP immediately
- Do NOT continue to the next step
- Do NOT attempt workarounds or alternative implementations
- Do NOT retry the command with dangerouslyDisableSandbox
- Do NOT skip the dependency and proceed without it

### Step 2: Inform the user
Clearly explain:
- What command failed and why (sandbox restriction)
- The exact command the user needs to run manually
- Format: suggest using `! <command>` prefix so output lands in the conversation

Example response:
```
サンドボックス制限により `npm install <package>` が失敗しました。
以下のコマンドを手動で実行してください:

! npm install <package>

完了したら教えてください。続きを進めます。
```

### Step 3: Wait for confirmation
- Ask the user to confirm when the installation is complete
- Do NOT proceed until the user explicitly confirms
- Once confirmed, verify the installation succeeded before continuing

## Proactive Detection

Before running any install command, check if it is likely to fail due to sandbox restrictions. If so, skip the attempt entirely and go directly to Step 2 (inform the user).

Common sandbox-restricted operations:
- Writing to node_modules, site-packages, or other package directories outside the allowed write paths
- Network access to package registries (npmjs.org, pypi.org, etc.) if not in allowed hosts
- Global installations requiring write access to system directories

## Multiple Dependencies

If multiple packages need to be installed, consolidate them into a single command for the user:
```
! npm install package-a package-b package-c
```

Do NOT ask the user to run multiple separate install commands when they can be combined.
