-- ============================================================
--  ZenFlow Yoga Studio — Full MySQL Schema
--  Optimized from original outline with enhancements:
--    • AUTO_INCREMENT primary keys throughout
--    • Indexes on all foreign keys + common query columns
--    • MEMBERSHIP_TYPE table (monthly/annual plans)
--    • Soft-delete / cancellation support on REGISTER
--    • TEACHES table (separate from INSTRUCTORPAYMENT)
--    • Password hash column for future auth integration
--    • All triggers, constraints, and sample data included
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS INSTRUCTORPAYMENT;
DROP TABLE IF EXISTS TEACHES;
DROP TABLE IF EXISTS REGISTER;
DROP TABLE IF EXISTS SALE;
DROP TABLE IF EXISTS CLASS;
DROP TABLE IF EXISTS CLASSPACKAGE;
DROP TABLE IF EXISTS MEMBERSHIP;
DROP TABLE IF EXISTS MEMBERSHIP_TYPE;
DROP TABLE IF EXISTS INSTRUCTOR;
DROP TABLE IF EXISTS PAYMENT;
DROP TABLE IF EXISTS WORK_SCHEDULE;
DROP TABLE IF EXISTS EMPLOYEE;
DROP TABLE IF EXISTS CUSTOMER;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  CUSTOMER
-- ============================================================
CREATE TABLE CUSTOMER (
    customerID    INT           NOT NULL AUTO_INCREMENT,
    fname         VARCHAR(50)   NOT NULL,
    lname         VARCHAR(50)   NOT NULL,
    email         VARCHAR(100)  NOT NULL,
    phone         VARCHAR(20),
    gender        CHAR(1),
    dob           DATE,
    joindate      DATE          NOT NULL DEFAULT (CURRENT_DATE),
    classbalance  INT           NOT NULL DEFAULT 0,
    password_hash VARCHAR(255),                        -- for future auth
    CONSTRAINT pk_customer    PRIMARY KEY (customerID),
    CONSTRAINT uq_cust_email  UNIQUE      (email),
    CONSTRAINT chk_cust_gender CHECK (gender IN ('M','F','O'))
);

CREATE INDEX idx_customer_email ON CUSTOMER (email);

-- ============================================================
--  MEMBERSHIP TYPE  (e.g. Monthly Unlimited, Annual, Drop-In)
-- ============================================================
CREATE TABLE MEMBERSHIP_TYPE (
    membershipTypeID   INT            NOT NULL AUTO_INCREMENT,
    typeName           VARCHAR(100)   NOT NULL,
    typeDescription    VARCHAR(255),
    monthlyPrice       DECIMAL(10,2)  NOT NULL,
    classesPerMonth    INT            DEFAULT NULL,  -- NULL = unlimited
    CONSTRAINT pk_membership_type PRIMARY KEY (membershipTypeID)
);

-- ============================================================
--  MEMBERSHIP  (customer subscription to a plan)
-- ============================================================
CREATE TABLE MEMBERSHIP (
    membershipID       INT          NOT NULL AUTO_INCREMENT,
    customerID         INT          NOT NULL,
    membershipTypeID   INT          NOT NULL,
    startDate          DATE         NOT NULL,
    endDate            DATE,
    status             VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',  -- ACTIVE / CANCELLED / EXPIRED
    CONSTRAINT pk_membership          PRIMARY KEY (membershipID),
    CONSTRAINT fk_membership_customer FOREIGN KEY (customerID)        REFERENCES CUSTOMER(customerID)      ON DELETE CASCADE,
    CONSTRAINT fk_membership_type     FOREIGN KEY (membershipTypeID)  REFERENCES MEMBERSHIP_TYPE(membershipTypeID),
    CONSTRAINT chk_membership_status  CHECK (status IN ('ACTIVE','CANCELLED','EXPIRED'))
);

CREATE INDEX idx_membership_customer ON MEMBERSHIP (customerID);

-- ============================================================
--  CLASSPACKAGE  (punch-card style: buy N classes)
-- ============================================================
CREATE TABLE CLASSPACKAGE (
    classpackageID    INT            NOT NULL AUTO_INCREMENT,
    classpackagedesc  VARCHAR(255)   NOT NULL,
    classpackageprice DECIMAL(10,2)  NOT NULL,
    numClasses        INT            NOT NULL,
    CONSTRAINT pk_classpackage PRIMARY KEY (classpackageID)
);

