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
spool &outputdir/opdb__sourcecode__&v_tag

WITH vsrc AS (
SELECT pkey,
       con_id,
       owner,
       TYPE,
       SUM(nr_lines)       sum_nr_lines,
       COUNT(1)            qt_objs,
       SUM(count_utl)      sum_nr_lines_w_utl,
       SUM(count_dbms)     sum_nr_lines_w_dbms,
       SUM(count_exec_im)  count_exec_im,
       SUM(count_dbms_sql) count_dbms_sql,
       SUM(count_dbms_utl) sum_nr_lines_w_dbms_utl,
       SUM(count_total)    sum_count_total
FROM   (SELECT '&&v_host'
               || '_'
               || '&&v_dbname'
               || '_'
               || '&&v_hora' AS pkey,
               &v_a_con_id AS con_id,
               owner,
               name,
               TYPE,
               MAX(line)     NR_LINES,
               COUNT(CASE
                       WHEN LOWER(text) LIKE '%utl_%' THEN 1
                     END)    count_utl,
               COUNT(CASE
                       WHEN LOWER(text) LIKE '%dbms_%' THEN 1
                     END)    count_dbms,
               COUNT(CASE
                       WHEN LOWER(text) LIKE '%dbms_%'
                            AND LOWER(text) LIKE '%utl_%' THEN 1
                     END)    count_dbms_utl,
               COUNT(CASE
                       WHEN LOWER(text) LIKE '%execute%immediate%' THEN 1
                     END)    count_exec_im,
               COUNT(CASE
                       WHEN LOWER(text) LIKE '%dbms_sql%' THEN 1
                     END)    count_dbms_sql,
               COUNT(1)      count_total
        FROM   &v_tblprefix._source a
        WHERE  owner NOT IN
@&EXTRACTSDIR/exclude_schemas.sql
        GROUP  BY '&&v_host'
                  || '_'
                  || '&&v_dbname'
                  || '_'
                  || '&&v_hora',
                  &v_a_con_id ,
                  owner,
                  name,
                  TYPE)
GROUP  BY pkey,
          con_id,
          owner,
          TYPE)
SELECT pkey , con_id , owner , type , sum_nr_lines , qt_objs ,
       sum_nr_lines_w_utl , sum_nr_lines_w_dbms , count_exec_im , count_dbms_sql , sum_nr_lines_w_dbms_utl , sum_count_total
FROM vsrc;
spool off
