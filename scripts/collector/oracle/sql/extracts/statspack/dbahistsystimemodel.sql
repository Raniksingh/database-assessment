/*
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

COLUMN HOUR FORMAT A4
spool &outputdir/opdb__dbahistsystimemodel__&v_tag

WITH vtimemodel AS (
SELECT
       '&&v_host' || '_' || '&&v_dbname' || '_' || '&&v_hora' as pkey,
       dbid,
       instance_number,
       hour,
       stat_name,
       COUNT(1)                                    cnt,
       ROUND(AVG(value))                           avg_value,
       ROUND(STATS_MODE(value))                    mode_value,
       ROUND(MEDIAN(value))                        median_value,
       ROUND(MIN(value))                           min_value,
       ROUND(MAX(value))                           max_value,
       ROUND(SUM(value))                           sum_value,
       ROUND(PERCENTILE_CONT(0.5)
         within GROUP (ORDER BY value DESC)) AS "PERC50",
       ROUND(PERCENTILE_CONT(0.25)
         within GROUP (ORDER BY value DESC)) AS "PERC75",
       ROUND(PERCENTILE_CONT(0.10)
         within GROUP (ORDER BY value DESC)) AS "PERC90",
       ROUND(PERCENTILE_CONT(0.05)
         within GROUP (ORDER BY value DESC)) AS "PERC95",
       ROUND(PERCENTILE_CONT(0)
         within GROUP (ORDER BY value DESC)) AS "PERC100"
FROM (
SELECT
       s.snap_id,
       s.dbid,
       s.instance_number,
       s.snap_time,
       to_char(s.snap_time,'hh24') hour,
       n.stat_name,
       NVL(DECODE(GREATEST(value, NVL(LAG(value)
                                        over (
                                          PARTITION BY s.dbid, s.instance_number, n.stat_name
                                          ORDER BY s.snap_id), 0)), value, value - LAG(value)
                                                                                     over (
                                                                                       PARTITION BY s.dbid, s.instance_number, n.stat_name
                                                                                       ORDER BY s.snap_id),
                                                                    0), 0) AS value
FROM   STATS$SNAPSHOT s,
       STATS$SYS_TIME_MODEL g,
       STATS$TIME_MODEL_STATNAME n
WHERE  s.snap_id = g.snap_id
       AND s.instance_number = g.instance_number
       AND s.dbid = g.dbid
       AND g.stat_id = n.stat_id
       AND s.snap_time BETWEEN '&&v_min_snaptime' AND '&&v_max_snaptime'
       AND s.dbid = '&&v_dbid'
)
GROUP BY
      '&&v_host' || '_' || '&&v_dbname' || '_' || '&&v_hora',
      dbid,
      instance_number,
      hour,
      stat_name)
SELECT pkey, dbid, instance_number, hour, stat_name, cnt,
       avg_value, mode_value, median_value, min_value, max_value,
	   sum_value, perc50, perc75, perc90, perc95, perc100
FROM vtimemodel;

spool off
COLUMN HOUR CLEAR