-- ============================================================
--  INSTRUCTOR
-- ============================================================
CREATE TABLE INSTRUCTOR (
    instructorID   INT          NOT NULL AUTO_INCREMENT,
    instfname      VARCHAR(50)  NOT NULL,
    instlname      VARCHAR(50)  NOT NULL,
    instphone      VARCHAR(20),
    instdob        DATE,
    inststartdate  DATE,
    instgender     CHAR(1),
    bio            TEXT,
    specialty      VARCHAR(100),
    CONSTRAINT pk_instructor        PRIMARY KEY (instructorID),
    CONSTRAINT chk_inst_gender      CHECK (instgender IN ('M','F','O'))
);

-- ============================================================
--  CLASS
-- ============================================================
CREATE TABLE CLASS (
    classID         INT            NOT NULL AUTO_INCREMENT,
    classname       VARCHAR(100)   NOT NULL,
    classtemp       DECIMAL(5,2),                    -- room temperature in °F
    startTime       TIME           NOT NULL,
    endTime         TIME           NOT NULL,
    classDate       DATE           NOT NULL,
    spotsAvailable  INT            NOT NULL DEFAULT 20,
    spotsTotal      INT            NOT NULL DEFAULT 20,
    instructorID    INT,
    difficulty      VARCHAR(20)    DEFAULT 'All Levels', -- Beginner/Intermediate/Advanced/All Levels
    description     TEXT,
    CONSTRAINT pk_class           PRIMARY KEY (classID),
    CONSTRAINT fk_class_inst      FOREIGN KEY (instructorID) REFERENCES INSTRUCTOR(instructorID) ON DELETE SET NULL,
    CONSTRAINT chk_class_spots    CHECK (spotsAvailable >= 0),
    CONSTRAINT chk_class_diff     CHECK (difficulty IN ('Beginner','Intermediate','Advanced','All Levels'))
);

CREATE INDEX idx_class_date       ON CLASS (classDate);
CREATE INDEX idx_class_instructor ON CLASS (instructorID);

-- ============================================================
--  TEACHES  (many-to-many: instructor ↔ class)
-- ============================================================
CREATE TABLE TEACHES (
    teachesID    INT  NOT NULL AUTO_INCREMENT,
    instructorID INT  NOT NULL,
    classID      INT  NOT NULL,
    CONSTRAINT pk_teaches         PRIMARY KEY (teachesID),
    CONSTRAINT fk_teaches_inst    FOREIGN KEY (instructorID) REFERENCES INSTRUCTOR(instructorID) ON DELETE CASCADE,
    CONSTRAINT fk_teaches_class   FOREIGN KEY (classID)      REFERENCES CLASS(classID)           ON DELETE CASCADE,
    CONSTRAINT uq_teaches         UNIQUE (instructorID, classID)
);

-- ============================================================
--  INSTRUCTOR PAYMENT
-- ============================================================
CREATE TABLE INSTRUCTORPAYMENT (
    paymentID      INT            NOT NULL AUTO_INCREMENT,
    instructorID   INT            NOT NULL,
    classID        INT            NOT NULL,
    paymentAmount  DECIMAL(10,2)  NOT NULL,
    paymentDate    DATE           NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_instpay          PRIMARY KEY (paymentID),
    CONSTRAINT fk_instpay_inst     FOREIGN KEY (instructorID) REFERENCES INSTRUCTOR(instructorID),
    CONSTRAINT fk_instpay_class    FOREIGN KEY (classID)      REFERENCES CLASS(classID)
);

CREATE INDEX idx_instpay_instructor ON INSTRUCTORPAYMENT (instructorID);

