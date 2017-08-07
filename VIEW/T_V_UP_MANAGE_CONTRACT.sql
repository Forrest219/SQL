CREATE OR REPLACE VIEW T_V_UP_MANAGE_CONTRACT AS
WITH UNPIVOT_DATA AS   ----1. ��ԭ����ת�У��������Ƿ�Ϊyoy��ʶ���ֶ�
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
         DECODE(INSTR(METRIC_EN_ORI, 'YOY'), 0, 'NO', 'YES') AS IS_YOY, --����ֶΰ���yoy����Ϊyes
         REPLACE(METRIC_EN_ORI, '_YOY') AS METRIC_EN,                   --ɾ���ֶ���������_yoy��ʶ
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

--2. ����yoy���ʣ�yes��no����������ת��
PIVOT_DATA AS
 (SELECT *
    FROM UNPIVOT_DATA PIVOT(SUM(METRIC_VALUE) FOR IS_YOY IN('NO' AS
                                                            METRIC_VALUE,
                                                            'YES' AS
                                                            METRIC_VALUE_YOY))),
--3. ����pivot_data���ά���ֶδ����ѿ���������ȫ�·�
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

--4. cartesianά�ȱ�ƥ��ʵ��ֵ
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
       NVL(T2.METRIC_VALUE, 0) METRIC_VALUE,              --����ֵ
       NVL(T2.METRIC_VALUE_YOY, 0) AS METRIC_VALUE_YOY    --ȥ��ͬ��ֵ
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

�����ˣ����ǳ�
�������ڣ�2017-8-7
����Ŀ�ģ���t_manage_manage_contract�������ת�У����淶ά�ȵ���������ߺ���ETL�Ͳ�ѯ��Ч��
�ӱ�˵����

1. unpivot_data   ��ԭ����ת�У��������Ƿ�Ϊyoy��ʶ���ֶ�
2. pivot_data     ����yoy���ʣ�yes��no����������ת��
3. cartesian      ����pivot_data���ά���ֶδ����ѿ�����
4.����cartesianά�ȱ�ƥ��ʵ��ֵ��metric_value��ʾ����ֵ��metric_value_yoy��ʾȥ��ͬ��ֵ

*/;
