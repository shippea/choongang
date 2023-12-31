/*
  * 예외 (Exception)
  * - 시스템예외, 사용자정의예외로 구분
  * - 예외처리 문법
  * EXCEPTION
  * WHEN 예외명 THEN
  * 예외처리 구문들...
  * WHEN 예외명 THEN
  * 예외처리 구문들...; *
 */

DECLARE
	VI_NUM NUMBER := 0;
BEGIN
	VI_NUM := 10/0;	-- 0으로 나누는 예외 발생
	-- OTHERS : 전체 시스템 예외
	EXCEPTION WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('예외가 발생함!');
END;

/*
  * SQLCODE : 예외코드번호
  * SQLERRM : 예외메세지
 */

CREATE OR REPLACE PROCEDURE EX_TEST1
IS
	VI_NUM NUMBER := 0;
BEGIN
	-- 실행시간에 알 수 있는 런타임예외
	VI_NUM := 10 / 0;	-- DEVIDE BY ZERO EXCEPTION
	DBMS_OUTPUT.PUT_LINE('Success');
	EXCEPTION
		WHEN ZERO_DIVIDE THEN
			DBMS_OUTPUT.PUT_LINE('ZERO_DIVIDE 예외 발생!');
			-- 예외코드
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			-- 예외메시지
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
			-- 예외발생줄번호
			DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);		
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('예외 발생!');
			-- 예외코드
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			-- 예외메시지
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
			-- 예외발생줄번호
			DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;

CALL EX_TEST1();

/*
  * 사용자 정의 예외 (USER DEFINED EXCEPTION)
  * - 사용자가 만들어서 필요할때 사용하는 예외, 주로 로직의 예외상황들을 처리하기 위해 사용됨
  * - 로직의 예외상황 (잘못된 입력/수정/삭제 등등...)
 */
CREATE OR REPLACE PROCEDURE EX_TEST2(
	P_EMPID EMPLOYEES.EMPLOYEE_ID%TYPE
)
IS
	V_DEPTID EMPLOYEES.DEPARTMENT_ID%TYPE;
	EX_DEPTID EXCEPTION;	-- 사용자예외 선언
BEGIN
	SELECT DEPARTMENT_ID
	INTO V_DEPTID
	FROM EMPLOYEES
	WHERE EMPLOYEE_ID = P_EMPID;
	IF V_DEPTID < 100 THEN
		RAISE EX_DEPTID;	-- 사용자예외 발생
	END IF;
	-- 사용자예외 처리
	EXCEPTION
		WHEN EX_DEPTID THEN
			DBMS_OUTPUT.PUT_LINE('부서번호가 100보다 작다!');
END;

BEGIN
	EX_TEST2(110);
END;

-- [실습 : 사용자정의예외]
-- 부서아이디를 입력했을때 매니져아이디가 없다면 '매니져아이디가 없습니다!' 라는
-- 메세지를 예외처리를 통해 출력하는 프로시져를 작성해 봅시다!

CREATE OR REPLACE PROCEDURE EX_TEST3(
	P_DEPTID DEPARTMENTS.DEPARTMENT_ID%TYPE
)
IS
	V_MNGID DEPARTMENTS.MANAGER_ID%TYPE;
	EX_MNGID EXCEPTION;	-- 사용자예외 선언
BEGIN
	SELECT MANAGER_ID
	INTO V_MNGID
	FROM DEPARTMENTS
	WHERE DEPARTMENT_ID = P_DEPTID;
	IF V_MNGID IS NULL THEN
		RAISE EX_MNGID;	-- 사용자예외 발생
	END IF;
	-- 사용자예외 처리
	EXCEPTION
		WHEN EX_MNGID THEN
			DBMS_OUTPUT.PUT_LINE('매니져 아이디가 없습니다!');
END;

BEGIN
	EX_TEST3(200);
END;

SELECT * FROM DEPARTMENTS d ;

