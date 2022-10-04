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

-- This file contains utilities to generate ratios of given features

{% macro divide_value(table, key, nom, denom) %}
  STRUCT(
     '{{ key }}'
       AS key,
     SAFE_DIVIDE(
        (SELECT ANY_VALUE(value) FROM {{ table }} WHERE key='{{ nom }}'),
        (SELECT ANY_VALUE(value) FROM {{ table }} WHERE key='{{ denom }}'))
      AS value
  )
{% endmacro %}

{% macro divide_value_pivoted(numerator, denominator, prefix) %}
     SAFE_DIVIDE( {{ prefix }}.{{ numerator }} ,  {{ prefix }}.{{ denominator }} ) AS {{ numerator }}_over_{{ denominator }}
{% endmacro %}