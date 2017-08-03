SELECT * FROM t_manage_contract@linkbidw
WHERE leader_name IS NULL;

SELECT * FROM py_check FOR UPDATE
ORDER BY table_name;

SELECT * FROM py_check
ORDER BY table_name;

COMMIT;

SELECT * FROM t_report_status;

CREATE TABLE py_check_status
(
db_environment VARCHAR2(200),
table_name VARCHAR2(200),
check_type VARCHAR2(200),
check_result VARCHAR2(200),
error_notes VARCHAR2(1000),
checking_time DATE
);

ALTER TABLE py_check ADD SQL varchar2(500);
COMMIT;

ALTER TABLE py_check RENAME COLUMN SQL TO sql_code;


SELECT * FROM py_check_status;
SELECT budget_profit FROM t_receipt_base@linkbidw;

SELECT * FROM py_check;


