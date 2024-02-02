
# Configure IDE and environment for DBT

## Open the Terminal and install Python tools

* Open a <walkthrough-editor-spotlight spotlightId="menu-terminal-new-terminal">new terminal</walkthrough-editor-spotlight>.

* In the terminal install globally the following tools:
```sh
sudo pip3 install --upgrade dbt-core dbt-bigquery 'shandy-sqlfmt[jinjafmt]'
```

## Install DBT Power User extension

* Click on the extensions icon on the left (the four boxes with one removed)
* Find and install DBT Power User

## Install sample profile

```sh
mkdir $HOME/.dbt
cat $HOME/$CLOUDSHELL_OPEN_DIR/reg-reporting-blueprint/common_components/devtools/cloudshell_profile.yml > $HOME/.dbt/profiles.yml
```

### Open and configure profile

 * Open the <walkthrough-editor-select-line filePath="$HOME/.dbt/profiles.yml" regex="BigQuery Location">profiles.yml</walkthrough-editor-select-line> file and replace the BigQuery Location.
 * Modify <walkthrough-editor-select-line filePath="$HOME/.dbt/profiles.yml" regex="BigQuery Location">profiles.yml</walkthrough-editor-select-line> file and replace the Region.

# Explore the project

## Open the dbt_project.yml

 * Open the <walkthrough-editor-open-file filePath="use_cases/examples/home_loan_delinquency/dbt/dbt_project.yml">dbt_project.yml</walkthrough-editor-open-file> file.


