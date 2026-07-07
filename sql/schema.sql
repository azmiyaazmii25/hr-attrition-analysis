-- ============================================
-- HR Attrition Analysis — Database Schema
-- MySQL 8.0+
-- ============================================

DROP DATABASE IF EXISTS hr_attrition;
CREATE DATABASE hr_attrition;
USE hr_attrition;

-- Departments table
CREATE TABLE departments (
    dept_id     INT PRIMARY KEY,
    dept_name   VARCHAR(50) NOT NULL,
    location    VARCHAR(50) NOT NULL
);

-- Employees table
CREATE TABLE employees (
    emp_id             INT PRIMARY KEY,
    first_name         VARCHAR(50) NOT NULL,
    last_name          VARCHAR(50) NOT NULL,
    gender             VARCHAR(1) NOT NULL,
    dept_id            INT NOT NULL,
    job_title          VARCHAR(50) NOT NULL,
    hire_date          DATE NOT NULL,
    termination_date   DATE NULL,          -- NULL = still employed
    salary             INT NOT NULL,        -- annual salary in INR
    manager_id         INT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id)
);

-- Performance reviews table
CREATE TABLE performance_reviews (
    review_id    INT PRIMARY KEY,
    emp_id       INT NOT NULL,
    review_date  DATE NOT NULL,
    rating       INT NOT NULL,   -- 1 (poor) to 5 (excellent)
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);

-- Helpful indexes for query performance
CREATE INDEX idx_emp_dept ON employees(dept_id);
CREATE INDEX idx_emp_manager ON employees(manager_id);
CREATE INDEX idx_review_emp ON performance_reviews(emp_id);
