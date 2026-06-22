-- ============================================================
--  ZenFlow Yoga Studio — Seed Data
--  Author: Braden Bourgeois
--
--  Run AFTER zenflow_yoga_schema.sql
--  Populates all tables with realistic sample data.
--
--  Load order matters due to foreign key constraints:
--    1. MEMBERSHIP_TYPE
--    2. CLASSPACKAGE
--    3. INSTRUCTOR
--    4. CUSTOMER
--    5. CLASS
--    6. TEACHES           (triggers → INSTRUCTORPAYMENT)
--    7. SALE              (triggers → CUSTOMER.classbalance)
--    8. MEMBERSHIP
--    9. REGISTER          (triggers → classbalance, spotsAvailable)
--   10. EMPLOYEE
--   11. WORK_SCHEDULE     (triggers → PAYMENT)
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ────────────────────────────────────────────────────────────
--  1. MEMBERSHIP TYPES
-- ────────────────────────────────────────────────────────────
INSERT INTO MEMBERSHIP_TYPE (membershipTypeID, typeName, typeDescription, monthlyPrice, classesPerMonth) VALUES
(1, 'Drop-In',           'Pay per class using class packages. No monthly commitment.',           0.00, 0),
(2, 'Basic',             '4 classes per month. Perfect for beginners.',                         39.00, 4),
(3, 'Standard',          '8 classes per month. Most popular plan.',                             65.00, 8),
(4, 'Unlimited',         'Unlimited classes every month. Best value for regulars.',             99.00, NULL),
(5, 'Annual Unlimited',  'Unlimited classes, billed annually. Save 20% vs monthly.',           79.00, NULL);

-- ────────────────────────────────────────────────────────────
--  2. CLASS PACKAGES
-- ────────────────────────────────────────────────────────────
INSERT INTO CLASSPACKAGE (classpackageID, classpackagedesc, classpackageprice, numClasses) VALUES
(1, 'Single Class',    18.00,  1),
(2, '5-Class Pass',    80.00,  5),
(3, '10-Class Pass',  140.00, 10),
(4, '20-Class Pass',  240.00, 20);

-- ────────────────────────────────────────────────────────────
--  3. INSTRUCTORS
-- ────────────────────────────────────────────────────────────
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

-- ────────────────────────────────────────────────────────────
--  4. CUSTOMERS (25 members)
-- ────────────────────────────────────────────────────────────
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

