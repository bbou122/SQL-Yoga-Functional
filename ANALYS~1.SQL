-- ============================================================
--  ZenFlow Yoga Studio — Business Analysis Queries
--  Author: Braden Bourgeois
--
--  A collection of real business questions answered in SQL,
--  demonstrating analytical thinking, JOINs, aggregations,
--  subqueries, window functions, and CTEs.
-- ============================================================


-- ────────────────────────────────────────────────────────────
--  1. REVENUE ANALYSIS
--     Total revenue by month, with running total
-- ────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(s.saleDate, '%Y-%m')          AS sale_month,
    COUNT(s.saleID)                           AS total_transactions,
    SUM(s.amountPaid)                         AS monthly_revenue,
    SUM(SUM(s.amountPaid)) OVER (
        ORDER BY DATE_FORMAT(s.saleDate, '%Y-%m')
    )                                         AS running_total_revenue,
    AVG(s.amountPaid)                         AS avg_transaction_value
FROM SALE s
GROUP BY DATE_FORMAT(s.saleDate, '%Y-%m')
ORDER BY sale_month;


-- ────────────────────────────────────────────────────────────
--  2. MOST POPULAR CLASSES
--     Ranked by total registrations, with fill rate
-- ────────────────────────────────────────────────────────────
SELECT
    c.classname,
    c.difficulty,
    c.classDate,
    CONCAT(i.instfname, ' ', i.instlname)     AS instructor,
    c.spotsTotal                              AS capacity,
    COUNT(r.registerID)                       AS total_registered,
    SUM(CASE WHEN r.status = 'ATTENDED' THEN 1 ELSE 0 END) AS attended,
    ROUND(COUNT(r.registerID) / c.spotsTotal * 100, 1)     AS fill_rate_pct,
    ROUND(SUM(CASE WHEN r.status = 'ATTENDED' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(r.registerID), 0) * 100, 1)       AS attendance_rate_pct
FROM CLASS c
LEFT JOIN REGISTER r  ON c.classID      = r.classID AND r.status != 'CANCELLED'
LEFT JOIN INSTRUCTOR i ON c.instructorID = i.instructorID
GROUP BY c.classID, c.classname, c.difficulty, c.classDate, instructor, c.spotsTotal
ORDER BY fill_rate_pct DESC, total_registered DESC;


-- ────────────────────────────────────────────────────────────
--  3. INSTRUCTOR PERFORMANCE
--     Who drives the most engagement and revenue?
-- ────────────────────────────────────────────────────────────
SELECT
    CONCAT(i.instfname, ' ', i.instlname)     AS instructor,
    i.specialty,
    COUNT(DISTINCT c.classID)                 AS classes_taught,
    COUNT(r.registerID)                       AS total_students,
    SUM(CASE WHEN r.status = 'ATTENDED' THEN 1 ELSE 0 END) AS total_attended,
    ROUND(AVG(
        (c.spotsTotal - c.spotsAvailable) / c.spotsTotal * 100
    ), 1)                                     AS avg_fill_rate_pct,
    SUM(ip.paymentAmount)                     AS total_instructor_pay
FROM INSTRUCTOR i
LEFT JOIN CLASS             c  ON i.instructorID  = c.instructorID
LEFT JOIN REGISTER          r  ON c.classID       = r.classID AND r.status != 'CANCELLED'
LEFT JOIN INSTRUCTORPAYMENT ip ON i.instructorID  = ip.instructorID
GROUP BY i.instructorID, instructor, i.specialty
ORDER BY total_students DESC;


-- ────────────────────────────────────────────────────────────
--  4. CUSTOMER LIFETIME VALUE
--     Total spend, classes booked, and membership status
-- ────────────────────────────────────────────────────────────
SELECT
    CONCAT(cu.fname, ' ', cu.lname)           AS customer,
    cu.email,
    cu.joindate,
    DATEDIFF(CURRENT_DATE, cu.joindate)       AS days_as_member,
    COUNT(DISTINCT s.saleID)                  AS total_purchases,
    COALESCE(SUM(s.amountPaid), 0)            AS total_spent,
    COUNT(DISTINCT r.registerID)              AS classes_booked,
    SUM(CASE WHEN r.status = 'ATTENDED' THEN 1 ELSE 0 END) AS classes_attended,
    cu.classbalance                           AS current_credit_balance,
    COALESCE(mt.typeName, 'Drop-In')          AS membership_plan
