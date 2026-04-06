---
name: auto-commit
description: Analyzes git changes, generates a Japanese commit message, and commits immediately without asking for confirmation or review. Use this skill whenever the user says "commit", "auto commit", "コミットして", "自動コミット", or wants changes committed without being asked to review the message.
---

# Auto Commit

Analyze staged/unstaged changes, generate a Japanese commit message, and commit immediately. Never ask the user to confirm or review the message.

## Steps

### 1. Gather change information (run in parallel)

- `git status` — list changed files
- `git diff HEAD` — full diff including staged and unstaged changes
- `git log --oneline -5` — recent commit history to match style

### 2. Stage changes if needed

- If there are already staged changes, use them as-is.
- If nothing is staged, run `git add -A` to stage all changes except sensitive files.
  - Never stage `.env`, `*.key`, `*credentials*`, `*secret*`, or similar files.
  - Only warn the user if a potentially sensitive file would be included.

### 3. Generate the commit message in Japanese

Format:
```
<prefix>: <Japanese description>
```

Prefix selection:
| Prefix | When to use |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Refactoring without behavior change |
| `docs` | Documentation only |
| `test` | Adding or fixing tests |
| `style` | Formatting, whitespace, style |
| `chore` | Build config, dependencies, tooling |
| `perf` | Performance improvement |

Message guidelines:
- Focus on **why** the change was made, not just what changed.
- Keep it to 1-2 concise sentences in natural Japanese.
- Capture the intent, not just a file listing.

Examples:
```
feat: ユーザー認証機能にJWTトークンを導入
fix: ログイン時にセッションが正しくリセットされない問題を修正
refactor: データ取得ロジックをサービス層に分離して責務を明確化
docs: APIエンドポイントの使用方法をREADMEに追記
```

### 4. Commit immediately

No confirmation needed. Use a HEREDOC to pass the message cleanly:

```bash
git commit -m "$(cat <<'EOF'
<generated message>

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### 5. Report the result

After committing, briefly report:
- Commit hash
- The commit message used
- Number of files changed

## Rules

- Never ask the user to review or confirm the commit message.
- Never commit sensitive files (`.env`, credentials, secrets).
- Never run `git push` unless the user explicitly asks.
- If a pre-commit hook fails: investigate and fix the issue, then create a new commit. Never use `--no-verify` or `--amend` unless explicitly instructed.
- If there is nothing to commit, say so clearly.
