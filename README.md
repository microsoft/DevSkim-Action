# DevSkim

DevSkim is security linter that highlights common security issues in source code.  

The DevSkim GitHub Action outputs a sarif file compatible with GitHub's Security Issues view.

## Usage

Add DevSkim to your GitHub Actions pipeline like below.

```
    - uses: actions/checkout@v3
    - uses: microsoft/DevSkim-Action@v1
    - uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: devskim-results.sarif
```

You can also specify a number of options to the action.

```
    - uses: microsoft/devskim-action@v1
      with:
        directory-to-scan: path/to/scan
        should-scan-archives: false
        output-filename: devskim-results.sarif
        output-directory: path/to/output (appended to $GITHUB_WORKSPACE)
        ignore-globs: "**/.git/**,*.txt"
        exclude-rules: DS176209,DS148264
        options-json: path/to/options.json
        extra-options: --args --to --devskimAnalyze
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