-- ============================================================
--  SALE  (customer buys a class package)
-- ============================================================
CREATE TABLE SALE (
    saleID          INT            NOT NULL AUTO_INCREMENT,
    customerID      INT            NOT NULL,
    classpackageID  INT            NOT NULL,
    saleDate        DATE           NOT NULL DEFAULT (CURRENT_DATE),
    paymentType     VARCHAR(50),
    amountPaid      DECIMAL(10,2),
    CONSTRAINT pk_sale              PRIMARY KEY (saleID),
    CONSTRAINT fk_sale_customer     FOREIGN KEY (customerID)       REFERENCES CUSTOMER(customerID),
    CONSTRAINT fk_sale_classpackage FOREIGN KEY (classpackageID)   REFERENCES CLASSPACKAGE(classpackageID)
);

CREATE INDEX idx_sale_customer ON SALE (customerID);

-- ============================================================
--  REGISTER  (customer signs up for a class)
-- ============================================================
CREATE TABLE REGISTER (
    registerID    INT          NOT NULL AUTO_INCREMENT,
    customerID    INT          NOT NULL,
    classID       INT          NOT NULL,
    registerDate  DATE         NOT NULL DEFAULT (CURRENT_DATE),
    status        VARCHAR(20)  NOT NULL DEFAULT 'REGISTERED',  -- REGISTERED / CANCELLED / ATTENDED
    CONSTRAINT pk_register          PRIMARY KEY (registerID),
    CONSTRAINT fk_register_customer FOREIGN KEY (customerID) REFERENCES CUSTOMER(customerID),
    CONSTRAINT fk_register_class    FOREIGN KEY (classID)    REFERENCES CLASS(classID),
    CONSTRAINT uq_register          UNIQUE (customerID, classID),
    CONSTRAINT chk_register_status  CHECK (status IN ('REGISTERED','CANCELLED','ATTENDED'))
);

CREATE INDEX idx_register_customer ON REGISTER (customerID);
CREATE INDEX idx_register_class    ON REGISTER (classID);

-- ============================================================
--  EMPLOYEE  (desk staff, cleaners, etc.)
-- ============================================================
CREATE TABLE EMPLOYEE (
    employeeID  INT          NOT NULL AUTO_INCREMENT,
    empfname    VARCHAR(50)  NOT NULL,
    emplname    VARCHAR(50)  NOT NULL,
    role        VARCHAR(50),
    phone       VARCHAR(20),
    hourlyRate  DECIMAL(10,2) NOT NULL DEFAULT 15.00,
    CONSTRAINT pk_employee PRIMARY KEY (employeeID)
);

-- ============================================================
--  WORK_SCHEDULE
-- ============================================================
CREATE TABLE WORK_SCHEDULE (
    scheduleID   INT   NOT NULL AUTO_INCREMENT,
    employeeID   INT   NOT NULL,
    workDate     DATE  NOT NULL,
    startTime    TIME  NOT NULL,
    endTime      TIME  NOT NULL,
    CONSTRAINT pk_work_schedule        PRIMARY KEY (scheduleID),
    CONSTRAINT fk_work_schedule_emp    FOREIGN KEY (employeeID) REFERENCES EMPLOYEE(employeeID)
);

CREATE INDEX idx_work_schedule_emp ON WORK_SCHEDULE (employeeID);

-- ============================================================
--  PAYMENT  (employee payroll)
-- ============================================================
CREATE TABLE PAYMENT (
    paymentID      INT            NOT NULL AUTO_INCREMENT,
    employeeID     INT            NOT NULL,
    paymentAmount  DECIMAL(10,2)  NOT NULL,
    paymentDate    DATE           NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_payment        PRIMARY KEY (paymentID),
    CONSTRAINT fk_payment_emp    FOREIGN KEY (employeeID) REFERENCES EMPLOYEE(employeeID)
);

-- ============================================================
--  TRIGGERS
-- ============================================================

DELIMITER //

-- 1. Auto-pay instructor when a TEACHES row is inserted
CREATE TRIGGER trg_PayInstructorAfterTeach
AFTER INSERT ON TEACHES
FOR EACH ROW
BEGIN
    INSERT INTO INSTRUCTORPAYMENT (instructorID, classID, paymentAmount, paymentDate)
    VALUES (NEW.instructorID, NEW.classID, 50.00, CURRENT_DATE);
END //

-- 2. Add classes to customer balance when a package is purchased
CREATE TRIGGER trg_UpdateClassBalanceAfterSale
AFTER INSERT ON SALE
FOR EACH ROW
BEGIN
    UPDATE CUSTOMER
    SET classbalance = classbalance +
        (SELECT numClasses FROM CLASSPACKAGE WHERE classpackageID = NEW.classpackageID)
    WHERE customerID = NEW.customerID;
