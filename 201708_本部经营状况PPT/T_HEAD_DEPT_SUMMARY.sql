--线下导入表
SELECT * FROM T_DEPT_MAP@LINKBIDW;
SELECT * FROM T_CON_MAP@LINKBIDW;

--*******************工作台********************

--1 费用 t_tot_expense
WITH TEMP_UNION AS
 (SELECT *
    FROM T_V_UP_TOT_EXPENSE
   WHERE OU_GROUP_CODE = '101'
     AND DEPT_OWN = '本部'
  
  --2 人年 t_dept_personinfo_sum
  UNION ALL
  SELECT *
    FROM T_V_UP_DEPT_PERSONINFO_SUM
   WHERE OU_GROUP_CODE = '101'
     AND DEPT_OWN = '本部'
     AND METRIC_EN IN ('ACTUAL_ONJOB_YEAR', 'STAFF_NUM')
  
  --3 收入 t_manage_receipt
  UNION ALL
  SELECT *
    FROM T_V_UP_MANAGE_RECEIPT
   WHERE OU_GROUP_CODE = '101'
     AND DEPT_OWN = '本部'
     AND METRIC_EN IN ('PROFIT_EXAM',
                       'REC_AMOUNT_OTHERDEPT',
                       'REC_TRANSFER_OTHERDEPT',
                       'REC_SIN_SERVICE',
                       'COST_SIN_SERVICE',
                       'IN_SOURCE',
                       'OUTSOURCE',
                       'RECEIPT_OTHER',
                       'REC_NET_DEPT'))
SELECT *
  FROM TEMP_UNION

 ORDER BY CALENDAR_DATE, DEPT_NAME, METRIC_EN;