-- ────────────────────────────────────────────────────────────
--  5. CLASSES (25 sessions across 5 days)
-- ────────────────────────────────────────────────────────────
INSERT INTO CLASS (classID, classname, classtemp, startTime, endTime, classDate, spotsAvailable, spotsTotal, instructorID, difficulty, description) VALUES
-- June 25
(1,  'Yoga Basics',      32.50, '08:00:00', '09:00:00', '2026-06-25', 20, 20, 1, 'Beginner',     'Foundation poses and breathing techniques for new yogis.'),
(2,  'Vinyasa Flow',     34.00, '10:00:00', '11:00:00', '2026-06-25', 15, 15, 1, 'Intermediate', 'A dynamic sequence linking breath to movement.'),
(3,  'Hatha Yoga',       31.00, '12:00:00', '13:00:00', '2026-06-25', 18, 18, 2, 'All Levels',   'Classic postures held with mindful alignment.'),
(4,  'Power Yoga',       35.00, '14:00:00', '15:00:00', '2026-06-25', 22, 22, 2, 'Advanced',     'High-intensity yoga for strength and endurance.'),
(5,  'Restorative Yoga', 30.00, '16:00:00', '17:00:00', '2026-06-25', 25, 25, 3, 'All Levels',   'Supported poses held for deep relaxation and recovery.'),
-- June 26
(6,  'Yin Yoga',         33.00, '08:00:00', '09:00:00', '2026-06-26', 18, 18, 3, 'All Levels',   'Long-held poses targeting deep connective tissue.'),
(7,  'Ashtanga Yoga',    36.00, '10:00:00', '11:00:00', '2026-06-26', 20, 20, 2, 'Advanced',     'A rigorous set sequence building heat and focus.'),
(8,  'Kundalini Yoga',   34.50, '12:00:00', '13:00:00', '2026-06-26', 15, 15, 4, 'All Levels',   'Dynamic kriyas and meditation to awaken energy.'),
(9,  'Chair Yoga',       28.00, '14:00:00', '15:00:00', '2026-06-26', 12, 12, 5, 'Beginner',     'Accessible yoga using a chair for support.'),
(10, 'Aerial Yoga',      37.00, '16:00:00', '17:00:00', '2026-06-26', 10, 10, 1, 'Intermediate', 'Yoga using a silk hammock for inversions and core work.'),
-- June 27
(11, 'Hot Yoga',         35.50, '08:00:00', '09:00:00', '2026-06-27', 22, 22, 2, 'All Levels',   'Flowing sequences in a heated room to build flexibility.'),
(12, 'Iyengar Yoga',     32.00, '10:00:00', '11:00:00', '2026-06-27', 18, 18, 1, 'All Levels',   'Precision alignment using props for therapeutic benefit.'),
(13, 'AcroYoga',         36.50, '12:00:00', '13:00:00', '2026-06-27', 15, 15, 4, 'Intermediate', 'Partner-based acrobatics and yoga — trust and play.'),
(14, 'Prenatal Yoga',    29.00, '14:00:00', '15:00:00', '2026-06-27', 20, 20, 5, 'All Levels',   'Gentle sequences designed for expectant mothers.'),
(15, 'Yoga for Seniors', 27.50, '16:00:00', '17:00:00', '2026-06-27', 18, 18, 5, 'Beginner',     'Low-impact yoga tailored for older adults.'),
-- June 28
(16, 'Core Power Yoga',  34.00, '08:00:00', '09:00:00', '2026-06-28', 25, 25, 2, 'Advanced',     'Strength-focused flow targeting core stability.'),
(17, 'Yoga Nidra',       30.50, '10:00:00', '11:00:00', '2026-06-28', 15, 15, 3, 'All Levels',   'Guided deep-relaxation practice — "yogic sleep".'),
(18, 'Mindfulness Yoga', 31.50, '12:00:00', '13:00:00', '2026-06-28', 20, 20, 3, 'All Levels',   'Slow, intentional movement paired with mindfulness cues.'),
(19, 'Pilates',          33.00, '14:00:00', '15:00:00', '2026-06-28', 18, 18, 4, 'All Levels',   'Core-centered movement system for posture and strength.'),
(20, 'Gentle Flow Yoga', 29.50, '16:00:00', '17:00:00', '2026-06-28', 22, 22, 5, 'Beginner',     'Soft flowing movements for stress relief.'),
-- June 29
(21, 'Beginner Yoga',    28.00, '08:00:00', '09:00:00', '2026-06-29', 20, 20, 5, 'Beginner',     'The perfect starting point for your yoga journey.'),
(22, 'Advanced Yoga',    36.00, '10:00:00', '11:00:00', '2026-06-29', 15, 15, 2, 'Advanced',     'Challenging sequences for experienced practitioners.'),
(23, 'Yoga Therapy',     32.50, '12:00:00', '13:00:00', '2026-06-29', 18, 18, 1, 'All Levels',   'Therapeutic yoga addressing specific physical concerns.'),
(24, 'Yoga Sculpt',      35.00, '14:00:00', '15:00:00', '2026-06-29', 22, 22, 4, 'Intermediate', 'Yoga with light weights for a full-body sculpting workout.'),
(25, 'Meditation Class', 25.00, '16:00:00', '17:00:00', '2026-06-29', 25, 25, 3, 'All Levels',   'Guided meditation for clarity, calm, and focus.');

-- ────────────────────────────────────────────────────────────
--  6. TEACHES  (auto-triggers INSTRUCTORPAYMENT for each row)
-- ────────────────────────────────────────────────────────────
INSERT INTO TEACHES (instructorID, classID) VALUES
(1,1),(1,2),(2,3),(2,4),(3,5),
(3,6),(2,7),(4,8),(5,9),(1,10),
(2,11),(1,12),(4,13),(5,14),(5,15),
(2,16),(3,17),(3,18),(4,19),(5,20),
(5,21),(2,22),(1,23),(4,24),(3,25);