END //

-- 3. Deduct class balance and spot count on registration
CREATE TRIGGER trg_UpdateBalanceAndSpotsAfterRegister
AFTER INSERT ON REGISTER
FOR EACH ROW
BEGIN
    DECLARE v_spots INT;
    DECLARE v_balance INT;

    -- Check customer has class balance
    SELECT classbalance INTO v_balance FROM CUSTOMER WHERE customerID = NEW.customerID;
    IF v_balance <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient class balance for registration';
    END IF;

    -- Check spots available
    SELECT spotsAvailable INTO v_spots FROM CLASS WHERE classID = NEW.classID;
    IF v_spots <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No spots available for this class';
    END IF;

    -- Deduct balance
    UPDATE CUSTOMER SET classbalance = classbalance - 1 WHERE customerID = NEW.customerID;

    -- Deduct spot
    UPDATE CLASS SET spotsAvailable = spotsAvailable - 1 WHERE classID = NEW.classID;
END //

-- 4. Restore class balance and spot count on registration cancellation
CREATE TRIGGER trg_RestoreOnCancellation
AFTER UPDATE ON REGISTER
FOR EACH ROW
BEGIN
    IF NEW.status = 'CANCELLED' AND OLD.status = 'REGISTERED' THEN
        UPDATE CUSTOMER SET classbalance = classbalance + 1 WHERE customerID = NEW.customerID;
        UPDATE CLASS SET spotsAvailable = spotsAvailable + 1 WHERE classID = NEW.classID;
    END IF;
END //

-- 5. Auto-calculate employee pay when a work schedule is added
CREATE TRIGGER trg_CalculateEmployeePayment
AFTER INSERT ON WORK_SCHEDULE
FOR EACH ROW
BEGIN
    DECLARE v_hours    DECIMAL(5,2);
    DECLARE v_rate     DECIMAL(10,2);
    DECLARE v_amount   DECIMAL(10,2);

    SET v_hours  = TIMESTAMPDIFF(MINUTE, NEW.startTime, NEW.endTime) / 60.0;
    SELECT hourlyRate INTO v_rate FROM EMPLOYEE WHERE employeeID = NEW.employeeID;
    SET v_amount = v_hours * v_rate;

    INSERT INTO PAYMENT (employeeID, paymentAmount, paymentDate)
    VALUES (NEW.employeeID, v_amount, CURRENT_DATE);
END //

DELIMITER ;

-- ============================================================
--  SAMPLE DATA
-- ============================================================

-- Membership types
INSERT INTO MEMBERSHIP_TYPE (membershipTypeID, typeName, typeDescription, monthlyPrice, classesPerMonth) VALUES
(1, 'Drop-In',           'Pay per class using class packages. No monthly commitment.',          0.00,  0),
(2, 'Basic',             '4 classes per month. Perfect for beginners.',                        39.00,  4),
(3, 'Standard',          '8 classes per month. Most popular plan.',                            65.00,  8),
(4, 'Unlimited',         'Unlimited classes every month. Best value for regulars.',            99.00, NULL),
(5, 'Annual Unlimited',  'Unlimited classes, billed annually. Save 20% vs monthly.',          79.00, NULL);

-- Class packages
INSERT INTO CLASSPACKAGE (classpackageID, classpackagedesc, classpackageprice, numClasses) VALUES
(1, 'Single Class',    18.00,   1),
(2, '5-Class Pass',    80.00,   5),
(3, '10-Class Pass',  140.00,  10),
(4, '20-Class Pass',  240.00,  20);

-- Instructors
INSERT INTO INSTRUCTOR (instructorID, instfname, instlname, instphone, instdob, inststartdate, instgender, bio, specialty) VALUES
(1, 'Alice',   'Smith',    '123-456-7890', '1980-05-15', '2010-01-01', 'F',
   'Alice has been teaching yoga for over 15 years with certifications in Hatha and Vinyasa.',
   'Vinyasa, Hatha'),
