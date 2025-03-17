<a id="readme-top"></a>

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![BSD-3-Clause License][license-shield]][license-url]

---

<br />
<div align="center">
    <p>Copyright (c) 2022, <a href="https://github.com/programmingwithalex">GitHub@programmingwithalex</a></p>


  <h3 align="center">pytester-cov</h3>

  <p align="center">
    Enforce minimum pytest coverage by individual files, total, or both
    <br />
    <a href="https://github.com/programmingwithalex/pytester-cov/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    ·
    <a href="https://github.com/programmingwithalex/pytester-cov/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>

## Python Packages Used

- [`pytest`](https://pypi.org/project/pytest/)
- [`pytest-cov`](https://pypi.org/project/pytest-cov/)

## Optional Inputs

- `pytest-root-dir`
  - root directory to recursively search for .py files
  - by default `pytest --cov` does not run recursively, but will here
- `pytest-tests-dir`
  - directory with pytest tests
  - if left empty will identify test(s) dir by default
- `requirements-file`
  - requirements filepath for project
  - if left empty will default to `requirements.txt`
  - necessary to install requirements to run `pytest` inside action
- `cov-omit-list`
  - list of directories and/or files to ignore
- `cov-threshold-single`
  - fail if any single file coverage is less than threshold
- `cov-threshold-total`
  - fail if the total coverage is less than threshold

## Outputs

- `output-table`
  - str
  - `pytest --cov` markdown output table
- `cov-threshold-single-fail`
  - boolean
  - `false` if any single file coverage less than `cov-threshold-single`, else `true`
- `cov-threshold-total-fail`
  - boolean
  - `false` if total coverage less than `cov-threshold-total`, else `true`

## Template workflow file

```yaml
# **************************************************************************************************************** #
# This workflow will install Python dependencies, and run `pytest --cov` on all files recursively from the `pytest-root-dir`
# The workflow is also configured to exit with error if minimum individual file or total pytest coverage minimum not met
# If the workflow exits with error, an informative issue is created for the repo alerting the user
# If the workflow succeeds, a commit message is generated with the `pytest --cov` markdown table
#
# Variables to set:
#   * pytester action:
#     * pytest-root-dir: top-level directory to recursively check all .py files for `pytest --cov`
#     * cov-omit-list: comma separated str of all files and/or dirs to ignore
#   * env:
#     * COVERAGE_SINGLE: minimum individual file coverage required
#     * COVERAGE_TOTAL: minimum total coverage required
#
# Action outputs:
#   * output-table: `pytest --cov` markdown output table
#   * cov-threshold-single-fail: `true` if any single file coverage less than `cov-threshold-single`, else `false`
#   * cov-threshold-total-fail: `true` if total coverage less than `cov-threshold-total`, else `false`
#
# Workflows used:
#   * actions/checkout@main: checkout files to perform additional actions on
#   * programmingwithalex/pytester-cov@main: runs `pytest --cov` and associated functions
#   * nashmaniac/create-issue-action@v1.1: creates issue for repo
#   * peter-evans/commit-comment@main: adds message to commit
# **************************************************************************************************************** #

name: pytester-cov workflow

on: [push, pull_request]

jobs:
  build:

    runs-on: ubuntu-latest
    env:
      COVERAGE_SINGLE: 60
      COVERAGE_TOTAL: 60

    steps:
    - uses: actions/checkout@main
    - name: Set up Python 3.9
      uses: actions/setup-python@main
      with:
        python-version: 3.9
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install flake8 pytest
        if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

    - name: pytester-cov
      id: pytester-cov
      uses: programmingwithalex/pytester-cov@main
      with:
        pytest-root-dir: '.'
        cov-omit-list: 'test/*, temp/main3.py, temp/main4.py'
        cov-threshold-single: ${{ env.COVERAGE_SINGLE }}
        cov-threshold-total: ${{ env.COVERAGE_TOTAL }}

    - name: Coverage single fail - new issue
      if: ${{ steps.pytester-cov.outputs.cov-threshold-single-fail == 'true' }}
      uses: nashmaniac/create-issue-action@v1.1
      with:
        title: Pytest coverage single falls below minimum ${{ env.COVERAGE_SINGLE }}
        token: ${{secrets.GITHUB_TOKEN}}
        assignees: ${{github.actor}}
        labels: workflow-failed
        body: ${{ steps.pytester-cov.outputs.output-table }}

    - name: Coverage single fail - exit
      if: ${{ steps.pytester-cov.outputs.cov-threshold-single-fail == 'true' }}
      run: |
        echo "cov single fail ${{ steps.pytester-cov.outputs.cov-threshold-single-fail }}"
        exit 1

    - name: Coverage total fail - new issue
      if: ${{ steps.pytester-cov.outputs.cov-threshold-total-fail == 'true' }}
      uses: nashmaniac/create-issue-action@v1.1
      with:
        title: Pytest coverage total falls below minimum ${{ env.COVERAGE_TOTAL }}
        token: ${{secrets.GITHUB_TOKEN}}
        assignees: ${{github.actor}}
        labels: workflow-failed
        body: ${{ steps.pytester-cov.outputs.output-table }}

    - name: Coverage total fail - exit
      if: ${{ steps.pytester-cov.outputs.cov-threshold-total-fail == 'true' }}
      run: |
        echo "cov single fail ${{ steps.pytester-cov.outputs.cov-threshold-total-fail }}"
        exit 1

    - name: Commit pytest coverage table
      uses: peter-evans/commit-comment@main
      with:
        body: ${{ steps.pytester-cov.outputs.output-table }}
```

## License

[BSD 3-Clause License](https://github.com/programmingwithalex/pytester-cov/blob/main/LICENSE)

[contributors-shield]: https://img.shields.io/github/contributors/programmingwithalex/pytester-cov?style=for-the-badge
[contributors-url]: https://github.com/programmingwithalex/pytester-cov/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/programmingwithalex/pytester-cov?style=for-the-badge
[forks-url]: https://github.com/programmingwithalex/pytester-cov/network/members
[stars-shield]: https://img.shields.io/github/stars/programmingwithalex/pytester-cov?style=for-the-badge
[stars-url]: https://github.com/programmingwithalex/pytester-cov/stargazers
[issues-shield]: https://img.shields.io/github/issues/programmingwithalex/pytester-cov?style=for-the-badge
[issues-url]: https://github.com/programmingwithalex/pytester-cov/issues
[license-shield]: https://img.shields.io/github/license/programmingwithalex/pytester-cov.svg?style=for-the-badge
[license-url]: https://github.com/programmingwithalex/pytester-cov/blob/main/LICENSE