-- ────────────────────────────────────────────────────────────
--  7. SALES  (auto-triggers classbalance update on CUSTOMER)
-- ────────────────────────────────────────────────────────────
INSERT INTO SALE (saleID, customerID, classpackageID, saleDate, paymentType, amountPaid) VALUES
(1,  1,  2, '2026-05-01', 'Credit Card', 80.00),
(2,  3,  3, '2026-05-03', 'Cash',       140.00),
(3,  5,  1, '2026-05-10', 'Credit Card', 18.00),
(4,  7,  2, '2026-05-12', 'Credit Card', 80.00),
(5,  9,  3, '2026-05-15', 'Cash',       140.00),
(6,  11, 2, '2026-05-20', 'Credit Card', 80.00),
(7,  13, 1, '2026-06-01', 'Credit Card', 18.00),
(8,  15, 3, '2026-06-05', 'Cash',       140.00),
(9,  17, 2, '2026-06-10', 'Credit Card', 80.00),
(10, 19, 1, '2026-06-15', 'Credit Card', 18.00),
(11, 2,  4, '2026-06-18', 'Credit Card', 240.00),
(12, 6,  3, '2026-06-19', 'Debit Card', 140.00),
(13, 10, 2, '2026-06-20', 'Credit Card', 80.00),
(14, 20, 3, '2026-06-21', 'PayPal',     140.00);

-- ────────────────────────────────────────────────────────────
--  8. MEMBERSHIPS
-- ────────────────────────────────────────────────────────────
INSERT INTO MEMBERSHIP (membershipID, customerID, membershipTypeID, startDate, endDate, status) VALUES
(1,  2,  4, '2026-01-01', NULL,         'ACTIVE'),
(2,  4,  3, '2026-03-01', NULL,         'ACTIVE'),
(3,  6,  4, '2025-06-01', NULL,         'ACTIVE'),
(4,  8,  2, '2026-05-01', '2026-08-01', 'ACTIVE'),
(5,  10, 5, '2025-01-01', '2026-01-01', 'EXPIRED'),
(6,  12, 3, '2026-02-01', NULL,         'ACTIVE'),
(7,  14, 4, '2026-04-01', NULL,         'ACTIVE'),
(8,  16, 5, '2026-01-01', '2027-01-01', 'ACTIVE'),
(9,  20, 4, '2025-09-01', NULL,         'ACTIVE'),
(10, 24, 2, '2026-06-01', NULL,         'ACTIVE');

-- ────────────────────────────────────────────────────────────
--  9. REGISTRATIONS  (auto-triggers balance & spot deduction)
--     NOTE: classbalance in CUSTOMER must be > 0 for each row
-- ────────────────────────────────────────────────────────────
INSERT INTO REGISTER (registerID, customerID, classID, registerDate, status) VALUES
(1,  2,  6,  '2026-06-20', 'REGISTERED'),
(2,  4,  8,  '2026-06-20', 'REGISTERED'),
(3,  6,  10, '2026-06-21', 'ATTENDED'),
(4,  8,  12, '2026-06-21', 'ATTENDED'),
(5,  10, 14, '2026-06-22', 'REGISTERED'),
(6,  12, 16, '2026-06-22', 'REGISTERED'),
(7,  14, 18, '2026-06-23', 'REGISTERED'),
(8,  16, 20, '2026-06-23', 'ATTENDED'),
(9,  18, 22, '2026-06-24', 'REGISTERED'),
(10, 20, 24, '2026-06-24', 'REGISTERED'),
(11, 3,  1,  '2026-06-24', 'REGISTERED'),
(12, 5,  3,  '2026-06-24', 'REGISTERED'),
(13, 7,  5,  '2026-06-24', 'CANCELLED'),   -- Cancelled: credits restored by trigger
(14, 9,  7,  '2026-06-24', 'ATTENDED'),
(15, 11, 9,  '2026-06-24', 'REGISTERED');