CREATE TABLE ACCOUNT(
	ACCID NUMBER PRIMARY KEY,
	ACCNAME VARCHAR2(100) NOT NULL,
	ACCAMOUNT NUMBER DEFAULT 0
);
CREATE SEQUENCE SEQ_ACCOUNT;
INSERT INTO ACCOUNT VALUES (SEQ_ACCOUNT.NEXTVAL, '톰', 10000);
INSERT INTO ACCOUNT VALUES (SEQ_ACCOUNT.NEXTVAL, '제리', 5000);
COMMIT;
CREATE TABLE ACCTRAN(
	ATID NUMBER PRIMARY KEY,
	ATFROM NUMBER,
	ATTO NUMBER,
	ATAMOUNT NUMBER
);
CREATE SEQUENCE SEQ_ACCTRAN;

-- [실습 : 입출금 프로시져]
-- 입금프로시져 : ACC_DEPOSIT(입금자ID, 입금액)
-- 출금프로시져 : ACC_WITHDRAW(출금자ID, 출금액)

CREATE OR REPLACE PROCEDURE ACC_DEPOSIT(
	P_ATID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT  ACCOUNT.ACCAMOUNT%TYPE	
)
IS
BEGIN
	PROC_CHECK_EXIST_ACCID(P_ATID);
	UPDATE ACCOUNT
	SET ACCAMOUNT = ACCAMOUNT + P_ACCAMOUNT
	WHERE ACCID = P_ATID;
END;

CREATE OR REPLACE PROCEDURE ACC_WITHDRAW(
	P_ATID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT  ACCOUNT.ACCAMOUNT%TYPE	
)
IS
BEGIN
	UPDATE ACCOUNT
	SET ACCAMOUNT = ACCAMOUNT - P_ACCAMOUNT
	WHERE ACCID = P_ATID;
END;

BEGIN
	ACC_DEPOSIT(1, 1000);
	ACC_WITHDRAW(2, 500);
END;

SELECT * FROM ACCOUNT;

-- [실습] 톰의 계좌는 10000원으로 제리의 계좌는 5000원으로
--          초기화 하는 프로시져 ACC_INIT
CREATE OR REPLACE PROCEDURE ACC_INIT
IS
BEGIN
	UPDATE ACCOUNT
	SET ACCAMOUNT = 10000
	WHERE ACCID = 1;
	UPDATE ACCOUNT
	SET ACCAMOUNT = 5000
	WHERE ACCID = 2;
	COMMIT;
END;

CALL ACC_INIT();

SELECT * FROM ACCOUNT;

-- [실습 : 출금시에 출금액이 모자라면 예외처리 하도록 출금프로시져를 변경]
CREATE OR REPLACE PROCEDURE ACC_WITHDRAW(
	P_ATID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT  ACCOUNT.ACCAMOUNT%TYPE	
)
IS
	V_ACCAMOUNT ACCOUNT.ACCAMOUNT%TYPE;
	EX_NOT_ENOUGH_MONEY EXCEPTION;
BEGIN
	PROC_CHECK_EXIST_ACCID(P_ATID);
	SELECT ACCAMOUNT
	INTO V_ACCAMOUNT
	FROM ACCOUNT
	WHERE ACCID = P_ATID;
	IF P_ACCAMOUNT > V_ACCAMOUNT THEN
		RAISE EX_NOT_ENOUGH_MONEY;
	END IF;
	UPDATE ACCOUNT
	SET ACCAMOUNT = ACCAMOUNT - P_ACCAMOUNT
	WHERE ACCID = P_ATID;
	EXCEPTION WHEN EX_NOT_ENOUGH_MONEY THEN
		DBMS_OUTPUT.PUT_LINE('잔액이 부족합니다.');
END;

BEGIN
	ACC_WITHDRAW(2, 10000);
END;

-- [실습] 계정아이디가 존재할때만 입출금이 가능하도록 입금프로시져, 출금프로시져를 변경
CREATE OR REPLACE PROCEDURE PROC_CHECK_EXIST_ACCID(
	P_ACCID ACCOUNT.ACCID%TYPE
)
IS
	V_ACCID ACCOUNT.ACCID%TYPE;
	EX_ACCID_NOT_EXIST EXCEPTION;