FROM CUSTOMER cu
LEFT JOIN SALE          s  ON cu.customerID      = s.customerID
LEFT JOIN REGISTER      r  ON cu.customerID      = r.customerID
LEFT JOIN MEMBERSHIP    m  ON cu.customerID      = m.customerID AND m.status = 'ACTIVE'
LEFT JOIN MEMBERSHIP_TYPE mt ON m.membershipTypeID = mt.membershipTypeID
GROUP BY cu.customerID, customer, cu.email, cu.joindate, cu.classbalance, membership_plan
ORDER BY total_spent DESC;


-- ────────────────────────────────────────────────────────────
--  5. CHURN RISK — CUSTOMERS WITH LOW ENGAGEMENT
--     Members who haven't booked a class in over 30 days
-- ────────────────────────────────────────────────────────────
SELECT
    CONCAT(cu.fname, ' ', cu.lname)           AS customer,
    cu.email,
    cu.classbalance                           AS unused_credits,
    MAX(r.registerDate)                       AS last_booking_date,
    DATEDIFF(CURRENT_DATE, MAX(r.registerDate)) AS days_since_last_booking,
    COALESCE(mt.typeName, 'Drop-In')          AS membership_plan
FROM CUSTOMER cu
LEFT JOIN REGISTER     r  ON cu.customerID      = r.customerID AND r.status != 'CANCELLED'
LEFT JOIN MEMBERSHIP   m  ON cu.customerID      = m.customerID AND m.status = 'ACTIVE'
LEFT JOIN MEMBERSHIP_TYPE mt ON m.membershipTypeID = mt.membershipTypeID
GROUP BY cu.customerID, customer, cu.email, cu.classbalance, membership_plan
HAVING last_booking_date IS NULL
    OR DATEDIFF(CURRENT_DATE, MAX(r.registerDate)) > 30
ORDER BY days_since_last_booking DESC;


-- ────────────────────────────────────────────────────────────
--  6. CLASS PACKAGE POPULARITY
--     Which packages sell best and generate the most revenue?
-- ────────────────────────────────────────────────────────────
SELECT
    cp.classpackagedesc                        AS package,
    cp.classpackageprice                       AS price,
    cp.numClasses                              AS classes_included,
    ROUND(cp.classpackageprice / cp.numClasses, 2) AS price_per_class,
    COUNT(s.saleID)                            AS times_sold,
    SUM(s.amountPaid)                          AS total_revenue,
    ROUND(COUNT(s.saleID) * 100.0 /
        SUM(COUNT(s.saleID)) OVER (), 1)       AS pct_of_all_sales
FROM CLASSPACKAGE cp
LEFT JOIN SALE s ON cp.classpackageID = s.classpackageID
GROUP BY cp.classpackageID, package, price, classes_included, price_per_class
ORDER BY total_revenue DESC;


-- ────────────────────────────────────────────────────────────
--  7. PEAK HOURS ANALYSIS
--     Which time slots fill fastest?
-- ────────────────────────────────────────────────────────────
SELECT
    c.startTime                               AS class_time,
    COUNT(DISTINCT c.classID)                 AS num_classes_offered,
    COUNT(r.registerID)                       AS total_registrations,
    ROUND(AVG(
        (c.spotsTotal - c.spotsAvailable) / c.spotsTotal * 100
    ), 1)                                     AS avg_fill_rate_pct,
    CASE
        WHEN c.startTime < '09:00:00' THEN 'Early Morning'
        WHEN c.startTime < '12:00:00' THEN 'Morning'
        WHEN c.startTime < '15:00:00' THEN 'Afternoon'
        ELSE 'Evening'
    END                                       AS time_of_day
