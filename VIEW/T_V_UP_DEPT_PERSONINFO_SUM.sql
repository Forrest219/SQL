CREATE OR REPLACE VIEW T_V_UP_DEPT_PERSONINFO_SUM AS
(

--创建人：张星辰
--创建日期：2017-8-1
--创建目的：对t_dept_personinfo_sum表进行列转行，并规范维度的命名，提高后期ETL和查询的效率

SELECT F_YEAR AS FY_YEAR,
       PERIOD_MONTH,
       CALENDAR_DATE,
       DEPT_NUMBER AS DEPT_NUM,
       DEPT_NAME,
       DECODE(SIGN(LENGTH(DEPT_NUMBER) - 5), 1, 2, 1) AS DEPT_LEVEL, --sign函数返回-1 , 0 , 1分别标识小于、等于、大于
       DEPT_ATTR AS DEPT_QUALITY,
       BELONG_TO AS DEPT_OWN,
       OU_GROUP_CODE,
       OU_GROUP,
       METRIC_EN,
       NVL(METRIC_VALUE, 0) AS METRIC_VALUE
  FROM T_DEPT_PERSONINFO_SUM@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(ACTUAL_ONJOB_MONTH,
                                                                            ACTUAL_ONJOB_YEAR,
                                                                            EXPECT_ACTUAL_ONJOB_YEAR,
                                                                            EXPECT_STAFF_NUM,
                                                                            NUM_PERSON_TYPE_GL,
                                                                            NUM_PERSON_TYPE_JS,
                                                                            NUM_PERSON_TYPE_XS,
                                                                            ONJOB_PERSON_TYPE_GL,
                                                                            ONJOB_PERSON_TYPE_JS,
                                                                            ONJOB_PERSON_TYPE_XS,
                                                                            RESIGN_RATE,
                                                                            STAFF_NUM,
                                                                            STAFF_NUM_RESIGND,
                                                                            STAFF_NUM_VACANT)));