BEGIN
	SELECT COUNT(*)
	INTO V_ACCID
	FROM ACCOUNT
	WHERE ACCID = P_ACCID;
	IF V_ACCID = 0 THEN
		RAISE EX_ACCID_NOT_EXIST;
	END IF;
	EXCEPTION WHEN EX_ACCID_NOT_EXIST THEN
		DBMS_OUTPUT.PUT_LINE('해당 계정은 없는 계정입니다!');
END;

BEGIN
	ACC_WITHDRAW(5,10000);
END;

-- 이체 프로시져
CREATE OR REPLACE PROCEDURE ACC_TRAN(
	P_SENDERID ACCOUNT.ACCID%TYPE,
	P_RECEIVERID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT ACCOUNT.ACCAMOUNT%TYPE
)
IS
	EX_OVER_ACCAMOUNT EXCEPTION;
BEGIN
	IF P_ACCAMOUNT>50000 THEN
		RAISE EX_OVER_ACCAMOUNT;
	END IF;
	-- 송신자의 계좌에서 출금
	ACC_WITHDRAW(P_SENDERID, P_ACCAMOUNT);
	-- 수신자의 계좌에 입금
	ACC_DEPOSIT(P_RECEIVERID, P_ACCAMOUNT);
	COMMIT;
	EXCEPTION
		WHEN EX_OVER_ACCAMOUNT THEN
			DBMS_OUTPUT.PUT_LINE('이체한도 초과!');
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('이체 실패!');
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		ROLLBACK;
END;

CALL ACC_TRAN(2, 1, 30000);

-- [실습] 1회 이체한도는 50000

-- [실습] 잔액이 없어도 송금이 되는 문제 해결
































/*
  * 예외 (Exception)
  * - 시스템예외, 사용자정의예외로 구분
  * - 예외처리 문법
  * EXCEPTION
  * WHEN 예외명 THEN
  * 예외처리 구문들...
  * WHEN 예외명 THEN
  * 예외처리 구문들...; *
 */

DECLARE
	VI_NUM NUMBER := 0;
BEGIN
	VI_NUM := 10/0;	-- 0으로 나누는 예외 발생
	-- OTHERS : 전체 시스템 예외
	EXCEPTION WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('예외가 발생함!');
END;

/*
  * SQLCODE : 예외코드번호
  * SQLERRM : 예외메세지
 */

CREATE OR REPLACE PROCEDURE EX_TEST1
IS
	VI_NUM NUMBER := 0;
BEGIN
	-- 실행시간에 알 수 있는 런타임예외
	VI_NUM := 10 / 0;	-- DEVIDE BY ZERO EXCEPTION
	DBMS_OUTPUT.PUT_LINE('Success');
	EXCEPTION
		WHEN ZERO_DIVIDE THEN
			DBMS_OUTPUT.PUT_LINE('ZERO_DIVIDE 예외 발생!');
			-- 예외코드
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			-- 예외메시지
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
			-- 예외발생줄번호
			DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);		
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('예외 발생!');
			-- 예외코드
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			-- 예외메시지
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
			-- 예외발생줄번호
			DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
END;

CALL EX_TEST1();

/*
  * 사용자 정의 예외 (USER DEFINED EXCEPTION)
  * - 사용자가 만들어서 필요할때 사용하는 예외, 주로 로직의 예외상황들을 처리하기 위해 사용됨
  * - 로직의 예외상황 (잘못된 입력/수정/삭제 등등...)
 */
CREATE OR REPLACE PROCEDURE EX_TEST2(
	P_EMPID EMPLOYEES.EMPLOYEE_ID%TYPE
)
IS
	V_DEPTID EMPLOYEES.DEPARTMENT_ID%TYPE;
	EX_DEPTID EXCEPTION;	-- 사용자예외 선언