FROM CLASS c
LEFT JOIN REGISTER r ON c.classID = r.classID AND r.status != 'CANCELLED'
GROUP BY c.startTime, time_of_day
ORDER BY avg_fill_rate_pct DESC;


-- ────────────────────────────────────────────────────────────
--  8. NEW MEMBER COHORT ANALYSIS
--     How many members joined each month? (growth tracking)
-- ────────────────────────────────────────────────────────────
SELECT
    DATE_FORMAT(joindate, '%Y-%m')            AS cohort_month,
    COUNT(customerID)                         AS new_members,
    SUM(COUNT(customerID)) OVER (
        ORDER BY DATE_FORMAT(joindate, '%Y-%m')
    )                                         AS cumulative_members
FROM CUSTOMER
GROUP BY DATE_FORMAT(joindate, '%Y-%m')
ORDER BY cohort_month;


-- ────────────────────────────────────────────────────────────
--  9. CANCELLATION RATE BY CLASS TYPE
--     Which classes have the most cancellations?
-- ────────────────────────────────────────────────────────────
SELECT
    c.classname,
    c.difficulty,
    COUNT(r.registerID)                       AS total_bookings,
    SUM(CASE WHEN r.status = 'CANCELLED' THEN 1 ELSE 0 END)  AS cancellations,
    SUM(CASE WHEN r.status = 'ATTENDED'  THEN 1 ELSE 0 END)  AS attended,
    ROUND(SUM(CASE WHEN r.status = 'CANCELLED' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(r.registerID), 0) * 100, 1)         AS cancellation_rate_pct
FROM CLASS c
JOIN REGISTER r ON c.classID = r.classID
GROUP BY c.classID, c.classname, c.difficulty
HAVING total_bookings > 0
ORDER BY cancellation_rate_pct DESC;


-- ────────────────────────────────────────────────────────────
--  10. PAYROLL SUMMARY
--      Total labor cost by role and employee
-- ────────────────────────────────────────────────────────────
SELECT
    CONCAT(e.empfname, ' ', e.emplname)       AS employee,
    e.role,
    e.hourlyRate,
    COUNT(ws.scheduleID)                      AS shifts_worked,
    SUM(TIMESTAMPDIFF(MINUTE, ws.startTime, ws.endTime)) / 60.0 AS total_hours,
    SUM(p.paymentAmount)                      AS total_paid
FROM EMPLOYEE e
LEFT JOIN WORK_SCHEDULE ws ON e.employeeID = ws.employeeID
LEFT JOIN PAYMENT        p  ON e.employeeID = p.employeeID
GROUP BY e.employeeID, employee, e.role, e.hourlyRate
ORDER BY total_paid DESC;


-- ────────────────────────────────────────────────────────────
--  BONUS: TOP CUSTOMERS THIS MONTH (using CTE)
--     Demonstrates CTE + date filtering pattern
-- ────────────────────────────────────────────────────────────
WITH monthly_activity AS (
    SELECT
        r.customerID,
        COUNT(r.registerID)  AS classes_this_month
    FROM REGISTER r
    WHERE r.registerDate >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
      AND r.status != 'CANCELLED'
    GROUP BY r.customerID
),
monthly_spend AS (
    SELECT
        s.customerID,
        SUM(s.amountPaid)    AS spent_this_month
    FROM SALE s
    WHERE s.saleDate >= DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
    GROUP BY s.customerID
)
SELECT
    CONCAT(cu.fname, ' ', cu.lname)           AS customer,
    cu.email,
    COALESCE(ma.classes_this_month, 0)        AS classes_booked,
    COALESCE(ms.spent_this_month, 0)          AS amount_spent,
    cu.classbalance                           AS credit_balance
FROM CUSTOMER cu
LEFT JOIN monthly_activity ma ON cu.customerID = ma.customerID
LEFT JOIN monthly_spend    ms ON cu.customerID = ms.customerID
WHERE ma.classes_this_month > 0 OR ms.spent_this_month > 0
ORDER BY classes_booked DESC, amount_spent DESC
LIMIT 10;