(2, 'Bob',     'Johnson',  '987-654-3210', '1975-08-20', '2008-06-15', 'M',
   'Bob is a former athlete turned wellness coach specializing in Power and Ashtanga yoga.',
   'Power Yoga, Ashtanga'),
(3, 'Eva',     'Brown',    '234-567-8901', '1983-02-10', '2012-03-20', 'F',
   'Eva is a certified meditation teacher and Yin yoga specialist.',
   'Yin, Restorative, Meditation'),
(4, 'Marcus',  'Lee',      '345-678-9012', '1988-11-03', '2015-07-01', 'M',
   'Marcus combines movement and mindfulness, specializing in Kundalini and breathwork.',
   'Kundalini, Breathwork'),
(5, 'Priya',   'Patel',    '456-789-0123', '1991-04-22', '2018-09-01', 'F',
   'Priya is an E-RYT 500 instructor with a passion for making yoga accessible to everyone.',
   'Beginner, Chair Yoga, Prenatal');

-- Customers (25 sample customers)
INSERT INTO CUSTOMER (customerID, fname, lname, email, phone, gender, dob, joindate, classbalance) VALUES
(1,  'John',      'Doe',       'john.doe@example.com',           '1234567890', 'M', '1990-01-01', '2020-01-15', 5),
(2,  'Jane',      'Smith',     'jane.smith@example.com',         '0987654321', 'F', '1992-05-15', '2020-02-10', 10),
(3,  'Michael',   'Johnson',   'michael.johnson@example.com',    '5678901234', 'M', '1985-09-20', '2019-12-20', 7),
(4,  'Emily',     'Williams',  'emily.williams@example.com',     '9876543210', 'F', '1988-03-12', '2020-03-05', 3),
(5,  'Daniel',    'Brown',     'daniel.brown@example.com',       '2345678901', 'M', '1993-07-25', '2020-04-18', 8),
(6,  'Olivia',    'Davis',     'olivia.davis@example.com',       '8765432109', 'F', '1991-11-30', '2020-05-02', 12),
(7,  'William',   'Miller',    'william.miller@example.com',     '3456789012', 'M', '1987-02-28', '2020-06-08', 6),
(8,  'Sophia',    'Wilson',    'sophia.wilson@example.com',      '7654321098', 'F', '1995-04-17', '2020-07-12', 4),
(9,  'James',     'Moore',     'james.moore@example.com',        '4567890123', 'M', '1989-08-10', '2020-08-25', 9),
(10, 'Emma',      'Taylor',    'emma.taylor@example.com',        '6543210987', 'F', '1994-12-05', '2020-09-01', 15),
(11, 'Benjamin',  'Anderson',  'benjamin.anderson@example.com',  '5432109876', 'M', '1996-02-18', '2020-10-03', 11),
(12, 'Mia',       'Thomas',    'mia.thomas@example.com',         '4321098765', 'F', '1986-06-22', '2020-11-14', 7),
(13, 'Elijah',    'Jackson',   'elijah.jackson@example.com',     '3210987654', 'M', '1997-10-08', '2020-12-30', 6),
(14, 'Charlotte', 'White',     'charlotte.white@example.com',    '2109876543', 'F', '1998-04-03', '2021-01-05', 9),
(15, 'Lucas',     'Harris',    'lucas.harris@example.com',       '1098765432', 'M', '1990-11-19', '2021-02-18', 8),
(16, 'Ava',       'Martinez',  'ava.martinez@example.com',       '0987654321', 'F', '1992-07-15', '2021-03-21', 13),
(17, 'Alexander', 'Garcia',    'alexander.garcia@example.com',   '9876543210', 'M', '1988-03-12', '2021-04-25', 5),
(18, 'Madison',   'Lopez',     'madison.lopez@example.com',      '8765432109', 'F', '1991-11-30', '2021-05-30', 10),
(19, 'Jacob',     'King',      'jacob.king@example.com',         '7654321098', 'M', '1995-04-17', '2021-06-12', 7),
(20, 'Isabella',  'Perez',     'isabella.perez@example.com',     '6543210987', 'F', '1989-08-10', '2021-07-18', 14),
(21, 'William',   'Rivera',    'william.rivera@example.com',     '5432109876', 'M', '1996-02-18', '2021-08-22', 9),
(22, 'Sophia',    'Young',     'sophia.young@example.com',       '4321098765', 'F', '1986-06-22', '2021-09-05', 6),
(23, 'Ethan',     'Wright',    'ethan.wright@example.com',       '3210987654', 'M', '1997-10-08', '2021-10-10', 11),
(24, 'Amelia',    'Scott',     'amelia.scott@example.com',       '2109876543', 'F', '1998-04-03', '2021-11-15', 8),
(25, 'Oliver',    'Green',     'oliver.green@example.com',       '1098765432', 'M', '1990-11-19', '2021-12-20', 7);