BEGIN
	SELECT DEPARTMENT_ID
	INTO V_DEPTID
	FROM EMPLOYEES
	WHERE EMPLOYEE_ID = P_EMPID;
	IF V_DEPTID < 100 THEN
		RAISE EX_DEPTID;	-- 사용자예외 발생
	END IF;
	-- 사용자예외 처리
	EXCEPTION
		WHEN EX_DEPTID THEN
			DBMS_OUTPUT.PUT_LINE('부서번호가 100보다 작다!');
END;

BEGIN
	EX_TEST2(110);
END;

-- [실습 : 사용자정의예외]
-- 부서아이디를 입력했을때 매니져아이디가 없다면 '매니져아이디가 없습니다!' 라는
-- 메세지를 예외처리를 통해 출력하는 프로시져를 작성해 봅시다!

CREATE OR REPLACE PROCEDURE EX_TEST3(
	P_DEPTID DEPARTMENTS.DEPARTMENT_ID%TYPE
)
IS
	V_MNGID DEPARTMENTS.MANAGER_ID%TYPE;
	EX_MNGID EXCEPTION;	-- 사용자예외 선언
BEGIN
	SELECT MANAGER_ID
	INTO V_MNGID
	FROM DEPARTMENTS
	WHERE DEPARTMENT_ID = P_DEPTID;
	IF V_MNGID IS NULL THEN
		RAISE EX_MNGID;	-- 사용자예외 발생
	END IF;
	-- 사용자예외 처리
	EXCEPTION
		WHEN EX_MNGID THEN
			DBMS_OUTPUT.PUT_LINE('매니져 아이디가 없습니다!');
END;

BEGIN
	EX_TEST3(200);
END;

SELECT * FROM DEPARTMENTS d ;

CREATE TABLE ACCOUNT(
	ACCID NUMBER PRIMARY KEY,
	ACCNAME VARCHAR2(100) NOT NULL,
	ACCAMOUNT NUMBER DEFAULT 0
);
CREATE SEQUENCE SEQ_ACCOUNT;
INSERT INTO ACCOUNT VALUES (SEQ_ACCOUNT.NEXTVAL, '톰', 10000);
INSERT INTO ACCOUNT VALUES (SEQ_ACCOUNT.NEXTVAL, '제리', 5000);
COMMIT;
CREATE TABLE ACCTRAN(
	ATID NUMBER PRIMARY KEY,
	ATFROM NUMBER,
	ATTO NUMBER,
	ATAMOUNT NUMBER
);
CREATE SEQUENCE SEQ_ACCTRAN;

-- [실습 : 입출금 프로시져]
-- 입금프로시져 : ACC_DEPOSIT(입금자ID, 입금액)
-- 출금프로시져 : ACC_WITHDRAW(출금자ID, 출금액)

CREATE OR REPLACE PROCEDURE ACC_DEPOSIT(
	P_ATID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT  ACCOUNT.ACCAMOUNT%TYPE	
)
IS
BEGIN
	PROC_CHECK_EXIST_ACCID(P_ATID);
	UPDATE ACCOUNT
	SET ACCAMOUNT = ACCAMOUNT + P_ACCAMOUNT
	WHERE ACCID = P_ATID;
END;

CREATE OR REPLACE PROCEDURE ACC_WITHDRAW(
	P_ATID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT  ACCOUNT.ACCAMOUNT%TYPE	
)
IS
BEGIN
	UPDATE ACCOUNT
	SET ACCAMOUNT = ACCAMOUNT - P_ACCAMOUNT
	WHERE ACCID = P_ATID;
END;

BEGIN
	ACC_DEPOSIT(1, 1000);
	ACC_WITHDRAW(2, 500);
END;

SELECT * FROM ACCOUNT;

-- [실습] 톰의 계좌는 10000원으로 제리의 계좌는 5000원으로
--          초기화 하는 프로시져 ACC_INIT
CREATE OR REPLACE PROCEDURE ACC_INIT
IS
BEGIN
	UPDATE ACCOUNT
	SET ACCAMOUNT = 10000
	WHERE ACCID = 1;
	UPDATE ACCOUNT
	SET ACCAMOUNT = 5000
	WHERE ACCID = 2;
	COMMIT;
