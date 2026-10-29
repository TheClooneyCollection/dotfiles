# Swift and Xcode projects

Extra setup for an app built with Xcode, on top of the skeleton. The templates live in [`../templates/swift/`](../templates/swift/).

## Ask

Add these to the one message in step 1:

- **App name**: the Xcode target, also the folder name. Default the project name without spaces.
- **Test simulator**: default the newest iPhone Pro in `xcrun simctl list devices available`, written as `iPhone 17 Pro,OS=26.2`.
- **Snapshot tests recorded locally only** (images stay out of Git): default yes.

## Steps

1. **Xcode project.** The user creates it in Xcode (File > New > Project, saved into the target directory, "Create Git repository" unchecked since the skeleton has one). Wait for it: done when `{{APP}}.xcodeproj`, `{{APP}}/` and `{{APP}}Tests/` exist. Its folders are synced groups, so the agent adds files by creating them on disk and leaves `project.pbxproj` alone.
2. **Tooling.** Copy `templates/swift/` into the folder that holds the `.xcodeproj`, keeping paths, with these renames: `swiftlint.yml` becomes `.swiftlint.yml`, `swiftformat` becomes `.swiftformat`, `tests.swiftlint.yml` becomes `{{APP}}Tests/.swiftlint.yml`, and `AGENTS-swift.md` is consumed rather than copied. Mark the scripts executable. Fill the placeholders:
   - `{{APP}}`: the app name.
   - `{{SIMULATOR}}`: the test simulator.
   - `{{SWIFT_VERSION}}`: major.minor from `xcrun swift --version`.
   - `{{AUTHOR}}`: the macOS full name (`id -F`), which Xcode writes in file headers.
3. **`.gitignore`.** Add `xcuserdata/`, `DerivedData/` and `.build/`, plus `__Snapshots__/` when snapshots stay local. With the allowlist style, also allow `{{APP}}/`, `{{APP}}.xcodeproj/`, `{{APP}}Tests/`, `.swiftlint.yml` and `.swiftformat`.
4. **`AGENTS.md`.** Append the body of `AGENTS-swift.md` as a `## Swift` section, before `## Git`.
5. **Test plan.** Ask the user to convert the scheme's tests to a test plan in Xcode (Product > Test Plan > Convert Scheme to Use Test Plans) and gather coverage for the app target only, so the number excludes the test bundle. The agent cannot set this up reliably by editing JSON, since the plan holds target identifiers from `project.pbxproj`.
6. **Check.** Run `./scripts/format.sh`, then `./scripts/lint.sh`. Done when lint passes on Xcode's template code, or when it fails only because `swiftlint` or `swiftformat` is missing (`brew install swiftlint swiftformat`), which goes in the report.

Commit with the skeleton when the Xcode project exists at setup; otherwise commit it later as `chore(xcode): app project and swift tooling`.
