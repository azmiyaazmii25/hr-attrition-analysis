-- =====================================================================
-- HR ATTRITION ANALYSIS — QUERY WALKTHROUGH
-- Organized by difficulty level so you learn progressively.
-- Run schema.sql and seed_data.sql first.
-- =====================================================================


-- =====================================================================
-- LEVEL 1: BASIC SELECT / WHERE / ORDER BY
-- (You already know this — warm-up + sanity checks on the data)
-- =====================================================================

-- 1.1 List all employees who have left the company
SELECT first_name, last_name, job_title, termination_date
FROM employees
WHERE termination_date IS NOT NULL
ORDER BY termination_date DESC;

-- 1.2 List employees earning more than 10 lakh (1,000,000) per year
SELECT first_name, last_name, job_title, salary
FROM employees
WHERE salary > 1000000
ORDER BY salary DESC;

-- 1.3 List employees hired in 2023
SELECT first_name, last_name, hire_date
FROM employees
WHERE YEAR(hire_date) = 2023;


-- =====================================================================
-- LEVEL 2: AGGREGATION + GROUP BY
-- (Turning rows into business numbers)
-- =====================================================================

-- 2.1 Headcount per department
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id;

-- 2.2 Average salary by job title
SELECT job_title, ROUND(AVG(salary), 0) AS avg_salary, COUNT(*) AS num_employees
FROM employees
GROUP BY job_title
ORDER BY avg_salary DESC;

-- 2.3 How many employees have left vs are still active?
SELECT
    CASE WHEN termination_date IS NULL THEN 'Active' ELSE 'Left' END AS status,
    COUNT(*) AS num_employees
FROM employees
GROUP BY status;


-- =====================================================================
-- LEVEL 3: JOINS
-- (Combining tables — this is what most interview SQL tests are about)
-- =====================================================================

-- 3.1 Employee list with department name (INNER JOIN)
SELECT e.first_name, e.last_name, d.dept_name, d.location, e.job_title
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- 3.2 Every employee with their manager's name (SELF JOIN)
-- This is a very common interview question: "join a table to itself"
SELECT
    emp.first_name AS employee_first_name,
    emp.last_name  AS employee_last_name,
    mgr.first_name AS manager_first_name,
    mgr.last_name  AS manager_last_name
FROM employees emp
LEFT JOIN employees mgr ON emp.manager_id = mgr.emp_id
ORDER BY manager_last_name;

-- 3.3 Departments with NO leavers at all (LEFT JOIN + filtering NULLs)
-- Shows you understand LEFT JOIN vs INNER JOIN behavior
SELECT d.dept_name
FROM departments d
LEFT JOIN employees e
    ON d.dept_id = e.dept_id AND e.termination_date IS NOT NULL
WHERE e.emp_id IS NULL;


-- =====================================================================
-- LEVEL 4: THE CORE BUSINESS QUESTION — ATTRITION
-- (This is the heart of the case study — what interviewers actually care about)
-- =====================================================================

