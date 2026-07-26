/*
Script: HRIS Schema Setup
Description: Creates the main table for the HRIS dataset.
*/
DROP TABLE IF EXISTS all_employees_in_hris5;

CREATE TABLE all_employees_in_hris5 (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    job_level INT,
    job_title VARCHAR(100),
    pay_grade VARCHAR(20),
    annual_salary_USD INT,
    country VARCHAR(50),
    region VARCHAR(10),
    manager_id INT,
    hire_date DATE,
    status VARCHAR(20),
    termination_date DATE
);