END;

CALL ACC_INIT();

SELECT * FROM ACCOUNT;

-- [실습 : 출금시에 출금액이 모자라면 예외처리 하도록 출금프로시져를 변경]
CREATE OR REPLACE PROCEDURE ACC_WITHDRAW(
	P_ATID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT ACCOUNT.ACCAMOUNT%TYPE,
	P_ISWITHDRAW OUT CHAR
)
IS
	V_ACCAMOUNT ACCOUNT.ACCAMOUNT%TYPE;
	EX_NOT_ENOUGH_MONEY EXCEPTION;
BEGIN
	PROC_CHECK_EXIST_ACCID(P_ATID);
	SELECT ACCAMOUNT
	INTO V_ACCAMOUNT
	FROM ACCOUNT
	WHERE ACCID = P_ATID;
	IF P_ACCAMOUNT > V_ACCAMOUNT THEN
		RAISE EX_NOT_ENOUGH_MONEY;
	END IF;
	UPDATE ACCOUNT
	SET ACCAMOUNT = ACCAMOUNT - P_ACCAMOUNT
	WHERE ACCID = P_ATID;
	P_ISWITHDRAW := 'Y';
	EXCEPTION WHEN EX_NOT_ENOUGH_MONEY THEN
		DBMS_OUTPUT.PUT_LINE('잔액이 부족합니다.');
		P_ISWITHDRAW := 'N';
END;

BEGIN
	ACC_WITHDRAW(2, 10000);
END;

-- [실습] 계정아이디가 존재할때만 입출금이 가능하도록 입금프로시져, 출금프로시져를 변경
CREATE OR REPLACE PROCEDURE PROC_CHECK_EXIST_ACCID(
	P_ACCID ACCOUNT.ACCID%TYPE
)
IS
	V_ACCID ACCOUNT.ACCID%TYPE;
	EX_ACCID_NOT_EXIST EXCEPTION;
BEGIN
	SELECT COUNT(*)
	INTO V_ACCID
	FROM ACCOUNT
	WHERE ACCID = P_ACCID;
	IF V_ACCID = 0 THEN
		RAISE EX_ACCID_NOT_EXIST;
	END IF;
	EXCEPTION WHEN EX_ACCID_NOT_EXIST THEN
		DBMS_OUTPUT.PUT_LINE('해당 계정은 없는 계정입니다!');
END;

BEGIN
	ACC_WITHDRAW(5,10000);
END;

-- 이체 프로시져
CREATE OR REPLACE PROCEDURE ACC_TRAN(
	P_SENDERID ACCOUNT.ACCID%TYPE,
	P_RECEIVERID ACCOUNT.ACCID%TYPE,
	P_ACCAMOUNT ACCOUNT.ACCAMOUNT%TYPE
)
IS
	EX_OVER_ACCAMOUNT EXCEPTION;
	V_ISWITHDRAW CHAR(1);
BEGIN
	IF P_ACCAMOUNT>50000 THEN
		RAISE EX_OVER_ACCAMOUNT;
	END IF;
	-- 송신자의 계좌에서 출금
	ACC_WITHDRAW(P_SENDERID, P_ACCAMOUNT, V_ISWITHDRAW);
	IF V_ISWITHDRAW = 'Y' THEN
		-- 수신자의 계좌에 입금
		ACC_DEPOSIT(P_RECEIVERID, P_ACCAMOUNT);
		COMMIT;
	ELSE
		ROLLBACK;
	END IF;
	EXCEPTION
		WHEN EX_OVER_ACCAMOUNT THEN
			DBMS_OUTPUT.PUT_LINE('이체한도 초과!');
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('이체 실패!');
			DBMS_OUTPUT.PUT_LINE(SQLCODE);
			DBMS_OUTPUT.PUT_LINE(SQLERRM);
		ROLLBACK;
END;

CALL ACC_TRAN(2, 1, 30000);

-- [실습] 1회 이체한도는 50000

-- [실습] 잔액이 없어도 송금이 되는 문제 해결