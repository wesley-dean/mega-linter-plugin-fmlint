# ADR-001: Extract Frontmatter with a Per-File Wrapper

Date: 2026-09-29

## Status

Accepted

## Context

The plugin exists to lint YAML frontmatter embedded at the beginning of Markdown
documents.  Its README has consistently described an extraction step before
`yamllint`, and the repository originally implemented that behavior with a
wrapper executable.  A later refactor removed the wrapper, changed the
MegaLinter mode to `list_of_files`, and invoked `yamllint` directly on complete
Markdown documents.

That implementation can appear to work when the Markdown body also happens to
parse as YAML.  It fails the plugin's intended contract as soon as ordinary
Markdown syntax is not valid YAML.  Current MegaLinter descriptors provide file
selection, command construction, installation hooks, and lint modes, but no
descriptor-only facility that transforms each selected file before the linter
receives it.

## Decision Drivers

- Only YAML frontmatter should affect the lint result.
- Existing users should retain `MARKDOWN_FMLINT` and `.fmlint.yml`.
- Diagnostics should continue to identify the original Markdown path.
- The adapter should preserve yamllint arguments and exit status.
- Markdown files without frontmatter should not become false failures.
- The implementation should fit MegaLinter's external-plugin model without
  requiring changes to MegaLinter itself.
- Regression tests should protect the observable behavior that previously drifted.

## Decision

The plugin SHALL use a thin Bash executable named `fmlint` as its lint-time
adapter.  MegaLinter SHALL invoke the adapter in `file` mode so each invocation
receives exactly one Markdown path.

A candidate Markdown file contains frontmatter only when its first line is an
exact `---` delimiter, allowing an optional carriage return before the newline.
The first subsequent exact `---` line closes the frontmatter.  The adapter SHALL
pass the opening delimiter and YAML body to `yamllint`, but SHALL NOT pass the
closing delimiter or any Markdown content that follows it.

Files without an opening delimiter SHALL be ignored successfully.  An opening
delimiter without a closing delimiter SHALL be reported as malformed frontmatter.
The adapter SHALL preserve yamllint argv boundaries, propagate yamllint's exit
status, and rewrite diagnostics that name its temporary YAML representation so
they identify the original Markdown path.

MegaLinter's `file_contains_regex` SHALL perform the ordinary candidate-file
filter so Markdown files without frontmatter are normally excluded before the
adapter runs.  The adapter still handles such files safely because direct
invocation and future framework behavior must not turn absence of frontmatter
into a lint failure.

## Alternatives Considered

### Lint Complete Markdown Files with yamllint

Rejected because Markdown syntax outside the frontmatter is not YAML and must not
influence the result.  The existing passing fixture demonstrated that accidental
YAML compatibility is not evidence that the intended extraction occurred.

### Preprocess the Workspace with MegaLinter Pre-Commands

Rejected because pre-commands are not a per-file transformation boundary.  A
workspace-wide preprocessing phase would require a shadow file tree and would
couple file selection, generated state, and diagnostic mapping unnecessarily.

### Use a MegaLinter Custom Python Linter Class

Rejected for an external plugin.  MegaLinter resolves custom linter classes from
its own Python package, so this is appropriate for embedded linters rather than a
descriptor hosted in an independent plugin repository.

### Support list_of_files in the Wrapper

Rejected because it would require managing multiple extracted temporary files and
diagnostic mappings in one invocation without a meaningful performance benefit.
Frontmatter extraction is small, and `file` mode maps directly to the adapter's
one-document contract.

## Consequences

### Positive

- Markdown after the frontmatter can no longer cause false YAML findings.
- The wrapper has one small responsibility and remains independently testable.
- MegaLinter diagnostics continue to point at the consumer's Markdown file.
- Ordinary Markdown without frontmatter is filtered natively by MegaLinter and is
  also safe if it reaches the wrapper.
- Public configuration names remain compatible.

### Negative

- MegaLinter starts one wrapper process per selected Markdown file.
- The plugin again owns a small executable in addition to its descriptor.
- Plugin installation must make both yamllint and the wrapper available.

## Compatibility and Migration

The linter key remains `MARKDOWN_FMLINT`, and `.fmlint.yml` remains the
default yamllint configuration file.  Existing optional MegaLinter include and
exclude filters continue to work, but users no longer need an include filter
merely to avoid Markdown files that have no frontmatter.

The descriptor path remains unchanged.  Consumers do not need to change their
`PLUGINS` entry.

## Expected Outcome

A Markdown document with valid YAML frontmatter produces the same lint result
regardless of the Markdown syntax after the closing delimiter.  Invalid YAML
inside the frontmatter remains visible to yamllint and MegaLinter, while files
without frontmatter do not create false errors.
