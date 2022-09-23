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


-- Calculate Information Value (IV) for all features
--
-- This query processes submissions with ratios to calculate information
-- value according to the will_default label. Note that metric_coverage
-- (number of labels with the metric) is also calculated.

WITH
  Subs AS (
    SELECT
      will_default,
      values
    FROM
      {{ ref('submissions_modelled') }} s
  ),

  -- Metric coverage stats
  MetricCoverage AS (
    SELECT
      key AS metric,
      COUNT(*) AS cnt
    FROM
      Subs s
      CROSS JOIN s.values
    GROUP BY
      1
  ),

  -- Add good and bad
  Src AS (
    SELECT
      key AS metric,
      IF(will_default,1,0) AS bad,
      IF(will_default,0,1) AS good,
      value
    FROM
      Subs s
      CROSS JOIN s.values
  ),

  -- Calculate 20 quantiles for each metric
  Quantile AS (
    SELECT
      metric,
      APPROX_QUANTILES(value, 20) AS metric_thresholds
    FROM
      Src
    GROUP BY
      1
  ),

    -- Turn into buckets
  Buckets AS (
    SELECT
      m.*,
      -- Find the bucket (bin) for each value
      (
        SELECT
          IFNULL(MIN(idx - 1), ARRAY_LENGTH(q.metric_thresholds)-2)
        FROM
          UNNEST(q.metric_thresholds) t
          WITH OFFSET idx
        WHERE
          idx > 0                                       -- Skip the lowest
          AND idx < ARRAY_LENGTH(q.metric_thresholds)-1 -- Skip the highest
          AND m.value <= t                              -- If match, then idx-1; if not match, then max
      ) AS bin

    FROM
      Src m
      JOIN Quantile q ON (q.metric=m.metric)
  ),

  -- Calculate Good/Bad stats over the entire metric
  BinStatsPrelim As (
   SELECT
      metric,
      bin,
      SUM(good) AS bin_good_raw,
      SUM(bad) AS bin_bad_raw,
    FROM
      Buckets
    GROUP BY
      1, 2
  ),

  BinStatsPrep As (
     SELECT
      metric,
      bin,
      CASE WHEN bin_good_raw = 0 THEN 0.99 ELSE bin_good_raw END as bin_good,
      CASE WHEN bin_bad_raw = 0 THEN 0.99 ELSE bin_bad_raw END as bin_bad,
    FROM
      BinStatsPrelim

  ),

  BinStats AS (
     SELECT
      metric,
      bin,
      bin_good,
      bin_bad,
      (SUM(bin_good) OVER (PARTITION BY metric)) AS metric_good,
      (SUM(bin_bad) OVER (PARTITION BY metric)) AS metric_bad
    FROM
      BinStatsPrep
  ),

  -- Prepare for WoE calculation
  -- Filter out metrics that don't have both good and bad elements
  -- Calculate percentage good and bad for the bin
  WoEPrep AS (
    SELECT
      *,
      bin_good / metric_good AS perc_good,
      bin_bad / metric_bad AS perc_bad,
    FROM
      BinStats
    WHERE
      metric_good > 0 AND metric_bad > 0
  ),

    -- Calculate WoE itself
  WoE AS (
    SELECT
      *,
      IF(perc_bad > 0 AND perc_good > 0,
        ((perc_good - perc_bad) * LN(perc_good/perc_bad)),
        -- From https://www.listendata.com/2015/03/weight-of-evidence-woe-and-information.html
        -- Handling zero events.
        ((perc_good - perc_bad) * LN( ((bin_good+0.5)/metric_good) / ((bin_bad+0.5)/(metric_bad)) ))
      ) AS woe_value
    FROM
      WoEPrep
  ),

  -- Calculate IV across all bins for each metric
  IV AS (
    SELECT
      metric,
      SUM(woe_value) AS iv_value
    FROM
      WoE
    GROUP BY
      1
    ORDER BY
      iv_value DESC
  )
SELECT
  *,
  -- Add in metric coverage across all submissions
  cnt/MAX(cnt) OVER () AS metric_coverage
FROM
  IV i
  JOIN MetricCoverage m USING (metric)

