CREATE OR REPLACE VIEW T_V_UP_MANAGE_RECEIPT AS(

--创建人：张星辰
--创建日期：2017-8-1
--创建目的：对t_manage_receipt表进行列转行，并规范维度的命名，提高后期ETL和查询的效率

SELECT PERIOD_YEAR AS FY_YEAR,
       PERIOD_MONTH,
       TRUNC(PERIOD, 'mm') AS CALENDAR_DATE,
       DEPT_NUM,
       DEPT_NAME_FIRST AS DEPT_NAME,
       DEPT_LEVEL,
       DEPT_QUALITY,
       DEPT_OWN,
       OU_GROUP_CODE,
       OU_GROUP,
       METRIC_EN,
       NVL(METRIC_VALUE, 0) AS METRIC_VALUE
  FROM T_MANAGE_RECEIPT@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(B_REC_CHECK_PROFIT,
                                                                       B_REC_INTERNAL,
                                                                       B_REC_INTERNAL_DEPT,
                                                                       B_REC_INTERNAL_OTHERDEPT,
                                                                       B_REC_NET_DEPT,
                                                                       B_RECIEPT_AMOUNT,
                                                                       CON_PROFIT,
                                                                       CONTRACT_AMOUNT,
                                                                       COST_SIN_SERVICE,
                                                                       IN_SOURCE,
                                                                       ONSITE_SERVICE,
                                                                       OUTSOURCE,
                                                                       PROFIT_EXAM,
                                                                       REC_AMOUNT,
                                                                       REC_AMOUNT_DEPT,
                                                                       REC_AMOUNT_OTHERDEPT,
                                                                       REC_NET_DEPT,
                                                                       REC_SIN_SERVICE,
                                                                       REC_TRANSFER_OTHERDEPT,
                                                                       RECEIPT_MTD,
                                                                       RECEIPT_OTHER,
                                                                       RECEIPT_RATE,
                                                                       SALES_NUM,
                                                                       STAFF_NUM)))
