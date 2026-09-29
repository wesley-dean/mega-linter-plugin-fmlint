# mega-linter-plugin-fmlint

[![MegaLinter](https://github.com/wesley-dean/mega-linter-plugin-fmlint/actions/workflows/megalinter.yml/badge.svg)](https://github.com/wesley-dean/mega-linter-plugin-fmlint/actions/workflows/megalinter.yml)
[![Dependabot Updates](https://github.com/wesley-dean/mega-linter-plugin-fmlint/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/wesley-dean/mega-linter-plugin-fmlint/actions/workflows/dependabot/dependabot-updates)
[![Scorecard supply-chain security](https://github.com/wesley-dean/mega-linter-plugin-fmlint/actions/workflows/scorecard.yml/badge.svg)](https://github.com/wesley-dean/mega-linter-plugin-fmlint/actions/workflows/scorecard.yml)

This MegaLinter plugin lints YAML frontmatter at the beginning of Markdown
documents.  A thin `fmlint` adapter extracts the frontmatter and delegates the
actual YAML analysis to [yamllint](https://github.com/adrienverge/yamllint).
Markdown after the closing frontmatter delimiter is never passed to yamllint.

## Frontmatter Contract

A document has YAML frontmatter when its first line is:

```text
---
```

The first subsequent standalone `---` line closes the frontmatter.  For
example:

```markdown
---
title: Example
tags:
  - documentation
  - example
---

# Markdown starts here

This content is not YAML and does not affect the frontmatter lint result.
```

Markdown files without an opening frontmatter delimiter are ignored.  An opening
delimiter without a closing delimiter is reported as malformed frontmatter.

## MegaLinter Configuration

Add the plugin descriptor to `.mega-linter.yml`:

```yaml
PLUGINS:
  - "https://raw.githubusercontent.com/wesley-dean/mega-linter-plugin-fmlint/refs/heads/main/mega-linter-plugin-fmlint/fmlint.megalinter-descriptor.yml"
```

Depending on the rest of your MegaLinter configuration, explicitly enable the
linter when necessary:

```yaml
ENABLE_LINTERS:
  - "MARKDOWN_FMLINT"
```

The descriptor uses MegaLinter's content filtering to select Markdown files that
begin with a frontmatter delimiter.  Existing
`MARKDOWN_FMLINT_FILTER_REGEX_INCLUDE` and
`MARKDOWN_FMLINT_FILTER_REGEX_EXCLUDE` settings remain available when a
repository wants to narrow that set further.

## yamllint Configuration

The default configuration file is `.fmlint.yml`.  It uses yamllint's ordinary
configuration syntax, so a repository may give frontmatter different YAML style
rules from its standalone YAML documents.

MegaLinter's generated configuration variable for overriding that path is
`MARKDOWN_FMLINT_CONFIG_FILE`.

## Development

The maintained adapter is `fmlint.bash`.  Behavioral tests use Bats and keep TAP
as the canonical console format while writing derivative JUnit data beneath
`test-results/`.

Useful targets are:

```bash
make test
make validate
make integration-test
make clean
```

`make test` runs deterministic wrapper behavior tests with a PATH-injected fake
yamllint.  `make validate` checks the descriptor against the schema from the
pinned MegaLinter release.  `make integration-test` loads the local descriptor
through that MegaLinter image and exercises real yamllint behavior.

## Repository Governance

This repository adopts released engineering standards from
[`wesley-dean/coding_standards`](https://github.com/wesley-dean/coding_standards).
The complete pinned snapshot is committed beneath `doc/standards/`, while
`.codingstandardrc` records the adopted release and verified archive digest.

Applicable files beneath `doc/standards/` are project requirements, subject to
accepted repository-specific ADRs and explicit local policy.  Imported standards
are managed as a release snapshot and are not edited locally to create
project-specific exceptions.
