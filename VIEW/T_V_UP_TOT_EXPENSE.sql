CREATE OR REPLACE VIEW T_V_UP_TOT_EXPENSE AS
(
--�����ˣ����ǳ�
--�������ڣ�2017-8-1
--����Ŀ�ģ���t_tot_expense�������ת�У����淶ά�ȵ���������ߺ���ETL�Ͳ�ѯ��Ч��

SELECT FY_YEAR,
       PERIOD_MONTH,
       TRUNC(CALENDER_DATE, 'mm') AS CALENDAR_DATE,
       DEPT_ID AS DEPT_NUM,
       DEPT_NAME,
       DEPT_LEVEL,
       DEPT_QUALITY,
       DEPT_OWN,
       OU_GROUP_CODE,
       OU_GROUP,
       METRIC_EN,
       NVL(METRIC_VALUE, 0) AS METRIC_VALUE
  FROM T_TOT_EXPENSE@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(DEPT_AMOUNT,
                                                                    IT_AMT,
                                                                    MANAGE_ALLOCATE,
                                                                    PERSON_AMT,
                                                                    PUBLIC_AMT,
                                                                    REMUN_AMT,
                                                                    STATION_AMT,
                                                                    TOT_AMOUNT,
                                                                    WELFARE_AMT))
 );
