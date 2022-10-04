-- Copyright 2022 The Reg Reporting Blueprint Authors

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     https://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- This is a variation of the pivot macro in dbt_utils which sums the values in the then_value column

{#
This is a variation of the pivot macro in dbt_utils which sums the values in the then_value column

Arguments:
    column: Column name, required
    values: List of row values to turn into columns, required
    alias: Whether to create column aliases, default is True
    agg: SQL aggregation function, default is sum
    cmp: SQL value comparison, default is =
    prefix: Column alias prefix, default is blank
    suffix: Column alias postfix, default is blank
    then_value: Value to use if comparison succeeds, default is 1
    else_value: Value to use if comparison fails, default is 0
    quote_identifiers: Whether to surround column aliases with double quotes, default is true
    distinct: Whether to use distinct in the aggregation, default is False
#}

{% macro pivot_and_aggregate(column,
                             values,
                             alias=True,
                             agg='SUM',
                             cmp='=',
                             prefix='',
                             suffix='',
                             then_value=1,
                             else_value=0,
                             quote_identifiers=True,
                             distinct=False) %}
    {{ return(adapter.dispatch('pivot', 'dbt_utils')(column, values, alias, agg, cmp, prefix, suffix, then_value, else_value, quote_identifiers, distinct)) }}
{% endmacro %}

{% macro default__pivot(column,
               values,
               alias=True,
               agg='SUM',
               cmp='=',
               prefix='',
               suffix='',
               then_value=1,
               else_value=0,
               quote_identifiers=True,
               distinct=False) %}
  {%- for value in values %}
    {{ agg }}(
      {%- if distinct %} DISTINCT {% endif %}
      IF(
        {{ column }} {{ cmp }} '{{ escape_single_quotes(value) }}',
        {{ then_value }},
        {{ else_value }}
      )
    )
    {%- if alias %}
      {%- if quote_identifiers %}
            AS {{ adapter.quote(prefix ~ value ~ suffix) }}
      {%- else %}
        AS {{ dbt_utils.slugify(prefix ~ value ~ suffix) }}
      {%- endif %}
    {%- endif %}
    {%- if not loop.last %},{% endif %}
  {%- endfor %}
{% endmacro %}
