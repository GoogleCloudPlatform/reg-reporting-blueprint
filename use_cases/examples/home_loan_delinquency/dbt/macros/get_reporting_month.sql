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


-- Macro for getting the reporting month
--
-- This macro gets the reporting month in the format YYYYMM from a reporting day in the format YYYY-MM-DD


{% macro get_reporting_month(reporting_day) %}
    {% set reporting_month = reporting_day | replace("-", "") %}
    {{ return (reporting_month[:6]) }}
{% endmacro %}
