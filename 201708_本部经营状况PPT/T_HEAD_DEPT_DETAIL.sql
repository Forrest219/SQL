/***********ETL�߼�˵��**********

���ߣ����ǳ�
��ʼ�������ڣ�2017/8/1
���������ڣ�2017/8/1

�м����;��
1. temp_sign_base: Ԥ����t_sign_base
2. temp_dept_sign: ����1��2�����Ż���
3. temp_receipt_base: Ԥ����t_receipt_base
4. temp_dept_receipt: ����1��2�����Ż���
5. temp_union: �ϲ������ǩԼ���ݣ���2��4�������
6. temp_cartesian�������ѿ���������ȫ�·ݣ��Ա����YTD
7. ETL���ս����������ȥ��ͬ��ֵ������ֵ��YTD��ͳ�ƽ��

*/

--1. Ԥ����t_sign_base
WITH TEMP_SIGN_BASE AS
 (SELECT FY_YEAR,
         PERIOD_MONTH,
         TRUNC(BOOKED_DATE, 'mm') AS CALENDAR_DATE,
         DEPT_CODE_LEVEL1,
         DEPT_NAME_LEVEL1,
         M_DEPT_CODE_LEVEL2,
         M_DEPT_NAME_LEVEL2,
         DEPT_OWN,
         OU_GROUP_CODE,
         OU_GROUP,
         T2.ORDER_TYPE_NAME,
         T2.NEW_CONTRACT_NAME AS NEW_CONTRACT_TYPE,
         'T_SIGN_BASE' AS DATA_SOURCE,
         CONTRACT_AMOUNT * EXCHANGE_RATE AS CONTRACT_AMOUNT
    FROM T_SIGN_BASE@LINKBIDW T1
    LEFT JOIN (SELECT DISTINCT ORDER_TYPE_NAME, NEW_CONTRACT_NAME
                FROM T_MAP_CONTRACT_TYPE) T2
      ON T1.ORDER_TYPE_NAME = T2.ORDER_TYPE_NAME
   WHERE OU_GROUP_CODE = '101'
     AND DEPT_OWN = '����'
     AND T1.ORDER_TYPE_NAME <> '��ǰִ��'),

--2. ����1��2�����Ż���
TEMP_DEPT_SIGN AS
 (
  --2.1 һ������ǩԼ
  SELECT FY_YEAR,
          PERIOD_MONTH,
          CALENDAR_DATE,
          DEPT_CODE_LEVEL1 AS DEPT_NUM,
          DEPT_NAME_LEVEL1 AS DEPT_NAME,
          '1' AS DEPT_LEVEL,
          DEPT_OWN,
          OU_GROUP_CODE,
          OU_GROUP,
          NEW_CONTRACT_TYPE,
          DATA_SOURCE,
          'CONTRACT_AMOUNT' AS METRIC_EN,
          SUM(CONTRACT_AMOUNT) AS METRIC_VALUE
    FROM TEMP_SIGN_BASE
   GROUP BY FY_YEAR,
             PERIOD_MONTH,
             CALENDAR_DATE,
             DEPT_CODE_LEVEL1,
             DEPT_NAME_LEVEL1,
             DEPT_OWN,
             NEW_CONTRACT_TYPE,
             OU_GROUP_CODE,
             OU_GROUP,
             DATA_SOURCE
  
  UNION ALL
  --2.2 ��������ǩԼ
  SELECT FY_YEAR,
         PERIOD_MONTH,
         CALENDAR_DATE,
         M_DEPT_CODE_LEVEL2 AS DEPT_NUM,
         M_DEPT_NAME_LEVEL2 AS DEPT_NAME,
         '2' AS DEPT_LEVEL,
         DEPT_OWN,
         OU_GROUP_CODE,
         OU_GROUP,
         NEW_CONTRACT_TYPE,
         DATA_SOURCE,
         'CONTRACT_AMOUNT' AS METRIC_EN,
         SUM(CONTRACT_AMOUNT) AS METRIC_VALUE
    FROM TEMP_SIGN_BASE
   WHERE M_DEPT_CODE_LEVEL2 IS NOT NULL
   GROUP BY FY_YEAR,
            PERIOD_MONTH,
            CALENDAR_DATE,
            M_DEPT_CODE_LEVEL2,
            M_DEPT_NAME_LEVEL2,
            DEPT_OWN,
            NEW_CONTRACT_TYPE,
            OU_GROUP_CODE,
            OU_GROUP,
            DATA_SOURCE),

