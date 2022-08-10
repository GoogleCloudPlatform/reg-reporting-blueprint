# DBT Logging

This [dbt](https://github.com/dbt-labs/dbt) package contains macros that can be used for
capturing DBT log information. This is for on run start and run end and captures graph
information as well as result information.

Note that individual variables can also be captured, but this must be done through customizing
the macros.

## Installation Instructions

Read the docs on [DBT package management](https://docs.getdbt.com/docs/package-management)
for more information on installing packages.

It is recommended to *copy* these macros rather than using them as a
[git packpage](https://docs.getdbt.com/docs/building-a-dbt-project/package-management#git-packages).
This is due likely customization of the variables and environment variables captured in the dbt_log.

## Using them in your project

Install them in the on-run-start and on-run-end hook as follows:
```
on-run-start:
  - "{{ dbt_log.create_dbt_log(target) }}"
  - "{{ dbt_log.insert_dbt_log(target, 'START', dbt_log.graph_to_json(target, graph)) }}"

on-run-end:
  - "{{ dbt_log.insert_dbt_log(target, 'END', dbt_log.results_to_json(results)) }}"
```

## Configurations

As the macros record to a BigQuery log table, the name of this table can be configured.

The following variables are supported for configuring the log table:
 * `dbt_log_project`. The project for the dbt_log. Default is the default project.
 * `dbt_log_dataset`. The project for the dbt_log. Default is the default dataset.
 * `dbt_log_table`. The table for the dbt_log. Default is dbt_log.

## Using the dbt_log

In the dbt_log table there are four fields.

| Field             | Type      | Description                                      |
|-------------------|-----------|--------------------------------------------------|
| update_time       | TIMESTAMP | Timestamp when the log entry was written.        |
| dbt_invocation_id | STRING    | DBT invocation id.                               |
| stage             | STRING    | Stage of log entry. START or END.                |
| info              | JSON      | Information for the log entry. Depends on stage. |

The info in the START stage contains [graph details](https://docs.getdbt.com/reference/dbt-jinja-functions/graph)
(the full DBT graph!) and other environment and pipeline configuration that can be extracted.
The info in the END stage contains the
[run results](https://docs.getdbt.com/reference/artifacts/run-results-json).

## More examples

See [../README.md](../README.md) for more examples of using dbt_log.
