
# Configure Development Environment

Open the Terminal and install Python tools.

```sh
sudo pip3 install --upgrade dbt-core dbt-bigquery 'shandy-sqlfmt[jinjafmt]'
```

Install the DBT Power Tools if you're in Cloud Editor.

* Click on the extensions icon on the left bar (the four boxes with one removed)
* Find and install DBT Power User

# Set the DBT profile

This will prompt you for the project, region, and BigQuery location. This should be the same
as the environment that you setup with terraform.

```sh
common_components/devtools/init_dbt_profile.sh
```

# Explore the project

Move to the home loan delinquency example use case.

```sh
cd use_cases/examples/home_loan_delinquency/dbt
```

Install dependencies for DBT.

```sh
dbt deps
```

Test out connectivity

```sh
dbt debug
```
