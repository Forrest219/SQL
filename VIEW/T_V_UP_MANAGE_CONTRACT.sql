CREATE OR REPLACE VIEW T_V_UP_MANAGE_CONTRACT AS
WITH UNPIVOT_DATA AS   ----1. 对原表列转行，并增加是否为yoy的识别字段
 (SELECT PERIOD_YEAR AS FY_YEAR,
         PERIOD_MONTH,
         TRUNC(PERIOD, 'mm') AS CALENDAR_DATE,
         DEPT_NUM,
         DEPT_NAME_FIRST AS DEPT_NAME,
         DEPT_LEVEL,
         DEPT_QUALITY,
         DEPT_OWN,
         OU_GROUP_CODE,
         OU_GROUP,
         --  METRIC_EN_ORI,
         DECODE(INSTR(METRIC_EN_ORI, 'YOY'), 0, 'NO', 'YES') AS IS_YOY, --如果字段包含yoy，则为yes
         REPLACE(METRIC_EN_ORI, '_YOY') AS METRIC_EN,                   --删除字段中所含的_yoy标识
         NVL(METRIC_VALUE, 0) AS METRIC_VALUE
    FROM T_MANAGE_CONTRACT@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN_ORI IN(CON_AMOUNT,
                                                                              CON_AMOUNT_DEPT,
                                                                              CON_AMOUNT_OTHERDEPT,
                                                                              CON_PROFIT,
                                                                              CONTRACT_AMOUNT,
                                                                              INNER_RECEIPT,
                                                                              ONSITE_SERVICE,
                                                                              SIGN_NET_AMOUNT,
                                                                              CON_AMOUNT_YOY,
                                                                              CON_AMOUNT_DEPT_YOY,
                                                                              CON_AMOUNT_OTHERDEPT_YOY,
                                                                              CON_PROFIT_YOY,
                                                                              CONTRACT_AMOUNT_YOY,
                                                                              INNER_RECEIPT_YOY,
                                                                              ONSITE_SERVICE_YOY,
                                                                              SIGN_NET_AMOUNT_YOY))
   WHERE NVL(METRIC_VALUE, 0) <> 0),

--2. 根据yoy性质（yes或no），进行行转列
PIVOT_DATA AS
 (SELECT *
    FROM UNPIVOT_DATA PIVOT(SUM(METRIC_VALUE) FOR IS_YOY IN('NO' AS
                                                            METRIC_VALUE,
                                                            'YES' AS
                                                            METRIC_VALUE_YOY))),
--3. 根据pivot_data表的维度字段创建笛卡尔积，补全月份
CARTESIAN AS
 (SELECT T1.*,
         T2.PERIOD_MONTH,
         ADD_MONTHS(TO_DATE(T1.FY_YEAR || T2.PERIOD_MONTH, 'yyyymm'), 3) AS CALENDAR_DATE
    FROM (SELECT DISTINCT FY_YEAR,
                          DEPT_NUM,
                          DEPT_NAME,
                          DEPT_LEVEL,
                          DEPT_QUALITY,
                          DEPT_OWN,
                          OU_GROUP_CODE,
                          OU_GROUP,
                          METRIC_EN
            FROM PIVOT_DATA) T1,
         (SELECT ROWNUM AS PERIOD_MONTH FROM DUAL CONNECT BY ROWNUM <= 12) T2)

--4. cartesian维度表匹配实际值
SELECT T1.FY_YEAR,
       T1.PERIOD_MONTH,
       T1.DEPT_NUM,
       T1.DEPT_NAME,
       T1.DEPT_LEVEL,
       T1.DEPT_QUALITY,
       T1.DEPT_OWN,
       T1.OU_GROUP_CODE,
       T1.OU_GROUP,
       T1.METRIC_EN,
       NVL(T2.METRIC_VALUE, 0) METRIC_VALUE,              --当月值
       NVL(T2.METRIC_VALUE_YOY, 0) AS METRIC_VALUE_YOY    --去年同期值
  FROM CARTESIAN T1
  LEFT JOIN PIVOT_DATA T2
    ON T1.CALENDAR_DATE = T2.CALENDAR_DATE
   AND T1.DEPT_NUM = T2.DEPT_NUM
      --   AND t1.dept_name = t2.dept_name
   AND T1.DEPT_LEVEL = T2.DEPT_LEVEL
   AND T1.OU_GROUP_CODE = T2.OU_GROUP_CODE
      --  AND T1.DEPT_OWN = T2.DEPT_OWN
   AND T1.METRIC_EN = T2.METRIC_EN
 ORDER BY T1.OU_GROUP_CODE, T1.DEPT_NUM, T1.METRIC_EN, T1.CALENDAR_DATE

/*

创建人：张星辰
创建日期：2017-8-7
创建目的：对t_manage_manage_contract表进行列转行，并规范维度的命名，提高后期ETL和查询的效率
子表说明：

1. unpivot_data   对原表列转行，并增加是否为yoy的识别字段
2. pivot_data     根据yoy性质（yes或no），进行行转列
3. cartesian      根据pivot_data表的维度字段创建笛卡尔积
4.根据cartesian维度表匹配实际值，metric_value表示当月值，metric_value_yoy表示去年同期值

*/;
