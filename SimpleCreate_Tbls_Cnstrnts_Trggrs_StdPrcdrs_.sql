
--------------CREATE TABLES----------------
Create table Flights (
    FlightNo Varchar(10),
    MemberID Varchar(10),
    PlaneID Varchar(10),
    FlightDurationHrs Decimal (4,2),
    CONSTRAINT F_PK Primary Key (FlightNo),
    CONSTRAINT F_FK_M Foreign Key (MemberID) REFERENCES Members (MemberID),
    CONSTRAINT F_FK_P Foreign Key (PlaneID) REFERENCES Aircraft (PlaneID)
)


Create table Members (
    MemberID Varchar(10),
    FirstName Varchar(50),
    LastName Varchar(50),
    YTDHrsLogged Decimal (6,2),
    MemberType Varchar(50),
    CONSTRAINT M_PK Primary Key (MemberID)
)

Create table MemberSvs (
    EmployeeID Varchar(10),
    MemberID Varchar(10),
    AnnSalary Decimal(8,2),
    Position Varchar(20),
    CONSTRAINT MS_PK Primary Key (EmployeeID),
    CONSTRAINT M_FK_M Foreign Key (MemberID) REFERENCES Members (MemberID)
)

Create table Aircraft (
    PlaneID Varchar(10),
    Make Varchar(50),
    Model Varchar(50),
    LifeTimeHrs Decimal (6,2),
    CONSTRAINT A_PK Primary Key (PlaneID)
)

-------------CONSTRAINTS---------------- 

ALTER TABLE FLIGHTS 
ADD CONSTRAINT Flight_Num CHECK (FlightDurationHrs between 0.00 and 15.00);

ALTER TABLE MEMBERS 
ADD CONSTRAINT Mem_Type CHECK (MemberType in ('Basic','Pro','Super'))

-------------INSERT INTO-----------------

--Insert INTO 
INSERT INTO Members VALUES ('000001','Mike','Benson','110','Super') 
INSERT INTO Members VALUES ('000002','John','Tomlins','180','Super') 
INSERT INTO Members VALUES ('000003','Anthony','Brady','30','Basic') 
INSERT INTO Members VALUES ('000004','Cheryll','Jordan','73','Pro') 
INSERT INTO Members VALUES ('000005','Susan','Stevens','88','Pro') 

INSERT INTO MemberSvs VALUES ('FC001','000001','42000','Flight Crew') 
INSERT INTO MemberSvs VALUES ('AT001','000002','96000','Air Traffic') 
INSERT INTO MemberSvs VALUES ('LX001',NULL,'88000','Logistics') 
INSERT INTO MemberSvs VALUES ('SC001',NULL,'77000','Supply Chain Manager') 
INSERT INTO MemberSvs VALUES ('RT001',NULL,'31000','Runway Tech') 

INSERT INTO Aircraft VALUES ('RED001','AIRBUS','A909','1000.41') 
INSERT INTO Aircraft VALUES ('ORA001','AIRBUS','A909','614.21') 
INSERT INTO Aircraft VALUES ('YEL001','BOEING','B737','1013.14') 
INSERT INTO Aircraft VALUES ('GRE001','BOEING','B737','500.19') 
INSERT INTO Aircraft VALUES ('BLU001','BOEING','B739','309.99') 

INSERT INTO Flights VALUES ('CID837','000001','RED001','1.15') 
INSERT INTO Flights VALUES ('PQIE715','000001','ORA001','2.85') 
INSERT INTO Flights VALUES ('AAA000','000002','YEL001','5.35') 
INSERT INTO Flights VALUES ('ZXC765','000002','GRE001','7.71') 
INSERT INTO Flights VALUES ('PPO298','000003','BLU001','2.50') 

------------SECURITY / USERS --------------

CREATE LOGIN SystemAdmin WITH PASSWORD = 'SYS123';
CREATE USER Tom4244 FOR LOGIN SystemAdmin
ALTER ROLE db_Owner ADD MEMBER Tom4244


CREATE LOGIN MEMBER WITH PASSWORD = 'MEM123'
CREATE USER JThompson FOR LOGIN MEMBER
GRANT INSERT ON OBJECT::dbo.flights TO JThompson
GRANT SELECT ON OBJECT::dbo.flights TO JThompson


CREATE LOGIN EMPLOYEE WITH PASSWORD = 'EMP123'
CREATE USER MBarrows FOR LOGIN EMPLOYEE
GRANT SELECT ON OBJECT::dbo.MemberSvs TO MBarrows
GRANT SELECT ON OBJECT::dbo.AirCraft TO MBarrows
GRANT SELECT ON OBJECT::dbo.Flights TO MBarrows 
GRANT UPDATE ON OBJECT::dbo.Flights TO MBarrows

------------TRIGGERS------------
--Adding hours when new flight scheduled
CREATE TRIGGER AddHours 
    ON Flights FOR INSERT 
AS 
    DECLARE @hrs decimal(6,2) 
    DECLARE @member varchar(10) 
BEGIN 
    SELECT @hrs = (SELECT FlightDurationHrs FROM INSERTED) 
    SELECT @member = (SELECT MemberID FROM INSERTED) 
UPDATE Members SET YTDHrsLogged = YTDHrsLogged + @hrs 
        WHERE MemberID = @member 
END  
GO 

--Updating membership type when hours break into next tier
CREATE TRIGGER UpdateMembership 
    ON Members FOR UPDATE 
AS 
    DECLARE @MemID as INT; 
    DECLARE @YTDHours as Decimal(6,2); 
    DECLARE @MemType as varchar(50); 
    DECLARE @Cursor as CURSOR; 
BEGIN 
    SET @Cursor = CURSOR FOR 
    SELECT MemberID, YTDHrsLogged, MemberType 
     FROM Members; 
    OPEN @Cursor; 
    FETCH NEXT FROM @Cursor INTO @MemID, @YTDHours, @MemType; 
    WHILE @@FETCH_STATUS = 0 
        BEGIN 
                IF @YTDHours BETWEEN 0 and 40  UPDATE Members SET MemberType = 'Basic' where MemberID = @MemID 
                IF @YTDHours BETWEEN 40 and 100  UPDATE Members SET MemberType = 'Pro' where MemberID = @MemID 
                IF @YTDHours > 100  UPDATE Members SET MemberType = 'Super' where MemberID = @MemID 
         FETCH NEXT FROM @Cursor INTO @MemID, @YTDHours, @MemType; 
        END; 
    CLOSE @Cursor; 
END 
GO 

--Stored Procedure that zeroes out hours on January 1st
CREATE PROCEDURE ZeroHours   
AS    
    UPDATE MEMBERS 
    SET YTDHrsLogged = 0 
GO   