-- Classes (5 days × 5 classes, instructorID assigned)
INSERT INTO CLASS (classID, classname, classtemp, startTime, endTime, classDate, spotsAvailable, spotsTotal, instructorID, difficulty, description) VALUES
-- Day 1: June 25, 2024
(1,  'Yoga Basics',        32.50, '08:00:00', '09:00:00', '2024-06-25', 20, 20, 1, 'Beginner',     'Foundation poses and breathing techniques for new yogis.'),
(2,  'Vinyasa Flow',       34.00, '10:00:00', '11:00:00', '2024-06-25', 15, 15, 1, 'Intermediate', 'A dynamic sequence linking breath to movement.'),
(3,  'Hatha Yoga',         31.00, '12:00:00', '13:00:00', '2024-06-25', 18, 18, 2, 'All Levels',   'Classic postures held with mindful alignment.'),
(4,  'Power Yoga',         35.00, '14:00:00', '15:00:00', '2024-06-25', 22, 22, 2, 'Advanced',     'High-intensity yoga for strength and endurance.'),
(5,  'Restorative Yoga',   30.00, '16:00:00', '17:00:00', '2024-06-25', 25, 25, 3, 'All Levels',   'Supported poses held for deep relaxation and recovery.'),
-- Day 2: June 26, 2024
(6,  'Yin Yoga',           33.00, '08:00:00', '09:00:00', '2024-06-26', 18, 18, 3, 'All Levels',   'Long-held poses targeting deep connective tissue.'),
(7,  'Ashtanga Yoga',      36.00, '10:00:00', '11:00:00', '2024-06-26', 20, 20, 2, 'Advanced',     'A rigorous set sequence building heat and focus.'),
(8,  'Kundalini Yoga',     34.50, '12:00:00', '13:00:00', '2024-06-26', 15, 15, 4, 'All Levels',   'Dynamic kriyas and meditation to awaken energy.'),
(9,  'Chair Yoga',         28.00, '14:00:00', '15:00:00', '2024-06-26', 12, 12, 5, 'Beginner',     'Accessible yoga using a chair for support. Great for seniors or rehabilitation.'),
(10, 'Aerial Yoga',        37.00, '16:00:00', '17:00:00', '2024-06-26', 10, 10, 1, 'Intermediate', 'Yoga using a silk hammock for inversions and core work.'),
-- Day 3: June 27, 2024
(11, 'Hot Yoga',           35.50, '08:00:00', '09:00:00', '2024-06-27', 22, 22, 2, 'All Levels',   'Flowing sequences in a heated room to build flexibility.'),
(12, 'Iyengar Yoga',       32.00, '10:00:00', '11:00:00', '2024-06-27', 18, 18, 1, 'All Levels',   'Precision alignment using props for therapeutic benefit.'),
(13, 'AcroYoga',           36.50, '12:00:00', '13:00:00', '2024-06-27', 15, 15, 4, 'Intermediate', 'Partner-based acrobatics and yoga — trust and play.'),
(14, 'Prenatal Yoga',      29.00, '14:00:00', '15:00:00', '2024-06-27', 20, 20, 5, 'All Levels',   'Gentle sequences designed for expectant mothers.'),
(15, 'Yoga for Seniors',   27.50, '16:00:00', '17:00:00', '2024-06-27', 18, 18, 5, 'Beginner',     'Low-impact yoga tailored for older adults.'),
-- Day 4: June 28, 2024
(16, 'Core Power Yoga',    34.00, '08:00:00', '09:00:00', '2024-06-28', 25, 25, 2, 'Advanced',     'Strength-focused flow targeting core stability.'),
(17, 'Yoga Nidra',         30.50, '10:00:00', '11:00:00', '2024-06-28', 15, 15, 3, 'All Levels',   'Guided deep-relaxation practice — "yogic sleep".'),
(18, 'Mindfulness Yoga',   31.50, '12:00:00', '13:00:00', '2024-06-28', 20, 20, 3, 'All Levels',   'Slow, intentional movement paired with mindfulness cues.'),
(19, 'Pilates',            33.00, '14:00:00', '15:00:00', '2024-06-28', 18, 18, 4, 'All Levels',   'Core-centered movement system for posture and strength.'),
(20, 'Gentle Flow Yoga',   29.50, '16:00:00', '17:00:00', '2024-06-28', 22, 22, 5, 'Beginner',     'Soft flowing movements for stress relief.'),
-- Day 5: June 29, 2024
(21, 'Beginner Yoga',      28.00, '08:00:00', '09:00:00', '2024-06-29', 20, 20, 5, 'Beginner',     'The perfect starting point for your yoga journey.'),
(22, 'Advanced Yoga',      36.00, '10:00:00', '11:00:00', '2024-06-29', 15, 15, 2, 'Advanced',     'Challenging sequences for experienced practitioners.'),
(23, 'Yoga Therapy',       32.50, '12:00:00', '13:00:00', '2024-06-29', 18, 18, 1, 'All Levels',   'Therapeutic yoga addressing specific physical concerns.'),
(24, 'Yoga Sculpt',        35.00, '14:00:00', '15:00:00', '2024-06-29', 22, 22, 4, 'Intermediate', 'Yoga with light weights for a full-body sculpting workout.'),
(25, 'Meditation Class',   25.00, '16:00:00', '17:00:00', '2024-06-29', 25, 25, 3, 'All Levels',   'Guided meditation for clarity, calm, and focus.');

