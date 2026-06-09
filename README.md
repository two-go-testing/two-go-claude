# two-go-claude

Ready-to-use [Claude Code](https://claude.com/claude-code) resources for writing
API tests with [two-go](https://github.com/two-go-testing/two-go).

Drop these into your project and Claude Code will know how to write, review, and
debug two-go tests for you.

## What is in here

| Path | Type | What it does |
| --- | --- | --- |
| `skills/two-go/SKILL.md` | Skill | Teaches Claude the full two-go API: the request chain, every expectation, sessions, polling, schema validation, fake data, and importers. Loads automatically when you work on API tests. |
| `agents/two-go-test-author.md` | Subagent | Writes new two-go tests from an endpoint, a flow, or an OpenAPI/Postman spec. |
| `agents/two-go-test-reviewer.md` | Subagent | Reviews existing two-go tests for missing assertions, weak matchers, and flakiness. |

## Install

### Quick install

From the root of your project:

```bash
curl -sSL https://raw.githubusercontent.com/two-go-testing/two-go-claude/main/install.sh | bash
```

This copies the skill and the subagents into your project's `.claude/` directory.

### Manual install

Copy the folders into your project's `.claude/` directory:

```bash
mkdir -p .claude/skills .claude/agents
cp -r skills/two-go .claude/skills/two-go
cp agents/*.md .claude/agents/
```

To make them available in every project instead of just one, copy into your
home config at `~/.claude/skills` and `~/.claude/agents` instead.

## Use

Once installed, the skill activates on its own when you ask Claude to work on API
tests. The subagents run when you ask for them, for example:

- "Write two-go tests for the /orders endpoint."
- "Review the tests in test/api for missing assertions."

You can also invoke a subagent by name, such as `two-go-test-author`.

## License

MIT
