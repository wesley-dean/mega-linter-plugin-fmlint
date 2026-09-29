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

### ADR-002: Publish Versioned Descriptor Release Artifacts

Normal consumers use GitHub release assets rather than the mutable `main`
descriptor.  Each release publishes the descriptor and its SHA-256 checksum, and
the distributed descriptor pins its runtime downloads to the exact source commit
that produced the release.  Validation exercises the generated descriptor before
a separate, narrowly privileged publication job re-verifies and publishes the
same bytes.

See [ADR-002](ADR-002-publish-versioned-descriptor-release-artifacts.md).

<!-- adrctl-generated-footer -->

## Architecture Decision Records

* [ADR-001: Extract Frontmatter with a Per-File Wrapper](ADR-001-extract-frontmatter-with-per-file-wrapper.md)
* [ADR-002: Publish Versioned Descriptor Release Artifacts](ADR-002-publish-versioned-descriptor-release-artifacts.md)