--3. Ԥ����t_receipt_base
TEMP_RECEIPT_BASE AS
 (SELECT FY_YEAR,
         PERIOD_MONTH,
         TRUNC(PERIOD, 'mm') AS CALENDAR_DATE,
         DEPT_CODE_LEVEL1,
         DEPT_NAME_LEVEL1,
         M_DEPT_CODE_LEVEL2,
         M_DEPT_NAME_LEVEL2,
         DEPT_OWN,
         OU_GROUP_CODE,
         OU_GROUP,
         T1.ORDER_TYPE_NAME,
         T2.NEW_CONTRACT_NAME AS NEW_CONTRACT_TYPE,
         'T_RECEIPT_BASE' AS DATA_SOURCE,
         FIN_RECIEPT * EXCHANGE_RATE AS FIN_RECIEPT
    FROM T_RECEIPT_BASE@LINKBIDW T1
    LEFT JOIN (SELECT DISTINCT ORDER_TYPE_NAME, NEW_CONTRACT_NAME
                FROM T_MAP_CONTRACT_TYPE) T2
      ON T1.ORDER_TYPE_NAME = T2.ORDER_TYPE_NAME
   WHERE OU_GROUP_CODE = '101'
     AND DEPT_OWN = '����'),

--4. ����1��2�����Ż���
TEMP_DEPT_RECEIPT AS
 (
  -- 4.1һ����������
  SELECT FY_YEAR,
          PERIOD_MONTH,
          CALENDAR_DATE,
          DEPT_CODE_LEVEL1 AS DEPT_NUM,
          DEPT_NAME_LEVEL1 AS DEPT_NAME,
          '1' AS DEPT_LEVEL,
          DEPT_OWN,
          OU_GROUP_CODE,
          OU_GROUP,
          NEW_CONTRACT_TYPE,
          DATA_SOURCE,
          'RECEIPT_AMOUNT' AS METRIC_EN,
          SUM(FIN_RECIEPT) AS METRIC_VALUE
    FROM TEMP_RECEIPT_BASE T
   GROUP BY FY_YEAR,
             PERIOD_MONTH,
             CALENDAR_DATE,
             DEPT_CODE_LEVEL1,
             DEPT_NAME_LEVEL1,
             DEPT_OWN,
             OU_GROUP_CODE,
             OU_GROUP,
             NEW_CONTRACT_TYPE,
             DATA_SOURCE
  
  UNION ALL
  -- 4.2 ������������
  SELECT FY_YEAR,
         PERIOD_MONTH,
         CALENDAR_DATE,
         M_DEPT_CODE_LEVEL2 AS DEPT_NUM,
         M_DEPT_NAME_LEVEL2 AS DEPT_NAME,
         '2' AS DEPT_LEVEL,
         DEPT_OWN,
         OU_GROUP_CODE,
         OU_GROUP,
         NEW_CONTRACT_TYPE,
         DATA_SOURCE,
         'RECEIPT_AMOUNT' AS METRIC_EN,
         SUM(FIN_RECIEPT) AS METRIC_VALUE
    FROM TEMP_RECEIPT_BASE T
   WHERE M_DEPT_CODE_LEVEL2 IS NOT NULL
   GROUP BY FY_YEAR,
            PERIOD_MONTH,
            CALENDAR_DATE,
            M_DEPT_CODE_LEVEL2,
            M_DEPT_NAME_LEVEL2,
            DEPT_OWN,
            OU_GROUP_CODE,
            OU_GROUP,
            NEW_CONTRACT_TYPE,
            DATA_SOURCE),

--5. �ϲ����ݼ�            
TEMP_UNION AS
 (SELECT *
    FROM TEMP_DEPT_RECEIPT
  UNION ALL
  SELECT * FROM TEMP_DEPT_SIGN),

--6. ����ά�ȵĵѿ�����
TEMP_CARTESIAN AS
 (SELECT DISTINCT FY_YEAR,
                  T2.PERIOD_MONTH,
                  ADD_MONTHS(TO_DATE(T1.FY_YEAR || T2.PERIOD_MONTH, 'yyyymm'),
                             3) AS CALENDAR_DATE,
                  DEPT_NUM,
                  DEPT_NAME,
                  DEPT_LEVEL,
                  DEPT_OWN,
                  OU_GROUP_CODE,
                  OU_GROUP,
                  NEW_CONTRACT_TYPE,
                  DATA_SOURCE,
                  METRIC_EN
    FROM TEMP_UNION T1,
         (SELECT ROWNUM AS PERIOD_MONTH FROM DUAL CONNECT BY ROWNUM <= 12) T2)

