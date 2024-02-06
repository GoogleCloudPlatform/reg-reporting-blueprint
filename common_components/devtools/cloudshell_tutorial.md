# Setup DBT in Cloud Shell

## Overview

This tutorial will setup Cloud Shell to be useful for basic DBT
development, both from the command line and using Cloud Shell Editor,
for regulatory reporting.

It is assumed that a Regulatory Reporting environment has already been setup
using the [tutorial](https://github.com/GoogleCloudPlatform/reg-reporting-blueprint/blob/main/docs/TUTORIAL.md).

## Install Python development tools

### Configure your PATH

Add $HOME/.local/bin to your path. This needs to be done both now in the shell, but also,
if not already done, to your $HOME/.profile.

```sh
export PATH="$PATH:$HOME/.local/bin"
(grep -q '$HOME/.local/bin' $HOME/.profile) || (echo 'export PATH="$PATH:$HOME/.local/bin"' >> $HOME/.profile)
```

### Install Python tools

Open the Terminal and run pip install to install DBT, SQL fmt, and sqlfluff tools.

```sh
pip3 install --user --upgrade dbt-core dbt-bigquery 'shandy-sqlfmt[jinjafmt]' sqlfluff
```

### Test it out

Make sure DBT is in your path correctly.

```sh
dbt --version
```

## Install Cloud Shell Editor development tools

### Install Extensions

Install the DBT Power User and SQLfluff extensions in Cloud Shell Editor

```sh
/google/devshell/editor/code-oss-for-cloud-shell/bin/codeoss-cloudshell --install-extension innoverio.vscode-dbt-power-user
/google/devshell/editor/code-oss-for-cloud-shell/bin/codeoss-cloudshell --install-extension RobertOstermann.vscode-sqlfluff
```

### Install Cloud Shell Editor example configuration

Install the example configuration into the home_loan_delinquency DBT example.

```sh
common_components/devtools/init_codeoss_settings.sh use_cases/examples/home_loan_delinquency/dbt/.vscode/settings.json
```

Examine the sample configuration. SQLfluff should be configured.

```sh
cat use_cases/examples/home_loan_delinquency/dbt/.vscode/settings.json
```

## Configure DBT profile

### Initialize the DBT profile

This will prompt you for the project, region, and BigQuery location. This should be the same
as the environment that you setup with terraform.

```sh
common_components/devtools/init_dbt_profiles.sh
```

Look at the install profile.

```sh
cat $HOME/.dbt/profiles.yml
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

Note that this will request authorization (if not already provided) to access
BigQuery. This is a connectivity test.

```sh
dbt debug
```

## Start exploring Cloud Shell IDE

### Open up the DBT folder in in Cloud Shell IDE

NOTE: This may prompt you to open up the parent folder. It works either way.

```sh
cloudshell workspace .
```

### Close the terminal

Click X to close the terminal and use the IDE!
