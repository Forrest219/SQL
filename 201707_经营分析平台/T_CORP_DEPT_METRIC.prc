CREATE OR REPLACE PROCEDURE T_CORP_DEPT_METRIC IS
  /******************************************************************************
     NAME:       T_CORP_DEPT_METRIC
     PURPOSE:    存储过程模板，执行状态写入t_report_status表
  
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
     '存储过程执行开始...',
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
  temp_data存储从中间表收集的数据
  
  */
  
    WITH TEMP_DATA AS
     (
      -- 1.从t_manage_receipt表中抽取指标，增加新字段只需在unpivot中增加字段名称即可
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
              '万元' AS UNIT
        FROM (
               /*        
               在t_manage_receipt表中新增“收入”字段，公式为：
               1. 公司级收入=收入确认金额（receipt_mtd）+ 营业外收入(receipt_other)
               
               2. 部门级收入=收入确认金额（receipt_mtd）+ 其他部门转入收入（rec_transfer_otherdept）+单次服务收入(rec_sin_service)
               +营业外收入(receipt_other)
               
               3. 净收入=净收入（rec_net_dept）+ 驻场（onsite_service）- 其它部门交付（rec_amount_otherdept）        
               */
               SELECT T.PERIOD_YEAR,
                       T.PERIOD_MONTH,
                       TRUNC(T.PERIOD, 'mm') AS PERIOD,
                       T.DEPT_NUM,
                       T.DEPT_NAME_FIRST,
                       T.DEPT_OWN,
                       T.OU_GROUP_CODE,
                       T.OU_GROUP,
                       NVL(T.RECEIPT_MTD, 0) + NVL(T.RECEIPT_OTHER, 0) AS RECEIPT_CORP, --公司级收入
                       NVL(T.RECEIPT_MTD, 0) + NVL(T.RECEIPT_OTHER, 0) +
                       NVL(T.REC_TRANSFER_OTHERDEPT, 0) +
                       NVL(T.REC_SIN_SERVICE, 0) AS RECEIPT_CORP_DEPT, --部门级收入
                       NVL(T.REC_NET_DEPT, 0) + NVL(ONSITE_SERVICE, 0) -
                       NVL(T.REC_AMOUNT_OTHERDEPT, 0) AS REC_NET_DEPT --部门级净收入
                 FROM T_MANAGE_RECEIPT@LINKBIDW T
                WHERE DEPT_LEVEL = 1) UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(REC_NET_DEPT, --部门级净收入
                                                                            RECEIPT_CORP, --公司级收入
                                                                            RECEIPT_CORP_DEPT --部门级收入
                                                                            ))
      
      --2.0 从t_tot_expense表中抽取指标，增加新字段只需在unpivot中增加字段名称即可
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
             '万元' AS UNIT
        FROM T_TOT_EXPENSE@LINKBIDW T UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(TOT_AMOUNT)) --费用总额
       WHERE DEPT_LEVEL = 1
      
      --3.0 从t_manage_control_profit表中抽取指标，增加新字段只需在unpivot中增加字段名称即可
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
             '万元' AS UNIT
        FROM T_MANAGE_CONTROL_PROFIT@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(CONTROL_PROFIT)) --可控净利
       WHERE DEPT_HIER = 1
      
      --4.0 从t_receipt_detail表中抽取指标，增加新字段只需在unpivot中增加字段名称即可
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
             '万元' AS UNIT
        FROM T_RECEIPT_DETAIL@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(RECEIPT_AMOUNT)) --RECEIPT_AMOUNT回款金额
      
      --5.0 从t_manage_contract表中抽取指标，增加新字段只需在unpivot中增加字段名称即可
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
             '万元' AS UNIT
        FROM T_MANAGE_CONTRACT@LINKBIDW UNPIVOT(METRIC_VALUE FOR METRIC_EN IN(CONTRACT_AMOUNT, --签约额
                                                                              SIGN_NET_AMOUNT)) --签约净额
       WHERE DEPT_LEVEL = 1
      
      --6.0 从t_dept_personinfo_sum表中抽取指标，增加新字段只需在unpivot中增加字段名称即可
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
             '人' AS UNIT
        FROM (SELECT T.*,
                     NVL(T.STAFF_NUM, 0) + NVL(T.STAFF_NUM_RESIGND, 0) -
                     NVL(T.STAFF_NUM_PERIOD_START, 0) AS STAFF_NUM_NEW_RECRUIT
                FROM T_DEPT_PERSONINFO_SUM@LINKBIDW T
               WHERE LENGTH(DEPT_NUMBER) <= 5) UNPIVOT(METRIC_VALUE FOR METRIC_EN IN( --EXPECT_STAFF_NUM, --预算在职人数
                                                                                     STAFF_NUM, --在职人数
                                                                                     NUM_PERSON_TYPE_XS, --其中，销售
                                                                                     NUM_PERSON_TYPE_JS, --其中，技术
                                                                                     NUM_PERSON_TYPE_GL, --其中，管理
                                                                                     STAFF_NUM_PERIOD_START, --期初人数
                                                                                     STAFF_NUM_RESIGND, --离职人数
                                                                                     STAFF_NUM_NEW_RECRUIT, --新入职
                                                                                     STAFF_NUM_VACANT)) --空编人数
      
      /*
      --7.0 从t_adjust_manage_receipt表中抽取指标，调整净收入，增加新字段只需在unpivot中增加字段名称即可
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
              '万元' AS UNIT
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
    temp_data_2是对temp_data做以下转换后的结果：
    1. 增加acc_unit列
    2. 删除metric_value值为空或零的行
    3. 删除acc_unit为空的行
    4. 对metric_value列进行group_by，使得每个部门在每个核算单元中仅出现一次
    5. 只取自然年2015年及之后的数据
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
                     --对dept_num、ou_group和dept_own进行decode，转换为acc_unit
                     DECODE(DEPT_NUM,
                            '10137',
                            '西安壮志',
                            '101FW',
                            '荣联数讯',
                            '10150',
                            '大健康医疗',
                            DECODE(OU_GROUP,
                                   '北京荣联',
                                   DECODE(DEPT_OWN,
                                          '本部',
                                          '本部',
                                          '不分部门',
                                          '不分部门',
                                          NULL，NULL， '平台'),
                                   OU_GROUP)) AS ACC_UNIT
                FROM TEMP_DATA)
      --仅保留有值且acc_unit不为空的行（删除值为零或者acc_unit为空的行）
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
        FROM CALENDAR_DATE) >= 2015), --取自然年2015年及之后的数据
    
    /*
    temp_data_3是“财年、财月、核算单元、部门编码、部门名称、数据源、单位unit”组成的笛卡尔积
    
    -- 将“数据源、单位unit”纳入笛卡尔积的原因是
    1. 指标和数据源、单位unit是多对一关系，因此不影响笛卡尔积的结果
    2. 为了保证数据源和单位unit列的数据完成性
    
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
    生成t_corp_dept_metric表数据，逻辑为：
    
    1. 笛卡尔积temp_data_3作为主数据源，左连接匹配将temp_data_2所含的实际值、上月值、去年同期值
    2. 从t_corp_dept_budget中取预算值
    3. 从t_map_metric_name中取指标中文名
    4. 通过sum-over-partition-by-order-by计算
    
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
               0) AS METRIC_VALUE_YTD, --本年YTD--财年
           NVL(SUM(D3.METRIC_VALUE)
               OVER(PARTITION BY D.FY_YEAR,
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY D.PERIOD_MONTH),
               0) AS METRIC_VALUE_YA_YTD, --去年YTD--财年
           NVL(D4.METRIC_VALUE, 0) AS BUDGET_METRIC_VALUE,
           NVL(SUM(D1.METRIC_VALUE)
               OVER(PARTITION BY EXTRACT(YEAR FROM D.CALENDAR_DATE),
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY EXTRACT(MONTH FROM D.CALENDAR_DATE)),
               0) AS CL_METRIC_VALUE_YTD, --本年YTD--自然年
           NVL(SUM(D3.METRIC_VALUE)
               OVER(PARTITION BY EXTRACT(YEAR FROM D.CALENDAR_DATE),
                    D.DEPT_NUM,
                    --                    D.DEPT_NAME,
                    D.ACC_UNIT,
                    D.METRIC_EN ORDER BY EXTRACT(MONTH FROM D.CALENDAR_DATE)),
               0) AS CL_METRIC_VALUE_YA_YTD, --去年YTD--自然年
           D.UNIT
    
      FROM TEMP_DATA_3 D
    
      LEFT JOIN TEMP_DATA_2 D1 --匹配当月值
        ON D.FY_YEAR = D1.FY_YEAR
       AND D.PERIOD_MONTH = D1.PERIOD_MONTH
       AND D.DEPT_NUM = D1.DEPT_NUM
          --       AND D.DEPT_NAME = D1.DEPT_NAME
       AND D.ACC_UNIT = D1.ACC_UNIT
       AND D.DATA_SOURCE = D1.DATA_SOURCE
       AND D.METRIC_EN = D1.METRIC_EN
    
      LEFT JOIN TEMP_DATA_2 D2 --匹配上期值
        ON D.CALENDAR_DATE = ADD_MONTHS(D2.CALENDAR_DATE, 1)
       AND D.DEPT_NUM = D2.DEPT_NUM
          --       AND D.DEPT_NAME = D2.DEPT_NAME
       AND D.ACC_UNIT = D2.ACC_UNIT
       AND D.DATA_SOURCE = D2.DATA_SOURCE
       AND D.METRIC_EN = D2.METRIC_EN
    
      LEFT JOIN TEMP_DATA_2 D3 --匹配去年同期值
        ON D.CALENDAR_DATE = ADD_MONTHS(D3.CALENDAR_DATE, 12)
       AND D.DEPT_NUM = D3.DEPT_NUM
          --       AND D.DEPT_NAME = D3.DEPT_NAME
       AND D.ACC_UNIT = D3.ACC_UNIT
       AND D.DATA_SOURCE = D3.DATA_SOURCE
       AND D.METRIC_EN = D3.METRIC_EN
    
      LEFT JOIN T_CORP_DEPT_BUDGET@LINKBIDW D4 --取指标的预算值
        ON D.FY_YEAR = D4.FY_YEAR
       AND D.DEPT_NUM = D4.DEPT_NUM
          --       AND D.DEPT_NAME = D4.DEPT_NAME
       AND D.ACC_UNIT = D4.ACC_UNIT
       AND D.METRIC_EN = D4.METRIC_EN
    
      LEFT JOIN T_MAP_METRIC_NAME D5 --取指标的中文名
        ON D.METRIC_EN = D5.METRIC_EN
    
    --删除车网互联、泰合佳通的收入、净收入指标  
     WHERE NOT (D.ACC_UNIT IN ('车网互联', '泰合佳通') AND
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
     '存储过程执行结束！',
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
       '存储过程执行时:' || V_SQLCODE || ';' || V_SQLERRM,
       SYSDATE);
  
    COMMIT;
END T_CORP_DEPT_METRIC;
/
