# Setup DBT in Cloud Shell

## Overview

This tutorial will setup Cloud Shell to be useful for basic DBT
development, both from the command line and using Cloud Shell Editor,
for regulatory reporting.

It is assumed that a Regulatory Reporting environment has already been setup
using the [tutorial](https://github.com/GoogleCloudPlatform/reg-reporting-blueprint/blob/main/docs/TUTORIAL.md).

## Install development tools

### Install Python tools

Open the Terminal and run pip install.

```sh
pip3 install --user --upgrade dbt-core dbt-bigquery 'shandy-sqlfmt[jinjafmt]'
```

### Configure your PATH

Add $HOME/.local/bin to your path. This needs to be done both now in the shell, but also,
if not already done, to your $HOME/.profile.

```sh
export PATH="$PATH:$HOME/.local/bin"
(grep -q '$HOME/.local/bin' $HOME/.profile) || (echo 'export PATH="$PATH:$HOME/.local/bin"' >> $HOME/.profile)
```

### Test it out

Make sure DBT is in your path correctly.

```sh
dbt --version
```

### DBT Power Tool

Install the DBT Power User extension in Cloud Shell Editor

```sh
/google/devshell/editor/code-oss-for-cloud-shell/bin/codeoss-cloudshell --install-extension innoverio.vscode-dbt-power-user
```

## Configure DBT profile

### Choose a project that we want to open the editor with.

<walkthrough-project-setup></walkthrough-project-setup>

### Initialize the DBT profile

This will prompt you for the region and BigQuery location. This should be the same
as the environment that you setup with terraform.

```sh
PROJECT_ID="<walkthrough-project-id/>" common_components/devtools/init_dbt_profiles.sh
```

## Explore the project

### Move to DBT project

```sh
cd use_cases/examples/home_loan_delinquency/dbt
```

### Install DBT dependencies

```sh
dbt deps
```

### Test out DBT

```sh
dbt debug
```

## Start exploring Cloud Shell IDE

Open up the DBT folder in in Cloud Shell IDE

NOTE: This may prompt you to open up the parent folder. It works either way.

```sh
cloudshell workspace .
```

