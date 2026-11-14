# Swift and Xcode projects

Extra setup for an app built with Xcode, on top of the skeleton. The templates live in [`../templates/swift/`](../templates/swift/).

## Ask

Add these to the one message in step 1:

- **App name**: the Xcode target, also the folder name. Default the project name without spaces.
- **Test simulator**: default the newest iPhone Pro in `xcrun simctl list devices available`, written as `iPhone 17 Pro,OS=26.2`.
- **Snapshot tests recorded locally only** (images stay out of Git): default yes.
- **Local Swift package** for the code below the UI (models, networking, repositories, view models), so its tests run with `swift test` on the Mac, without a simulator, and compile against an enforced module boundary: default no. Worth it when that layer is large or agents should run tests from the CLI.

## Steps

1. **Xcode project.** The user creates it in Xcode (File > New > Project, saved into the target directory, "Create Git repository" unchecked since the skeleton has one). Wait for it: done when `{{APP}}.xcodeproj`, `{{APP}}/` and `{{APP}}Tests/` exist. Its folders are synced groups, so the agent adds files by creating them on disk and leaves `project.pbxproj` alone.
2. **Tooling.** Copy `templates/swift/` into the folder that holds the `.xcodeproj`, keeping paths, with these renames: `swiftlint.yml` becomes `.swiftlint.yml`, `swiftformat` becomes `.swiftformat`, `tests.swiftlint.yml` becomes `{{APP}}Tests/.swiftlint.yml`, and `AGENTS-swift.md` is consumed rather than copied. Mark the scripts executable. Fill the placeholders:
   - `{{APP}}`: the app name.
   - `{{SIMULATOR}}`: the test simulator.
   - `{{SWIFT_VERSION}}`: major.minor from `xcrun swift --version`.
   - `{{AUTHOR}}`: the macOS full name (`id -F`), which Xcode writes in file headers.
3. **`.gitignore`.** Add `xcuserdata/`, `DerivedData/` and `.build/`, plus `__Snapshots__/` when snapshots stay local. With the allowlist style, also allow `{{APP}}/`, `{{APP}}.xcodeproj/`, `{{APP}}Tests/`, `.swiftlint.yml` and `.swiftformat`.
4. **`AGENTS.md`.** Append the body of `AGENTS-swift.md` as a `## Swift` section, before `## Git`.
5. **Local package** (when chosen).
   - Run `swift package init --type library --name {{APP}}Kit` in a new `{{APP}}Kit/` folder beside `{{APP}}/`. In `Package.swift`, set `platforms` to the app's iOS deployment target plus a matching `.macOS`, since `swift test` builds for the Mac. The package then keeps UIKit and SwiftUI views out; those stay in the app.
   - Ask the user to add it in Xcode (File > Add Package Dependencies > Add Local, then link `{{APP}}Kit` to the app target), since that edits `project.pbxproj`.
   - Add `{{APP}}Kit` to `SOURCES` in both scripts and to `included` in `.swiftlint.yml`, and allow `{{APP}}Kit/` in an allowlist `.gitignore`.
   - Add to the `## Swift` section: code below the UI lives in `{{APP}}Kit/Sources/{{APP}}Kit/`, in the same layer folders, with tests mirrored under `{{APP}}Kit/Tests/{{APP}}KitTests/`; run them with `swift test --package-path {{APP}}Kit`, which agents may run themselves.
   - Done when `swift test --package-path {{APP}}Kit` passes and the app builds in Xcode with the package linked.
6. **Test plan.** Ask the user to convert the scheme's tests to a test plan in Xcode (Product > Test Plan > Convert Scheme to Use Test Plans) and gather coverage for the app target only, so the number excludes the test bundle. The agent cannot set this up reliably by editing JSON, since the plan holds target identifiers from `project.pbxproj`.
7. **Check.** Run `./scripts/format.sh`, then `./scripts/lint.sh`. Done when lint passes on Xcode's template code, or when it fails only because `swiftlint` or `swiftformat` is missing (`brew install swiftlint swiftformat`), which goes in the report.

Commit with the skeleton when the Xcode project exists at setup; otherwise commit it later as `chore(xcode): app project and swift tooling`.