-- ────────────────────────────────────────────────────────────
--  10. EMPLOYEES
-- ────────────────────────────────────────────────────────────
INSERT INTO EMPLOYEE (employeeID, empfname, emplname, role, phone, hourlyRate) VALUES
(1, 'John',  'Smith',   'Desk Employee', '111-222-3333', 17.00),
(2, 'Alice', 'Johnson', 'Cleaner',       '555-666-7777', 15.00),
(3, 'Maria', 'Chen',    'Desk Employee', '444-555-6666', 17.00),
(4, 'Derek', 'Okafor',  'Manager',       '777-888-9999', 25.00);

-- ────────────────────────────────────────────────────────────
--  11. WORK SCHEDULES  (auto-triggers PAYMENT calculation)
-- ────────────────────────────────────────────────────────────
INSERT INTO WORK_SCHEDULE (scheduleID, employeeID, workDate, startTime, endTime) VALUES
(1, 1, '2026-06-25', '08:00:00', '16:00:00'),   -- John: 8 hrs → $136.00
(2, 2, '2026-06-25', '08:00:00', '12:00:00'),   -- Alice: 4 hrs → $60.00
(3, 2, '2026-06-25', '13:00:00', '17:00:00'),   -- Alice: 4 hrs → $60.00
(4, 3, '2026-06-25', '12:00:00', '20:00:00'),   -- Maria: 8 hrs → $136.00
(5, 4, '2026-06-25', '09:00:00', '17:00:00'),   -- Derek: 8 hrs → $200.00
(6, 1, '2026-06-26', '08:00:00', '16:00:00'),   -- John: 8 hrs → $136.00
(7, 3, '2026-06-26', '12:00:00', '20:00:00'),   -- Maria: 8 hrs → $136.00
(8, 2, '2026-06-26', '08:00:00', '12:00:00'),   -- Alice: 4 hrs → $60.00
(9, 4, '2026-06-26', '09:00:00', '17:00:00');   -- Derek: 8 hrs → $200.00

SET FOREIGN_KEY_CHECKS = 1;

-- ────────────────────────────────────────────────────────────
--  VERIFICATION QUERIES
--  Run these after seeding to confirm everything loaded cleanly
-- ────────────────────────────────────────────────────────────

-- Row counts
SELECT 'CUSTOMER'         AS tbl, COUNT(*) AS rows FROM CUSTOMER         UNION ALL
SELECT 'INSTRUCTOR',             COUNT(*)          FROM INSTRUCTOR        UNION ALL
SELECT 'CLASS',                  COUNT(*)          FROM CLASS             UNION ALL
SELECT 'CLASSPACKAGE',           COUNT(*)          FROM CLASSPACKAGE      UNION ALL
SELECT 'MEMBERSHIP_TYPE',        COUNT(*)          FROM MEMBERSHIP_TYPE   UNION ALL
SELECT 'MEMBERSHIP',             COUNT(*)          FROM MEMBERSHIP        UNION ALL
SELECT 'TEACHES',                COUNT(*)          FROM TEACHES           UNION ALL
SELECT 'INSTRUCTORPAYMENT',      COUNT(*)          FROM INSTRUCTORPAYMENT UNION ALL
SELECT 'SALE',                   COUNT(*)          FROM SALE              UNION ALL
SELECT 'REGISTER',               COUNT(*)          FROM REGISTER          UNION ALL
SELECT 'EMPLOYEE',               COUNT(*)          FROM EMPLOYEE          UNION ALL
SELECT 'WORK_SCHEDULE',          COUNT(*)          FROM WORK_SCHEDULE     UNION ALL
SELECT 'PAYMENT',                COUNT(*)          FROM PAYMENT;

-- Confirm trigger-created records exist
SELECT 'Instructor payments auto-created:' AS check_item, COUNT(*) AS result FROM INSTRUCTORPAYMENT
UNION ALL
SELECT 'Employee payments auto-created:', COUNT(*) FROM PAYMENT;
