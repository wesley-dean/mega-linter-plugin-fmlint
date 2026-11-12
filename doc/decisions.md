# Architectural Decisions

This index summarizes accepted decisions. The full ADRs govern when a
summary is incomplete; applicable imported shared standards and explicit
local policies remain authoritative.

## ADR-001: Extract Frontmatter with a Per-File Wrapper

The `MARKDOWN_FMLINT` plugin extracts YAML frontmatter through a per-file
Bash adapter before running yamllint. Markdown after the closing delimiter
does not affect lint results. Absent frontmatter is ignored, unterminated
frontmatter is rejected, and public configuration remains stable.

See [ADR-001](adr/ADR-001-extract-frontmatter-with-per-file-wrapper.md).

## ADR-002: Publish Versioned Descriptor Release Artifacts

Consumers may pin release descriptor assets rather than mutable `main`.
The generated descriptor pins runtime downloads to its exact source commit,
publishes a SHA-256 companion, and is validated before narrowly privileged
publication. Artifact naming and integration test boundaries are preserved.

See [ADR-002](adr/ADR-002-publish-versioned-descriptor-release-artifacts.md).

## ADR-003: Consolidate Scheduled Dependabot Version Updates

GitHub Actions and pip retain separate weekly version-update entries, each
with a seven-day cooldown and a wildcard major/minor/patch routine group.
Security updates remain independent; major-containing groups require human
review and cannot use the existing non-major auto-merge path. Pip update
verification must preserve generated dependency-hash correctness.

See [ADR-003](adr/ADR-003-consolidate-dependabot-version-updates.md).
