DROP TABLE ReadOnly;
DROP TABLE Privileged;
DROP TABLE AccessTable;
DROP TABLE LoginCredentials;

DROP TABLE Industry;
DROP TABLE IndustryTrend;
DROP TABLE TrendInput;

DROP TABLE CompanyName;
DROP TABLE CompanyData;
DROP TABLE DataInput;

DROP TABLE Employee_Input;
DROP TABLE Employee;


CREATE TABLE Employee (
Employee_id DECIMAL(12) NOT NULL PRIMARY KEY,
FirstName VARCHAR(255) NOT NULL,
LastName VARCHAR(255) NOT NULL
);

CREATE TABLE LoginCredentials (
Username VARCHAR(64) NOT NULL PRIMARY KEY,
Password VARCHAR(24) NOT NULL,
employee_id DECIMAL(12) NOT NULL,
FOREIGN KEY (employee_id) REFERENCES Employee(Employee_id)
);

CREATE TABLE AccessTable (
AccessYN char(1) NULL PRIMARY KEY,
Username VARCHAR(64) NOT NULL,
FOREIGN KEY (Username) REFERENCES LoginCredentials(Username)
);

CREATE TABLE ReadOnly (
Username VARCHAR(64) NOT NULL PRIMARY KEY,
FOREIGN KEY (Username) REFERENCES LoginCredentials(Username)
);

CREATE TABLE Privileged (
Username VARCHAR(64) NOT NULL PRIMARY KEY,
FOREIGN KEY (Username) REFERENCES LoginCredentials(Username)
);

CREATE TABLE Employee_Input (
Input_ID DECIMAL(12) NOT NULL PRIMARY KEY,
Employee_ID DECIMAL(12) NOT NULL,
FOREIGN KEY (Employee_ID) REFERENCES Employee(Employee_ID)
);

CREATE TABLE DataInput (
Input_ID DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY (Input_ID) REFERENCES Employee_Input(Input_ID)
);

CREATE TABLE TrendInput (
Input_ID DECIMAL(12) NOT NULL PRIMARY KEY,
FOREIGN KEY (Input_ID) REFERENCES Employee_Input(Input_ID)
);

CREATE TABLE IndustryTrend (
TrendID DECIMAL(12) NOT NULL PRIMARY KEY,
Input_ID DECIMAL(12) NOT NULL,
Industry_ID DECIMAL(12) NOT NULL,
FOREIGN KEY (Input_ID) REFERENCES TrendInput(Input_ID)
);

CREATE TABLE Industry (
IndustryName VARCHAR(64) NOT NULL PRIMARY KEY,
TrendID DECIMAL(12) NOT NULL,
FOREIGN KEY (TrendID) REFERENCES IndustryTrend(TrendID)
);

CREATE TABLE CompanyData (
Company_ID DECIMAL(12) NOT NULL PRIMARY KEY,
Input_ID DECIMAL(12) NOT NULL,
CompanyReputation DECIMAL(2,2) NOT NULL,
CompanyProducts DECIMAL(2,2) NOT NULL,
CompanyLeadership DECIMAL(2,2) NOT NULL,
FOREIGN KEY (Input_ID) REFERENCES DataInput(Input_ID)
);

CREATE TABLE CompanyName (
CompanyName VARCHAR(255) NOT NULL PRIMARY KEY,
Company_ID DECIMAL(12) NOT NULL,
HomeCountry VARCHAR(64) NOT NULL,
FOREIGN KEY (Company_ID) REFERENCES CompanyData(Company_ID)
);

CREATE UNIQUE INDEX UsernameIDX
ON AccessTable(Username);

CREATE UNIQUE INDEX Employee_ID_IDX
ON Employee_Input(Employee_ID); --removed this index so one employee can have multiple data inputs

CREATE UNIQUE INDEX TrendID_IDX
ON Industry(TrendID);

CREATE UNIQUE INDEX Company_ID_IDX
ON CompanyName(Company_ID);

CREATE UNIQUE INDEX Input_ID_IDX
ON IndustryTrend(Input_ID);
---
CREATE INDEX HomeCountry_IDX
ON CompanyName(HomeCountry);

CREATE INDEX LastName_IDX
ON Employee(LastName);

CREATE INDEX CompanyLeadership_IDX
ON CompanyData(CompanyLeadership);
-------
CREATE OR REPLACE PROCEDURE EmployeeInfo(Employee_id IN DECIMAL, FirstName IN VARCHAR, LastName IN VARCHAR)
AS
BEGIN
 INSERT INTO Employee(Employee_id, FirstName, LastName)
 VALUES(Employee_id, FirstName, LastName);
END;


--user info use case
CREATE OR REPLACE PROCEDURE UserInput(Employee_id IN DECIMAL, input_id IN DECIMAL)
AS
BEGIN
 INSERT INTO Employee_Input(Employee_id, input_id)
 VALUES(Employee_id, input_id);
END;

BEGIN 
    EmployeeInfo(1001, 'John', 'Smith');
    COMMIT;
END;

BEGIN
    EmployeeInfo(1002, 'Davy', 'Jones');
END;

BEGIN
    UserInput(1001, 5001);
    COMMIT;
END;

--login credntial use case
CREATE OR REPLACE PROCEDURE LoginCredentials_PL(Username IN VARCHAR, Password IN VARCHAR, Employee_id IN DECIMAL)
AS
BEGIN
    INSERT INTO LoginCredentials(Username, Password, Employee_id)
    Values(Username, Password, Employee_id);
END;

