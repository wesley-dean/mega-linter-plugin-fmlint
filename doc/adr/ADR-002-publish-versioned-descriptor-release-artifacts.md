# ADR-002: Publish Versioned Descriptor Release Artifacts

Date: 2026-09-29

## Status

Accepted

## Context

MegaLinter consumes an external plugin through its descriptor URL.  Historically,
fmlint documentation recommended the descriptor stored on the repository's
`main` branch.  That makes development state a distribution channel: a consumer
can receive different plugin behavior without changing its own configuration.

The frontmatter repair also requires the descriptor to install `fmlint.bash`
and its pinned Python requirements.  A released descriptor therefore needs a
coherent way to identify the exact runtime files that belong to that release.

The repository has no prior GitHub releases or tags.  It already adopts
Conventional Commit and release-versioning governance, and related projects use a
validate-then-publish GitHub Actions boundary for release artifacts.

## Decision Drivers

- Production consumers should be able to pin an immutable plugin release.
- Consumers who intentionally follow releases should have a stable latest-release
  URL that does not point at development state.
- A released descriptor must install the wrapper and requirements from the same
  source revision that produced the descriptor.
- Distributed bytes should be validated directly before publication.
- Publication authority should be separated from source execution and validation.
- The repository's maintained descriptor should remain convenient for development
  and should preserve the existing source path.

## Decision

Every GitHub release SHALL include:

```text
fmlint.megalinter-descriptor.yml
fmlint.megalinter-descriptor.yml.sha256
```

The maintained descriptor at
`mega-linter-plugin-fmlint/fmlint.megalinter-descriptor.yml` remains the source
descriptor and MAY follow the `main` branch for development-time runtime
downloads.

The release build SHALL generate the distributed descriptor from that maintained
descriptor.  During generation, the two fmlint-owned raw GitHub runtime URLs SHALL
be replaced with URLs pinned to the exact Git commit that produced the release.
The generated descriptor SHALL record the release version and source commit in
YAML comments.

The build SHALL reject a symbolic or mutable runtime reference.  `BUILD_REF`
must be a 40-character lowercase Git commit SHA.  The generated descriptor SHALL
contain exactly two commit-pinned fmlint runtime references and no fmlint
`refs/heads/main` runtime reference.

Release validation SHALL test the generated descriptor itself, including:

- MegaLinter descriptor-schema validation;
- SHA-256 checksum verification;
- successful linting of valid frontmatter through MegaLinter;
- rejection of invalid YAML frontmatter through MegaLinter; and
- rejection of unterminated frontmatter through MegaLinter.

Only after validation succeeds SHALL a separate publication job receive the
release files.  That job SHALL re-verify the exact file set and checksum before
creating the GitHub release.

The initial release version SHALL be `v0.1.0`.  Subsequent versions SHALL follow
the repository's adopted Conventional Commit and semantic-versioning governance.

Documentation SHALL recommend a version-pinned release asset for reproducible CI:

```text
https://github.com/wesley-dean/mega-linter-plugin-fmlint/releases/download/vX.Y.Z/fmlint.megalinter-descriptor.yml
```

Documentation MAY also offer the following URL when a consumer intentionally
wants the newest published release:

```text
https://github.com/wesley-dean/mega-linter-plugin-fmlint/releases/latest/download/fmlint.megalinter-descriptor.yml
```

The raw `main` descriptor is a development surface and SHALL NOT be the primary
documented production installation method.

MegaLinter validates the configured plugin URL or `file://` path before loading
the descriptor.  Its plugin-path contract requires the configured string to
contain `/mega-linter-plugin-` and to end with
`.megalinter-descriptor.yml`.  Both documented GitHub release URL forms satisfy
that contract because the repository path contains
`/mega-linter-plugin-fmlint/`, even though GitHub may subsequently redirect the
HTTPS request to a release-asset host with a different URL.

Local integration testing of the generated artifact is different: the natural
build path `file://dist/fmlint.megalinter-descriptor.yml` does not contain the
required repository-name segment.  Tests therefore stage a byte-identical copy
beneath a temporary `mega-linter-plugin-` directory before invoking MegaLinter.
That staging path is a local-test accommodation and does not change the release
artifact filename or public distribution URLs.

## Alternatives Considered

### Continue Recommending the main-Branch Descriptor

Rejected because branch content is mutable and consumers can receive new behavior
without an explicit release decision.

### Pin Runtime Downloads to the Release Tag

Considered because a tag gives human-readable version coherence.  Rejected in
favor of the release commit SHA because the SHA exists before publication and
allows CI to exercise the exact generated descriptor before a tag or GitHub
release is created.  The GitHub release and tag still provide the human-facing
version boundary.

### Publish Only a Checksum

Rejected because a checksum without the descriptor asset would leave the mutable
branch as the distribution channel.

### Publish the Descriptor Without a Checksum

Rejected because a checksum is inexpensive, provides an additional integrity
check for downloaded bytes, and matches the artifact conventions used by related
projects.  The checksum is not treated as independent publisher authentication.

### Build and Publish in One Privileged Job

Rejected because source execution and publication authority do not need to
coexist.  A validate-then-publish boundary provides narrower capabilities and
allows the publication job to operate only on already validated artifacts.

## Consequences

### Positive

- Production consumers can pin an immutable fmlint release.
- Consumers can follow releases without following `main`.
- Release descriptors install runtime files from one exact source revision.
- CI directly validates the descriptor bytes that will be published.
- Publication credentials are isolated from the job that executes repository
  source and tests.
- Release artifacts have a checksum and explicit provenance comments.

### Negative

- The repository gains release-build and publication machinery.
- Development and release descriptors intentionally differ in their fmlint-owned
  runtime URL references.
- Maintainers must treat the pull request or merge title as a release-significance
  input under the adopted release governance.

## Compatibility and Migration

The maintained descriptor path, `MARKDOWN_FMLINT` key, and `.fmlint.yml`
configuration contract remain unchanged.

Existing consumers of the raw `main` descriptor continue to function after the
frontmatter repair is merged.  They are encouraged to move to either a pinned
release asset or the latest-release asset according to their reproducibility
needs.

No existing release URL is invalidated because this repository had no prior
GitHub releases or tags.

## Expected Outcome

A consumer can choose explicitly between immutable version-pinned fmlint behavior
and automatic adoption of newly published fmlint releases.  Published descriptor
bytes are validated before publication and install runtime files from the exact
source commit represented by the release.
