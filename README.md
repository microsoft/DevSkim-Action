# DevSkim

DevSkim is security linter available both as IDE extensions and as a GitHub Action.  The DevSkim GitHub action outputs a sarif file compatible with GitHub's security issues view.

https://docs.github.com/en/github/finding-security-vulnerabilities-and-errors-in-your-code/uploading-a-sarif-file-to-github

## Usage

Add DevSkim to your GitHub Actions pipeline like below.

```
    - uses: actions/checkout@v2
    - uses: microsoft/DevSkim-Action
    - uses: github/codeql-action/upload-sarif@v1
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
```

### Features

* Built-in rules, and support for writing custom rules
* Information and guidance provided for identified security issues
* Broad language support including: C, C++, C#, Cobol, Go, Java, Javascript/Typescript, Python, and [more](https://github.com/Microsoft/DevSkim/wiki/Supported-Languages).

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