-- Teaches (instructor assigned per class — auto-triggers INSTRUCTORPAYMENT)
INSERT INTO TEACHES (instructorID, classID) VALUES
(1,1),(1,2),(2,3),(2,4),(3,5),
(3,6),(2,7),(4,8),(5,9),(1,10),
(2,11),(1,12),(4,13),(5,14),(5,15),
(2,16),(3,17),(3,18),(4,19),(5,20),
(5,21),(2,22),(1,23),(4,24),(3,25);

-- Sales (customers buying class packages)
INSERT INTO SALE (saleID, customerID, classpackageID, saleDate, paymentType, amountPaid) VALUES
(1,  1,  2, '2024-06-25', 'Credit Card', 80.00),
(2,  3,  3, '2024-06-26', 'Cash',       140.00),
(3,  5,  1, '2024-06-27', 'Credit Card', 18.00),
(4,  7,  2, '2024-06-28', 'Credit Card', 80.00),
(5,  9,  3, '2024-06-29', 'Cash',       140.00),
(6,  11, 2, '2024-06-30', 'Credit Card', 80.00),
(7,  13, 1, '2024-07-01', 'Credit Card', 18.00),
(8,  15, 3, '2024-07-02', 'Cash',       140.00),
(9,  17, 2, '2024-07-03', 'Credit Card', 80.00),
(10, 19, 1, '2024-07-04', 'Credit Card', 18.00);

-- Memberships
INSERT INTO MEMBERSHIP (membershipID, customerID, membershipTypeID, startDate, endDate, status) VALUES
(1,  2,  4, '2024-01-01', NULL,         'ACTIVE'),
(2,  4,  3, '2024-03-01', NULL,         'ACTIVE'),
(3,  6,  4, '2023-06-01', NULL,         'ACTIVE'),
(4,  8,  2, '2024-05-01', '2024-08-01', 'ACTIVE'),
(5,  10, 5, '2023-01-01', '2024-01-01', 'EXPIRED'),
(6,  12, 3, '2024-02-01', NULL,         'ACTIVE'),
(7,  14, 4, '2024-04-01', NULL,         'ACTIVE'),
(8,  16, 5, '2024-01-01', '2025-01-01', 'ACTIVE'),
(9,  20, 4, '2023-09-01', NULL,         'ACTIVE'),
(10, 24, 2, '2024-06-01', NULL,         'ACTIVE');

