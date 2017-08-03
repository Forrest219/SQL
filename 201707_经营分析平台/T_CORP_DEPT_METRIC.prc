CREATE OR REPLACE PROCEDURE T_CORP_DEPT_METRIC IS
  /******************************************************************************
     NAME:       T_CORP_DEPT_METRIC
     PURPOSE:    �洢����ģ�壬ִ��״̬д��t_report_status��
  
     REVISIONS:
     Ver        Date        Author           Description
     ---------  ----------  ---------------  ------------------------------------
     1.0        2017/2/22    hry      1. Created this procedure.
  
     NOTES:
  
     Automatically available Auto Replace Keywords:
        Object Name:     T_CORP_DEPT_METRIC
        Sysdate:         2017/2/22
        Date and Time:   2017/2/22, 10:36:50, and 2017/2/22 10:36:50
        Username:         (set in TOAD Options, Procedure Editor)
        Table Name:       (set in the "New PL/SQL Object" dialog)
  
  ******************************************************************************/

  V_SQLCODE VARCHAR2(4000);
  V_SQLERRM VARCHAR2(4000);
BEGIN
  INSERT INTO T_REPORT_STATUS
    (LNGRSOID,
     STRBILLNAME,
     LNGERPUSERID,
     STRREPORTNAME,
     STATUS,
     APPDEF1,
     CREATIONTIME)
  VALUES
    (UECBI_RESERVE.NEXTVAL,
     'errormsg',
     81,
     'T_CORP_DEPT_METRIC',
     2,
     '�洢����ִ�п�ʼ...',
     SYSDATE);
  COMMIT;

  DELETE FROM T_CORP_DEPT_METRIC@LINKBIDW;
  INSERT INTO T_CORP_DEPT_METRIC@LINKBIDW
    (FY_YEAR,
     PERIOD_MONTH,
     CALENDAR_DATE,
     DEPT_NUM,
     DEPT_NAME,
     ACC_UNIT,
     DATA_SOURCE,
     METRIC_EN,
     METRIC_ZH,
     METRIC_VALUE,
     METRIC_VALUE_PP,
     METRIC_VALUE_YA,
     METRIC_VALUE_YTD,
     METRIC_VALUE_YA_YTD,
     BUDGET_METRIC_VALUE,
     CL_METRIC_VALUE_YTD,
     CL_METRIC_VALUE_YA_YTD,
     UNIT)
  
  /*
  temp_data�洢���м���ռ�������
  
  */
  
    WITH TEMP_DATA AS
     (
      -- 1.��t_manage_receipt���г�ȡָ�꣬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
      SELECT PERIOD_YEAR AS FY_YEAR,
              PERIOD_MONTH,
              TRUNC(PERIOD, 'mm') AS CALENDAR_DATE,
              DECODE(DEPT_NUM, '80101', '10150', DEPT_NUM) AS DEPT_NUM,
              DEPT_NAME_FIRST AS DEPT_NAME,
              DEPT_OWN,
              OU_GROUP_CODE,
              OU_GROUP,
              METRIC_EN,
              NVL(METRIC_VALUE, 0) / 10000 AS METRIC_VALUE,
              't_manage_receipt' AS DATA_SOURCE,
              '��Ԫ' AS UNIT
        FROM (
               /*        
               ��t_manage_receipt�������������롱�ֶΣ���ʽΪ��
               1. ��˾������=����ȷ�Ͻ�receipt_mtd��+ Ӫҵ������(receipt_other)
               
               2. ���ż�����=����ȷ�Ͻ�receipt_mtd��+ ��������ת�����루rec_transfer_otherdept��+���η�������(rec_sin_service)
               +Ӫҵ������(receipt_other)
               
               3. ������=�����루rec_net_dept��+ פ����onsite_service��- �������Ž�����rec_amount_otherdept��        
               */
               SELECT T.PERIOD_YEAR,
                       T.PERIOD_MONTH,
                       TRUNC(T.PERIOD, 'mm') AS PERIOD,
                       T.DEPT_NUM,
                       T.DEPT_NAME_FIRST,
                       T.DEPT_OWN,
                       T.OU_GROUP_CODE,
                       T.OU_GROUP,
                       NVL(T.RECEIPT_MTD, 0) + NVL(T.RECEIPT_OTHER, 0) AS RECEIPT_CORP, --��˾������
                       NVL(T.RECEIPT_MTD, 0) + NVL(T.RECEIPT_OTHER, 0) +
                       NVL(T.REC_TRANSFER_OTHERDEPT, 0) +
                       NVL(T.REC_SIN_SERVICE, 0) AS RECEIPT_CORP_DEPT, --���ż�����
                       NVL(T.REC_NET_DEPT, 0) + NVL(ONSITE_SERVICE, 0) -
                       NVL(T.REC_AMOUNT_OTHERDEPT, 0) AS REC_NET_DEPT --���ż�������
                 FROM T_MANAGE_RECEIPT@LINKBIDW T
                WHERE DEPT_LEVEL = 1) UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(REC_NET_DEPT, --���ż�������
                                                                            RECEIPT_CORP, --��˾������
                                                                            RECEIPT_CORP_DEPT --���ż�����
                                                                            ))
      
      --2.0 ��t_tot_expense���г�ȡָ�꣬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
      UNION ALL
      SELECT TO_NUMBER(FY_YEAR) AS FY_YEAR,
             TO_NUMBER(PERIOD_MONTH) AS PERIOD_MONTH,
             TRUNC(CALENDER_DATE, 'mm') AS CALENDAR_DATE,
             DECODE(DEPT_ID, '80101', '10150', DEPT_ID) AS DEPT_NUM,
             DEPT_NAME,
             DEPT_OWN,
             OU_GROUP_CODE,
             OU_GROUP,
             METRIC_EN,
             NVL(METRIC_VALUE, 0) / 10000 AS METRIC_VALUE,
             't_tot_expense' AS DATA_SOURCE,
             '��Ԫ' AS UNIT
        FROM T_TOT_EXPENSE@LINKBIDW T UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(TOT_AMOUNT)) --�����ܶ�
       WHERE DEPT_LEVEL = 1
      
      --3.0 ��t_manage_control_profit���г�ȡָ�꣬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
      UNION ALL
      SELECT FY_YEAR,
             PERIOD_MONTH,
             TRUNC(CALENDER_DATE, 'mm') AS CALENDAR_DATE,
             DECODE(DEPT_CODE, '80101', '10150', DEPT_CODE) AS DEPT_NUM,
             DEPT_NAME,
             DEPT_OWN,
             OU_GROUP_CODE,
             OU_GROUP,
             METRIC_EN,
             NVL(METRIC_VALUE, 0) / 10000 AS METRIC_VALUE,
             't_manage_control_profit' AS DATA_SOURCE,
             '��Ԫ' AS UNIT
        FROM T_MANAGE_CONTROL_PROFIT@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(CONTROL_PROFIT)) --�ɿؾ���
       WHERE DEPT_HIER = 1
      
      --4.0 ��t_receipt_detail���г�ȡָ�꣬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
      UNION ALL
      SELECT EXTRACT(YEAR FROM ADD_MONTHS(DUE_DATE, -3)) AS FY_YEAR,
             EXTRACT(MONTH FROM ADD_MONTHS(DUE_DATE, -3)) AS PERIOD_MONTH,
             TRUNC(DUE_DATE, 'mm') AS CALENDAR_DATE,
             DECODE(DEPT_CODE_LEVEL1, '80101', '10150', DEPT_CODE_LEVEL1) AS DEPT_NUM,
             DEPT_NAME_LEVEL1 AS DEPT_NAME,
             BELONG_TO AS DEPT_OWN,
             OU_GROUP_CODE,
             OU_GROUP,
             DECODE(METRIC_EN, 'RECEIPT_AMOUNT', 'MONEY_RETURN', METRIC_EN),
             NVL(METRIC_VALUE, 0) / 10000 AS METRIC_VALUE,
             't_receipt_detail' AS DATA_SOURCE,
             '��Ԫ' AS UNIT
        FROM T_RECEIPT_DETAIL@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(RECEIPT_AMOUNT)) --RECEIPT_AMOUNT�ؿ���
      
      --5.0 ��t_manage_contract���г�ȡָ�꣬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
      UNION ALL
      SELECT PERIOD_YEAR AS FY_YEAR,
             PERIOD_MONTH,
             TRUNC(PERIOD, 'mm') AS CALENDAR_DATE,
             DECODE(DEPT_NUM, '80101', '10150', DEPT_NUM) AS DEPT_NUM,
             DEPT_NAME_FIRST AS DEPT_NAME,
             DEPT_OWN,
             OU_GROUP_CODE,
             OU_GROUP,
             METRIC_EN,
             NVL(METRIC_VALUE, 0) / 10000 AS METRIC_VALUE,
             't_manage_contract' AS DATA_SOURCE,
             '��Ԫ' AS UNIT
        FROM T_MANAGE_CONTRACT@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(CONTRACT_AMOUNT, --ǩԼ��
                                                                              SIGN_NET_AMOUNT)) --ǩԼ����
       WHERE DEPT_LEVEL = 1
      
      --6.0 ��t_dept_personinfo_sum���г�ȡָ�꣬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
      UNION ALL
      
      SELECT F_YEAR AS FY_YEAR,
             PERIOD_MONTH AS PERIOD_MONTH,
             TRUNC(CALENDAR_DATE, 'mm') AS CALENDAR_DATE,
             DECODE(DEPT_NUMBER, '80101', '10150', DEPT_NUMBER) AS DEPT_NUM,
             DEPT_NAME,
             BELONG_TO AS DEPT_OWN,
             OU_GROUP_CODE,
             OU_GROUP,
             METRIC_EN,
             NVL(METRIC_VALUE, 0) AS METRIC_VALUE,
             't_dept_personinfo_sum' AS DATA_SOURCE,
             '��' AS UNIT
        FROM (SELECT T.*,
                     NVL(T.STAFF_NUM, 0) + NVL(T.STAFF_NUM_RESIGND, 0) -
                     NVL(T.STAFF_NUM_PERIOD_START, 0) AS STAFF_NUM_NEW_RECRUIT
                FROM T_DEPT_PERSONINFO_SUM@LINKBIDW T
               WHERE LENGTH(DEPT_NUMBER) <= 5) UNPIVOT(METRIC_VALUE FOR METRIC_EN IN( --EXPECT_STAFF_NUM, --Ԥ����ְ����
                                                                                     STAFF_NUM, --��ְ����
                                                                                     NUM_PERSON_TYPE_XS, --���У�����
                                                                                     NUM_PERSON_TYPE_JS, --���У�����
                                                                                     NUM_PERSON_TYPE_GL, --���У�����
                                                                                     STAFF_NUM_PERIOD_START, --�ڳ�����
                                                                                     STAFF_NUM_RESIGND, --��ְ����
                                                                                     STAFF_NUM_NEW_RECRUIT, --����ְ
                                                                                     STAFF_NUM_VACANT)) --�ձ�����
      
      /*
      --7.0 ��t_adjust_manage_receipt���г�ȡָ�꣬���������룬�������ֶ�ֻ����unpivot�������ֶ����Ƽ���
       UNION ALL
       SELECT PERIOD_YEAR AS FY_YEAR,
              PERIOD_MONTH,
              TRUNC(PERIOD, 'mm') AS CALENDAR_DATE,
              DEPT_NUM,
              DEPT_NAME_FIRST AS DEPT_NAME,
              DEPT_OWN,
              OU_GROUP_CODE,
              OU_GROUP,
              METRIC_EN,
              NVL(METRIC_VALUE, 0) / 10000 AS METRIC_VALUE,
              't_manage_receipt/t_adjust_manage_receipt' AS DATA_SOURCE,
              '��Ԫ' AS UNIT
         FROM (SELECT T.PERIOD_YEAR,
                      T.PERIOD_MONTH,
                      TRUNC(T.PERIOD, 'mm') AS PERIOD,
                      T.DEPT_NUM,
                      T.DEPT_NAME_FIRST,
                      T.DEPT_OWN,
                      T.OU_GROUP_CODE,
                      T.OU_GROUP,
                      T.REC_NET_DEPT - T.REC_AMOUNT_OTHERDEPT AS REC_NET_DEPT
                 FROM T_ADJUST_MANAGE_RECEIPT@LINKBIDW T) UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(REC_NET_DEPT)))
                 */
      ),
    
    /*
    temp_data_2�Ƕ�temp_data������ת����Ľ����
    1. ����acc_unit��
    2. ɾ��metric_valueֵΪ�ջ������
    3. ɾ��acc_unitΪ�յ���
    4. ��metric_value�н���group_by��ʹ��ÿ��������ÿ�����㵥Ԫ�н�����һ��
    5. ֻȡ��Ȼ��2015�꼰֮�������
    */
    TEMP_DATA_2 AS
     (SELECT FY_YEAR,
             PERIOD_MONTH,
             CALENDAR_DATE,
             DEPT_NUM,
             DEPT_NAME,
             ACC_UNIT,
             METRIC_EN,
             DATA_SOURCE,
             SUM(METRIC_VALUE) AS METRIC_VALUE,
             UNIT
        FROM (SELECT TEMP_DATA.*,
                     --��dept_num��ou_group��dept_own����decode��ת��Ϊacc_unit
                     DECODE(DEPT_NUM,
                            '10137',
                            '����׳־',
                            '101FW',
                            '������Ѷ',
                            '10150',
                            '�󽡿�ҽ��',
                            DECODE(OU_GROUP,
                                   '��������',
                                   DECODE(DEPT_OWN,
                                          '����',
                                          '����',
                                          '���ֲ���',
                                          '���ֲ���',
                                          NULL��NULL�� 'ƽ̨'),
                                   OU_GROUP)) AS ACC_UNIT
                FROM TEMP_DATA)
      --��������ֵ��acc_unit��Ϊ�յ��У�ɾ��ֵΪ�����acc_unitΪ�յ��У�
       WHERE NVL(METRIC_VALUE, 0) <> 0
         AND ACC_UNIT IS NOT NULL
       GROUP BY FY_YEAR,
                PERIOD_MONTH,
                CALENDAR_DATE,
                DEPT_NUM,
                DEPT_NAME,
                ACC_UNIT,
                METRIC_EN,
                DATA_SOURCE,
                UNIT
      HAVING EXTRACT(YEAR
        FROM CALENDAR_DATE) >= 2015), --ȡ��Ȼ��2015�꼰֮�������
    
    /*
    temp_data_3�ǡ����ꡢ���¡����㵥Ԫ�����ű��롢�������ơ�����Դ����λunit����ɵĵѿ�����
    
    -- ��������Դ����λunit������ѿ�������ԭ����
    1. ָ�������Դ����λunit�Ƕ��һ��ϵ����˲�Ӱ��ѿ������Ľ��
    2. Ϊ�˱�֤����Դ�͵�λunit�е����������
    
    */
    TEMP_DATA_3 AS
     (SELECT T.*,
             T2.PERIOD_MONTH,
             ADD_MONTHS(TO_DATE(T.FY_YEAR || T2.PERIOD_MONTH, 'yyyymm'), 3) AS CALENDAR_DATE
        FROM (SELECT DISTINCT FY_YEAR,
                              DEPT_NUM,
                              DEPT_NAME,
                              ACC_UNIT,
                              DATA_SOURCE,
                              METRIC_EN,
                              UNIT
                FROM TEMP_DATA_2) T,
             (SELECT ROWNUM AS PERIOD_MONTH FROM DUAL CONNECT BY ROWNUM <= 12) T2)
    
    /*
    ����t_corp_dept_metric�����ݣ��߼�Ϊ��
    
    1. �ѿ�����temp_data_3��Ϊ������Դ��������ƥ�佫temp_data_2������ʵ��ֵ������ֵ��ȥ��ͬ��ֵ
    2. ��t_corp_dept_budget��ȡԤ��ֵ
    3. ��t_map_metric_name��ȡָ��������
    4. ͨ��sum-over-partition-by-order-by����
    
    */
    
    SELECT D.FY_YEAR,
           D.PERIOD_MONTH,
           D.CALENDAR_DATE,
           D.DEPT_NUM,
           D.DEPT_NAME,
           D.ACC_UNIT,
           D.DATA_SOURCE,
           D.METRIC_EN,
           D5.METRIC_ZH,
           NVL(D1.METRIC_VALUE, 0) AS METRIC_VALUE,
           NVL(D2.METRIC_VALUE, 0) AS METRIC_VALUE_PP,
           NVL(D3.METRIC_VALUE, 0) AS METRIC_VALUE_YA,
           NVL(SUM(D1.METRIC_VALUE)
               OVER(PARTITION BY D.FY_YEAR,
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY D.PERIOD_MONTH),
               0) AS METRIC_VALUE_YTD, --����YTD--����
           NVL(SUM(D3.METRIC_VALUE)
               OVER(PARTITION BY D.FY_YEAR,
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY D.PERIOD_MONTH),
               0) AS METRIC_VALUE_YA_YTD, --ȥ��YTD--����
           NVL(D4.METRIC_VALUE, 0) AS BUDGET_METRIC_VALUE,
           NVL(SUM(D1.METRIC_VALUE)
               OVER(PARTITION BY EXTRACT(YEAR FROM D.CALENDAR_DATE),
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY EXTRACT(MONTH FROM D.CALENDAR_DATE)),
               0) AS CL_METRIC_VALUE_YTD, --����YTD--��Ȼ��
           NVL(SUM(D3.METRIC_VALUE)
               OVER(PARTITION BY EXTRACT(YEAR FROM D.CALENDAR_DATE),
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY EXTRACT(MONTH FROM D.CALENDAR_DATE)),
               0) AS CL_METRIC_VALUE_YA_YTD, --ȥ��YTD--��Ȼ��
           D.UNIT
    
      FROM TEMP_DATA_3 D
    
      LEFT JOIN TEMP_DATA_2 D1 --ƥ�䵱��ֵ
        ON D.FY_YEAR = D1.FY_YEAR
       AND D.PERIOD_MONTH = D1.PERIOD_MONTH
       AND D.DEPT_NUM = D1.DEPT_NUM
          --       AND D.DEPT_NAME = D1.DEPT_NAME
       AND D.ACC_UNIT = D1.ACC_UNIT
       AND D.DATA_SOURCE = D1.DATA_SOURCE
       AND D.METRIC_EN = D1.METRIC_EN
    
      LEFT JOIN TEMP_DATA_2 D2 --ƥ������ֵ
        ON D.CALENDAR_DATE = ADD_MONTHS(D2.CALENDAR_DATE, 1)
       AND D.DEPT_NUM = D2.DEPT_NUM
          --       AND D.DEPT_NAME = D2.DEPT_NAME
       AND D.ACC_UNIT = D2.ACC_UNIT
       AND D.DATA_SOURCE = D2.DATA_SOURCE
       AND D.METRIC_EN = D2.METRIC_EN
    
      LEFT JOIN TEMP_DATA_2 D3 --ƥ��ȥ��ͬ��ֵ
        ON D.CALENDAR_DATE = ADD_MONTHS(D3.CALENDAR_DATE, 12)
       AND D.DEPT_NUM = D3.DEPT_NUM
          --       AND D.DEPT_NAME = D3.DEPT_NAME
       AND D.ACC_UNIT = D3.ACC_UNIT
       AND D.DATA_SOURCE = D3.DATA_SOURCE
       AND D.METRIC_EN = D3.METRIC_EN
    
      LEFT JOIN T_CORP_DEPT_BUDGET@LINKBIDW D4 --ȡָ���Ԥ��ֵ
        ON D.FY_YEAR = D4.FY_YEAR
       AND D.DEPT_NUM = D4.DEPT_NUM
          --       AND D.DEPT_NAME = D4.DEPT_NAME
       AND D.ACC_UNIT = D4.ACC_UNIT
       AND D.METRIC_EN = D4.METRIC_EN
    
      LEFT JOIN T_MAP_METRIC_NAME D5 --ȡָ���������
        ON D.METRIC_EN = D5.METRIC_EN
    
    --ɾ������������̩�ϼ�ͨ�����롢������ָ��  
     WHERE NOT (D.ACC_UNIT IN ('��������', '̩�ϼ�ͨ') AND
            D.METRIC_EN IN
            ('RECEIPT_CORP_DEPT', 'RECEIPT_NET_DEPT', 'RECEIPT_CORP'))
    
     ORDER BY D.DEPT_NUM,
              D.DEPT_NAME,
              D.ACC_UNIT,
              D.DATA_SOURCE,
              D.METRIC_EN,
              D.FY_YEAR,
              D.PERIOD_MONTH;

  INSERT INTO T_REPORT_STATUS
    (LNGRSOID,
     STRBILLNAME,
     LNGERPUSERID,
     STRREPORTNAME,
     STATUS,
     APPDEF1,
     CREATIONTIME)
  VALUES
    (UECBI_RESERVE.NEXTVAL,
     'errormsg',
     81,
     'T_CORP_DEPT_METRIC',
     2,
     '�洢����ִ�н�����',
     SYSDATE);
  COMMIT;
EXCEPTION

  WHEN OTHERS THEN
    ROLLBACK;
    V_SQLCODE := SQLCODE;
    V_SQLERRM := SQLERRM;
    -- 20160617
    INSERT INTO T_REPORT_STATUS
      (LNGRSOID,
       STRBILLNAME,
       LNGERPUSERID,
       STRREPORTNAME,
       STATUS,
       APPDEF1,
       CREATIONTIME)
    VALUES
      (UECBI_RESERVE.NEXTVAL,
       'errormsg',
       81,
       'T_CORP_DEPT_METRIC',
       2,
       '�洢����ִ��ʱ:' || V_SQLCODE || ';' || V_SQLERRM,
       SYSDATE);
  
    COMMIT;
END T_CORP_DEPT_METRIC;
/
