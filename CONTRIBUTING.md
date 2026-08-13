# Contributing

## Workflow

1. Create a focused branch from `main`, such as `fix/shopping-layout` or
   `feature/production-queue-filter`.
2. Make one cohesive change and test it in every affected WoW client.
3. Add user-visible changes under `Unreleased` in `CHANGELOG.md`.
4. Open a pull request and merge it only after validation succeeds.

Use concise imperative commit subjects, for example:

```text
Fix Shopping viewport alignment
```

## Versioning

Logistician follows Semantic Versioning:

- Patch (`1.1.77` to `1.1.78`): compatible fixes and small UI corrections.
- Minor (`1.1.77` to `1.2.0`): backward-compatible features.
- Major (`1.1.77` to `2.0.0`): breaking behavior or incompatible data changes.

The version in `!Logistician.toc`, Git tag, GitHub release, and package name
must match. Git tags use a `v` prefix, such as `v1.1.77`.

## Release checklist

1. Verify the addon in each affected WoW client.
2. Move changelog entries from `Unreleased` into a dated version section.
3. Update `## Version:` in `!Logistician.toc`.
4. Merge the release commit into `main`.
5. Create and push an annotated matching tag, such as `v1.1.77`.

The release workflow validates the tag against the TOC, packages the addon as
`Logistician-vX.Y.Z.zip`, and publishes a GitHub release. Do not manually edit
an already published tag or release asset; issue a new patch version instead.