-- Registrations (customers signing up for classes)
INSERT INTO REGISTER (registerID, customerID, classID, registerDate, status) VALUES
(1,  2,  6,  '2024-06-25', 'REGISTERED'),
(2,  4,  8,  '2024-06-25', 'REGISTERED'),
(3,  6,  10, '2024-06-26', 'ATTENDED'),
(4,  8,  12, '2024-06-26', 'ATTENDED'),
(5,  10, 14, '2024-06-27', 'REGISTERED'),
(6,  12, 16, '2024-06-27', 'REGISTERED'),
(7,  14, 18, '2024-06-28', 'REGISTERED'),
(8,  16, 20, '2024-06-28', 'ATTENDED'),
(9,  18, 22, '2024-06-29', 'REGISTERED'),
(10, 20, 24, '2024-06-29', 'REGISTERED');

-- Employees
INSERT INTO EMPLOYEE (employeeID, empfname, emplname, role, phone, hourlyRate) VALUES
(1, 'John',  'Smith',   'Desk Employee', '111-222-3333', 17.00),
(2, 'Alice', 'Johnson', 'Cleaner',       '555-666-7777', 15.00),
(3, 'Maria', 'Chen',    'Desk Employee', '444-555-6666', 17.00),
(4, 'Derek', 'Okafor',  'Manager',       '777-888-9999', 25.00);

-- Work schedules (triggers auto-calculate payroll)
INSERT INTO WORK_SCHEDULE (scheduleID, employeeID, workDate, startTime, endTime) VALUES
(1, 1, '2024-06-25', '08:00:00', '16:00:00'),
(2, 2, '2024-06-25', '08:00:00', '12:00:00'),
(3, 2, '2024-06-25', '13:00:00', '17:00:00'),
(4, 3, '2024-06-25', '12:00:00', '20:00:00'),
(5, 4, '2024-06-25', '09:00:00', '17:00:00'),
(6, 1, '2024-06-26', '08:00:00', '16:00:00'),
(7, 3, '2024-06-26', '12:00:00', '20:00:00');

-- ============================================================
--  USEFUL VIEWS
-- ============================================================

-- Full class schedule with instructor name and availability
CREATE OR REPLACE VIEW v_class_schedule AS
SELECT
    c.classID,
    c.classname,
    c.classDate,
    c.startTime,
    c.endTime,
    c.difficulty,
    c.classtemp   AS roomTempF,
    c.spotsAvailable,
    c.spotsTotal,
    c.description,
    CONCAT(i.instfname, ' ', i.instlname) AS instructorName,
    i.specialty
FROM CLASS c
LEFT JOIN INSTRUCTOR i ON c.instructorID = i.instructorID
ORDER BY c.classDate, c.startTime;

-- Customer class balance and membership status
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT
    cu.customerID,
    CONCAT(cu.fname, ' ', cu.lname) AS fullName,
    cu.email,
    cu.classbalance,
    mt.typeName    AS membershipPlan,
    m.status       AS membershipStatus,
    m.startDate    AS membershipStart,
    m.endDate      AS membershipEnd
FROM CUSTOMER cu
LEFT JOIN MEMBERSHIP m   ON cu.customerID = m.customerID AND m.status = 'ACTIVE'
LEFT JOIN MEMBERSHIP_TYPE mt ON m.membershipTypeID = mt.membershipTypeID;

-- Revenue summary by month
CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT
    DATE_FORMAT(saleDate, '%Y-%m') AS saleMonth,
    COUNT(*)                       AS totalSales,
    SUM(amountPaid)                AS totalRevenue
FROM SALE
GROUP BY DATE_FORMAT(saleDate, '%Y-%m')
ORDER BY saleMonth;

-- Most popular classes
CREATE OR REPLACE VIEW v_class_popularity AS
SELECT
    c.classname,
    COUNT(r.registerID) AS totalRegistrations,
    SUM(CASE WHEN r.status = 'ATTENDED' THEN 1 ELSE 0 END) AS attended
FROM CLASS c
LEFT JOIN REGISTER r ON c.classID = r.classID
GROUP BY c.classID, c.classname
ORDER BY totalRegistrations DESC;
