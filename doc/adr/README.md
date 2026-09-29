# Architecture Decisions

This directory contains accepted Architecture Decision Records for
`mega-linter-plugin-fmlint`.

## Current Decisions

### ADR-001: Extract Frontmatter with a Per-File Wrapper

The plugin uses a thin Bash adapter in MegaLinter `file` mode so only YAML
frontmatter reaches `yamllint`.  MegaLinter filters ordinary Markdown candidates
by content, while the adapter independently treats files without frontmatter as a
successful no-op and reports an opening delimiter without a close as malformed.
The public `MARKDOWN_FMLINT` and `.fmlint.yml` interfaces remain stable, and
yamllint diagnostics are attributed back to the original Markdown path.

See [ADR-001](ADR-001-extract-frontmatter-with-per-file-wrapper.md).

<!-- adrctl-generated-footer -->

## Architecture Decision Records

* [ADR-001: Extract Frontmatter with a Per-File Wrapper](ADR-001-extract-frontmatter-with-per-file-wrapper.md)
