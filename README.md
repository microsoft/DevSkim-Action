# DevSkim

DevSkim is security linter that highlights common security issues in source code.  

The DevSkim GitHub Action outputs a sarif file compatible with GitHub's Security Issues view.

## Usage

Add DevSkim to your GitHub Actions pipeline like below.

Pin to a specific released version tag rather than a moving major/minor alias like `@v1`; this action no longer updates a floating `v1` tag. For the strongest supply-chain guarantee, pin to the full commit SHA of a release instead of a tag (see [Versioning and releases](#versioning-and-releases) below).

> **Note:** `v2.0.0` below is the version this README documents and is not published yet. Until it is released, use the [latest available release tag](https://github.com/microsoft/DevSkim-Action/releases) instead. Maintainers: remove/update this note once `v2.0.0` (or a later version) has actually been published.

```
    - uses: actions/checkout@v4
    - uses: microsoft/DevSkim-Action@v2.0.0
    - uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: devskim-results.sarif
```

You can also specify a number of options to the action.

```
    - uses: microsoft/DevSkim-Action@v2.0.0
      with:
        directory-to-scan: path/to/scan
        should-scan-archives: false
        output-filename: devskim-results.sarif
        output-directory: path/to/output (appended to $GITHUB_WORKSPACE)
        ignore-globs: "**/.git/**,*.txt"
        exclude-rules: DS176209,DS148264
        options-json: path/to/options.json
        extra-options: --args --to --devskimAnalyze
        devskim-version: 1.0.90
```
## Arguments
The arguments specified are provided to the DevSkim CLI's Analyze command. See the [DevSkim Wiki](https://github.com/microsoft/DevSkim/wiki/Analyze-Command) for detailed usage instruction.

### directory-to-scan
Relative path in `$GITHUB_WORKSPACE` for DevSkim to Scan. Equivalent to the `--source-code` argument to Analyze.

### should-scan-archives
DevSkim can peek into archives to scan the files contained inside them. Setting this to true will enable that behavior. Equivalent to the `--crawl-archives` argument to Analyze.

### output-filename
The filename to use for the results of the Analyze scan. Along with `output-directory` equivalent to the `--output-file` argument to Analyze.

### output-directory
Relative path to a directory in `$GITHUB_WORKSPACE` to emit the output file, default to output in the root of `$GITHUB_WORKSPACE` with the specified `output-filename`.

### ignore-globs
Files which match any of these globs will be skipped during analysis. Equivalent to the `--ignore-globs` argument to Analyze.

### exclude-rules
Comma separated list of Rule IDs to skip during analysis.  Equivalent to the `--ignore-rule-ids` argument to Analyze.

### options-json
Relative path in `$GITHUB_WORKSPACE` to a json serialiation of a SerializedAnalyzeCommandOptions object. Equivalent to the `--options-json` argument to Analyze.

### extra-options
Use this field to specify any other arguments to the DevSkim Analyze command. See the [DevSkim Wiki](https://github.com/microsoft/DevSkim/wiki/Analyze-Command) for available options and usage documentation.

### devskim-version
Optional. An exact, published `Microsoft.CST.DevSkim.Cli` NuGet package version, for example `1.0.90` or a prerelease such as `1.0.91-beta.1`. Version ranges, wildcards (`1.0.*`), floating aliases (`latest`), and any other non-exact value are rejected and cause the action to fail before scanning, rather than silently falling back to a default. Leave this empty (the default) to use the version bundled with the action, which requires no runtime network install. If you set `devskim-version` to a value different from the bundled version, the action downloads that exact CLI version from the official [nuget.org](https://www.nuget.org/packages/Microsoft.CST.DevSkim.Cli) feed into an isolated directory at container start; **you are responsible for confirming that the version you choose is compatible with your ruleset and CLI options**, since it is not the version this action was tested against.

## DevSkim CLI version pinning

Earlier versions of this action installed the DevSkim CLI without pinning a version, so upstream `Microsoft.CST.DevSkim.Cli` releases could change scan behavior for everyone using this action without a corresponding action release. Starting with this release, the action's container image bundles one exact, tested `Microsoft.CST.DevSkim.Cli` version by default (currently `1.0.90`), pinned in the `Dockerfile`. Upstream DevSkim CLI publications never implicitly change the version this action runs; a new CLI version is only picked up when a maintainer bumps the pin and cuts a new action release.

Use the [`devskim-version`](#devskim-version) input if you need a different exact CLI version than the one currently bundled. Note that pinning the CLI version does not, by itself, make the container build fully reproducible: the base .NET SDK image and its own dependencies can still change over time independently of this pin.

### For maintainers: bumping the pin and releasing

1. Pick the new exact `Microsoft.CST.DevSkim.Cli` version from the [official NuGet listing](https://www.nuget.org/packages/Microsoft.CST.DevSkim.CLI).
2. Update the `DEVSKIM_CLI_VERSION` build argument default in `Dockerfile` and verify the image builds and `docker run`/`tests/entrypoint_test.sh` still pass, including a scan against representative test files, to confirm compatibility with the .NET runtime and the CLI arguments this action passes.
3. Bump the `VERSION` file to the next action release version (a new minor/patch for additive changes, or a new major for breaking changes) and merge the reviewed change to `main`.
4. Once the build/test job succeeds on `main`, the release workflow automatically creates a `vX.Y.Z` tag and GitHub release for that exact tested commit. It never moves an existing tag; if `VERSION` isn't bumped, or already matches the current tag for that commit, no new tag or release is created.

## Versioning and releases

This action is versioned with full `vMAJOR.MINOR.PATCH` release tags (see the repository's [Releases](https://github.com/microsoft/DevSkim-Action/releases) page for what has actually been published). Prefer pinning to:

* A full release tag, e.g. `microsoft/DevSkim-Action@v2.0.0`, or
* A full commit SHA, e.g. `microsoft/DevSkim-Action@<40-character-sha>`, for the strongest guarantee that the action's behavior cannot change without you explicitly updating the reference.

This action no longer recommends or maintains a moving `@v1` alias tag. Release tags are created once, for a specific tested commit, and are not force-moved afterward. The repository maintainers may additionally enable GitHub's [immutable releases](https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases) setting, which is a repository setting outside the scope of this action's workflow changes; not force-moving tags in automation is a best-effort practice, not a substitute for that platform-enforced protection. See GitHub's guide on [using immutable releases and tags to manage your actions releases](https://docs.github.com/en/actions/how-tos/create-and-publish-actions/using-immutable-releases-and-tags-to-manage-your-actions-releases) for details.

## Features

* Built-in ruleset highlighting common security issues in source code
* Support for scanning code contained in archives
* Information and guidance provided for identified security issues
* Broad language support including: C, C++, C#, Cobol, Go, Java, Javascript/Typescript, Python, and [more](https://github.com/Microsoft/DevSkim/wiki/#supported-languages).

## Main Project

The DevSkim engine powering this GitHub Action is also available [here](https://github.com/Microsoft/DevSkim) as a Cli and as IDE extensions for Visual Studio and Visual Studio Code.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