--7. �������������ݼ�
SELECT T1.*,
DECODE(T1.METRIC_EN,'CONTRACT_AMOUNT','����˰ǩԼ��','RECEIPT_AMOUNT','����'),
       NVL(T2.METRIC_VALUE, 0) AS METRIC_VALUE,
       NVL(T3.METRIC_VALUE, 0) AS METRIC_VALUE_PP,        --����ֵ
       NVL(T4.METRIC_VALUE, 0) AS METRIC_VALUE_YA,        --ȥ��ͬ��ֵ
       NVL(SUM(T2.METRIC_VALUE) OVER(PARTITION BY T1.FY_YEAR,
                T1.DEPT_NUM,
                T1.DEPT_LEVEL,
                T1.OU_GROUP_CODE,
                T1.NEW_CONTRACT_TYPE,
                T1.DATA_SOURCE,
                T1.METRIC_EN ORDER BY T1.PERIOD_MONTH),
           0) AS METRIC_VALUE_YTD,                        --����YTD
       NVL(SUM(T4.METRIC_VALUE) OVER(PARTITION BY T1.FY_YEAR,
                T1.DEPT_NUM,
                T1.DEPT_LEVEL,
                T1.OU_GROUP_CODE,
                T1.NEW_CONTRACT_TYPE,
                T1.DATA_SOURCE,
                T1.METRIC_EN ORDER BY T1.PERIOD_MONTH),
           0) AS METRIC_VALUE_YA_YTD                      --ȥ��YTD
  FROM TEMP_CARTESIAN T1

--7.1 ƥ�䵱��ֵ
  LEFT JOIN TEMP_UNION T2
    ON T1.CALENDAR_DATE = T2.CALENDAR_DATE
   AND T1.DEPT_NUM = T2.DEPT_NUM
   AND T1.DEPT_LEVEL = T2.DEPT_LEVEL
   AND T1.OU_GROUP_CODE = T2.OU_GROUP_CODE
   AND T1.NEW_CONTRACT_TYPE = T2.NEW_CONTRACT_TYPE
   AND T1.DATA_SOURCE = T2.DATA_SOURCE
   AND T1.METRIC_EN = T2.METRIC_EN

--7.1 ƥ������ֵ
  LEFT JOIN TEMP_UNION T3
    ON T1.CALENDAR_DATE = ADD_MONTHS(T3.CALENDAR_DATE, 1)
   AND T1.DEPT_NUM = T3.DEPT_NUM
   AND T1.DEPT_LEVEL = T3.DEPT_LEVEL
   AND T1.OU_GROUP_CODE = T3.OU_GROUP_CODE
   AND T1.NEW_CONTRACT_TYPE = T3.NEW_CONTRACT_TYPE
   AND T1.DATA_SOURCE = T3.DATA_SOURCE
   AND T1.METRIC_EN = T3.METRIC_EN

--7.3 ƥ��ȥ��ֵ
  LEFT JOIN TEMP_UNION T4
    ON T1.CALENDAR_DATE = ADD_MONTHS(T4.CALENDAR_DATE, 12)
   AND T1.DEPT_NUM = T4.DEPT_NUM
   AND T1.DEPT_LEVEL = T4.DEPT_LEVEL
   AND T1.OU_GROUP_CODE = T4.OU_GROUP_CODE
   AND T1.NEW_CONTRACT_TYPE = T4.NEW_CONTRACT_TYPE
   AND T1.DATA_SOURCE = T4.DATA_SOURCE
   AND T1.METRIC_EN = T4.METRIC_EN

--7.4 �ڴ˴���ETL�������ɸѡ��ά���ֶ���ӱ����t1����t1.fy_year
 
/*
WHERE t1.fy_year = 2017
*/

 ORDER BY T1.DEPT_NAME,
          T1.NEW_CONTRACT_TYPE,
          T1.DEPT_NUM,
          T1.DEPT_LEVEL,
          T1.METRIC_EN,
          T1.CALENDAR_DATE;