-- 4.1 Overall attrition rate
SELECT
    COUNT(*) AS total_employees,
    SUM(CASE WHEN termination_date IS NOT NULL THEN 1 ELSE 0 END) AS total_leavers,
    ROUND(100.0 * SUM(CASE WHEN termination_date IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS attrition_rate_pct
FROM employees;

-- 4.2 Attrition rate BY DEPARTMENT (this is the finding that drives the recommendation)
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS headcount,
    SUM(CASE WHEN e.termination_date IS NOT NULL THEN 1 ELSE 0 END) AS leavers,
    ROUND(100.0 * SUM(CASE WHEN e.termination_date IS NOT NULL THEN 1 ELSE 0 END) / COUNT(e.emp_id), 2) AS attrition_rate_pct
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
ORDER BY attrition_rate_pct DESC;

-- 4.3 Average tenure (in months) of employees who left, by department
-- DATEDIFF gives days; divide by 30 for approx months
SELECT
    d.dept_name,
    ROUND(AVG(DATEDIFF(e.termination_date, e.hire_date)) / 30, 1) AS avg_tenure_months
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.termination_date IS NOT NULL
GROUP BY d.dept_name
ORDER BY avg_tenure_months ASC;

-- 4.4 Does pay correlate with attrition? Compare avg salary: leavers vs stayers
SELECT
    CASE WHEN termination_date IS NULL THEN 'Active' ELSE 'Left' END AS status,
    ROUND(AVG(salary), 0) AS avg_salary
FROM employees
GROUP BY status;


-- =====================================================================
-- LEVEL 5: CTEs (Common Table Expressions)
-- (Makes complex queries readable — interviewers love seeing clean CTEs
--  instead of deeply nested subqueries)
-- =====================================================================

-- 5.1 Rewrite of 4.2 using a CTE — same result, cleaner structure
WITH dept_attrition AS (
    SELECT
        d.dept_name,
        COUNT(e.emp_id) AS headcount,
        SUM(CASE WHEN e.termination_date IS NOT NULL THEN 1 ELSE 0 END) AS leavers
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
    GROUP BY d.dept_name
)
SELECT
    dept_name,
    headcount,
    leavers,
    ROUND(100.0 * leavers / headcount, 2) AS attrition_rate_pct
FROM dept_attrition
ORDER BY attrition_rate_pct DESC;

-- 5.2 CTE + filtering: departments with above-average attrition
WITH dept_attrition AS (
    SELECT
        d.dept_name,
        COUNT(e.emp_id) AS headcount,
        SUM(CASE WHEN e.termination_date IS NOT NULL THEN 1 ELSE 0 END) AS leavers,
        100.0 * SUM(CASE WHEN e.termination_date IS NOT NULL THEN 1 ELSE 0 END) / COUNT(e.emp_id) AS attrition_rate_pct
    FROM employees e
    JOIN departments d ON e.dept_id = d.dept_id
    GROUP BY d.dept_name
)
SELECT dept_name, ROUND(attrition_rate_pct, 2) AS attrition_rate_pct
FROM dept_attrition
WHERE attrition_rate_pct > (SELECT AVG(attrition_rate_pct) FROM dept_attrition);


-- =====================================================================
-- LEVEL 6: WINDOW FUNCTIONS
-- (The #1 differentiator between junior and mid-level analysts in interviews)
-- =====================================================================

-- 6.1 RANK employees by salary within their department
SELECT
    e.first_name, e.last_name, d.dept_name, e.salary,
    RANK() OVER (PARTITION BY d.dept_name ORDER BY e.salary DESC) AS salary_rank_in_dept
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.termination_date IS NULL
ORDER BY d.dept_name, salary_rank_in_dept;

-- 6.2 Track rating TREND per employee using LAG()
-- LAG lets you compare a row to the PREVIOUS row for the same employee
-- This answers: "did performance ratings drop before someone left?"
SELECT
    p.emp_id,
    e.first_name,
    e.last_name,
    p.review_date,
    p.rating,
    LAG(p.rating) OVER (PARTITION BY p.emp_id ORDER BY p.review_date) AS previous_rating,
    p.rating - LAG(p.rating) OVER (PARTITION BY p.emp_id ORDER BY p.review_date) AS rating_change
FROM performance_reviews p
JOIN employees e ON p.emp_id = e.emp_id
ORDER BY p.emp_id, p.review_date;

-- 6.3 Running headcount growth over time by hire month
-- Uses a window function to compute a cumulative (running) total
SELECT
    hire_month,
    new_hires,
    SUM(new_hires) OVER (ORDER BY hire_month) AS running_headcount
FROM (
    SELECT DATE_FORMAT(hire_date, '%Y-%m') AS hire_month, COUNT(*) AS new_hires
    FROM employees
    GROUP BY hire_month
) monthly_hires
ORDER BY hire_month;

-- 6.4 Pay-equity check: average salary by gender within same job title
-- A very common real-world HR analytics question
SELECT
    job_title,
    gender,
    ROUND(AVG(salary), 0) AS avg_salary,
    COUNT(*) AS num_employees
FROM employees
GROUP BY job_title, gender
ORDER BY job_title, gender;