CREATE OR REPLACE PROCEDURE AccessType_PL(AccessYN IN CHAR, Username IN VARCHAR)
AS
BEGIN
    INSERT INTO AccessTable(AccessYN, Username)
    VALUES(AccessYN, Username);
END;

CREATE OR REPLACE PROCEDURE Privileged_PL(Username IN VARCHAR)
AS 
BEGIN
    INSERT INTO Privileged(Username)
    VALUES(Username);
END;

CREATE OR REPLACE PROCEDURE ReadOnly_PL(Username IN VARCHAR)
AS 
BEGIN
    INSERT INTO ReadOnly(Username)
    VALUES(Username);
END;

BEGIN
    LoginCredentials_PL('JohnSmith', 'password', 1001);
    COMMIT;
END;

BEGIN
    LoginCredentials_PL('DavyJones', 'qwerty', 1002);
    COMMIT;
END;

BEGIN
    AccessType_PL(1, 'JohnSmith');
    COMMIT;
END;

BEGIN
    AccessType_PL(0, 'DavyJones');
    COMMIT;
END;

BEGIN
    Privileged_PL('JohnSmith');
    COMMIT;
END;

BEGIN
    ReadOnly_PL('DavyJones');
    COMMIT;
END;

--Industry data input use case
CREATE OR REPLACE PROCEDURE IndustryInput_PL(TrendID IN DECIMAL, Input_ID IN DECIMAL, Industry_ID IN DECIMAL, IndustryName IN VARCHAR)
AS
BEGIN
    INSERT INTO TrendInput(Input_ID)
    VALUES(Input_ID);
    
    INSERT INTO IndustryTrend(TrendID, Input_ID, Industry_ID)
    VALUES(TrendID, Input_ID, Industry_ID);
    
    INSERT INTO Industry(TrendID, IndustryName)
    Values(TrendID, IndustryName);
END;

BEGIN
    IndustryInput_PL('6001', '5001', '100', 'Packaged Goods');
    COMMIT;
END;

CREATE TABLE DataPointChange (
DataUpdateID DECIMAL(12) NOT NULL PRIMARY KEY,
OldReputation DECIMAL(2,2) NOT NULL,
NewReputation DECIMAL(2,2) NOT NULL,
OldProducts DECIMAL(2,2) NOT NULL,
NewProducts DECIMAL(2,2) NOT NULL,
OldLeaderhip DECIMAL(2,2) NOT NULL,
NewLeadership DECIMAL(2,2) NOT NULL,
Company_ID DECIMAL(12) NOT NULL,
ChangeDate DATE NOT NULL,
FOREIGN KEY (Company_ID) REFERENCES CompanyData(Company_ID)
);


CREATE OR REPLACE TRIGGER ReputationChangeTrigger
BEFORE UPDATE OR INSERT ON CompanyData
FOR EACH ROW
BEGIN
    IF :NEW.CompanyReputation <= 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Company Reputation cannot be negative.');
    END IF;
END;

CREATE OR REPLACE TRIGGER DataValidationTrigger
BEFORE UPDATE ON CompanyData
FOR EACH ROW
BEGIN
    INSERT INTO DataPointChange(DataUpdateID, OldReputation, NewReputation, OldProducts, NewProducts, OldLeaderhip, NewLeadership, Company_ID, ChangeDate)
    VALUES(NVL((SELECT MAX(DataUpdateID)+1 FROM DataPointChange), 1),
        :OLD.CompanyReputation,
        :NEW.CompanyReputation,
        :OLD.CompanyProducts,
        :NEW.CompanyProducts,
        :OLD.CompanyLeadership,
        :NEW.CompanyLeadership,
        :NEW.Company_ID,
        trunc(sysdate)
        );
END;
    
INSERT INTO Employee_Input(Input_ID, Employee_ID)
VALUES(5002, 1001);

INSERT INTO DataInput(Input_ID)
VALUES(5002);

INSERT INTO CompanyData(Company_ID, Input_ID, CompanyReputation, CompanyProducts, CompanyLeadership)
VALUES(999, 5002, .79, .81, .54);

UPDATE CompanyData
SET CompanyReputation = .77
WHERE Company_ID = 999;

UPDATE CompanyData
SET CompanyReputation = .75
WHERE Company_ID = 999;

UPDATE CompanyData
SET CompanyReputation = .73
WHERE Company_ID = 999;

SELECT *
FROM DataPointChange;

COMMIT;

--This query shows when any Company Data was updated and the associated date
SELECT DataPointChange.DataUpdateID, datapointchange.changedate
FROM DataPointChange
JOIN CompanyData ON CompanyData.Company_ID = DataPointChange.Company_ID
GROUP BY datapointchange.changedate, DataPointChange.DataUpdateID
HAVING COUNT(DataPointChange.DataUpdateID) = 1;



--This query retrieves access credential information of all employees
SELECT AccessYN, AccessTable.Username
FROM AccessTable
JOIN LoginCredentials ON LoginCredentials.Username = AccessTable.Username
JOIN Privileged ON Privileged.Username = AccessTable.Username
GROUP BY AccessTable.Username, AccessYN
HAVING COUNT(AccessYN) = 1;

/*This query retrieves Employee Username and ID Number if they have made an
input into the database
*/
SELECT LoginCredentials.Username, LoginCredentials.Employee_ID
FROM LoginCredentials
JOIN Employee ON Employee.Employee_id = LoginCredentials.Employee_ID
WHERE Employee.Employee_id IN
    (SELECT Employee_input.Employee_id
    FROM Employee_Input
    JOIN Employee ON Employee.Employee_id = Employee_input.Employee_id
    GROUP BY Employee_input.Employee_id)


commit;
