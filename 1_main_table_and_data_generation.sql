/*
---------------------------------------------------------------------
Script: Main table and data generation
Description: Creates the main table structure and generates 3000 realistic 
             employee records for the HRIS dataset.
---------------------------------------------------------------------
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
/* 
---------------------------------------------------------------------
Business compensation rules (summarised im dimensional lookup tables)
---------------------------------------------------------------------
*/

DROP TABLE IF EXISTS location_dimension;
CREATE TEMP TABLE location_dimension AS
SELECT * FROM (VALUES 
    ('United States', 'NAM',  1.00),
    ('Canada',        'NAM',  0.85),
    ('Mexico',        'NAM',  0.60),
    ('United Kingdom','EMEA', 0.85),
    ('Germany',       'EMEA', 0.85),
    ('France',        'EMEA', 0.85),
    ('Spain',         'EMEA', 0.85),
    ('Hungary',       'EMEA', 0.60),
    ('Japan',         'APAC', 0.85),
    ('Australia',     'APAC', 1.00),
    ('Singapore',     'APAC', 1.00),
    ('India',         'APAC', 0.60)
) AS t(country, region, cost_multiplier);

DROP TABLE IF EXISTS pay_bands;
CREATE TEMP TABLE pay_bands AS
SELECT * FROM (VALUES 
    (1, 'Professional1', 60000,  0.15, 'Associate'),
    (2, 'Professional2', 85000,  0.15, 'Analyst'),
    (3, 'Manager1',      120000, 0.20, 'Manager'),
    (4, 'Manager2',      170000, 0.20, 'Director'),
    (5, 'Executive1',    250000, 0.30, 'VP'),
    (6, 'Executive2',    400000, 0.40, 'CEO')
) AS t(job_level, pay_grade, us_midpoint, pay_range_spread, title_suffix);


/*
---------------------------------------------------------------------
 Generating employees based on criterias
---------------------------------------------------------------------
*/

WITH employee_spine AS (
    --generating the employee id-s for 3000 employees and assigning a randomised hire date
    SELECT 
        id AS seq_id, 
        CURRENT_DATE - CAST(floor(random() * 3650) AS INT) AS hire_date
    FROM generate_series(1, 3000) AS id
),


employee_attributes AS (
    SELECT 
        seq_id,
        hire_date,
        -- names: the array contains 8 random names, then the algorithm choses between their numbers (between one and 8)
        (ARRAY['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda'])[floor(random()*8)+1] AS first_name,
        (ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'])[floor(random()*8)+1] AS last_name,
        
        -- CEO is "executive", everyone else works in a sub-department department
        CASE WHEN seq_id = 1 THEN 'Executive'
             ELSE (ARRAY['Engineering', 'Sales', 'HR', 'Finance', 'Marketing', 'Operations'])[floor(random()*6) + 1]
        END AS department,
        
        (ARRAY['United States', 'Canada', 'Mexico', 'United Kingdom', 'Hungary', 'Germany', 'France', 'Spain', 'Japan', 'India', 'Australia', 'Singapore'])[floor(random()*12)+1] AS country
    FROM employee_spine 
),

ranked_departments AS (
    -- Employees with the earliest hire dates will be the departmental leaders
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY department ORDER BY seq_id) as dept_tenure_rank
    FROM employee_attributes
),

job_level_and_status AS (
    SELECT 
        *,
        -- Creating job levels
        CASE 
            WHEN seq_id = 1 THEN 6 
            WHEN dept_tenure_rank = 1 THEN 5 
            WHEN dept_tenure_rank = 2 THEN 4 
            WHEN dept_tenure_rank = 3 THEN 3 
            WHEN dept_tenure_rank = 4 THEN 2 
            WHEN dept_tenure_rank = 5 THEN 1 
            ELSE 
                CASE 
                    WHEN random() < 0.40 THEN 1 
                    WHEN random() < 0.75 THEN 2 
                    WHEN random() < 0.90 THEN 3 
                    WHEN random() < 0.98 THEN 4 
                    ELSE 5 
                END
        END AS job_level,
        
        -- Employees must not have terminated managers -> 
        -- due to the small headcount, only below level 5 employees can be terminated
        CASE 
            WHEN seq_id = 1 OR dept_tenure_rank <= 5 THEN 'Active'
            WHEN random() < 0.15 THEN 'Terminated'   -- terminations, calculates with a 15% average attrition
            ELSE 'Active' 
        END AS emp_status
    FROM ranked_departments
),

reporting_lines AS (
    /* 
    Employees must report to a randomly assigned, active manager exactly one level up 
    within their own department.
    */
    SELECT 
        e.*,
        CASE 
            WHEN e.seq_id = 1 THEN NULL -- CEO
            WHEN e.job_level = 5 THEN 1 -- VPs report directly to CEO
            ELSE 
                (SELECT m.seq_id 
                 FROM job_level_and_status m 
                 WHERE m.department = e.department      
                   AND m.job_level = e.job_level + 1    
                   AND m.emp_status = 'Active'           
                 ORDER BY m.job_level ASC, random() 
                 LIMIT 1
                )
        END AS manager_id
    FROM job_level_and_status e

)
/*
---------------------------------------------------------------------
Populating all_employees_in_hris_main table
---------------------------------------------------------------------
*/
INSERT INTO all_employees_in_hris5
SELECT 
    r.seq_id AS employee_id,
    r.first_name,
    r.last_name,
    r.department,
    r.job_level,
    
    -- Creating job titles
    CASE 
        WHEN r.seq_id = 1 THEN 'CEO'
        WHEN r.job_level = 5 THEN 'VP of ' || r.department
        ELSE r.department || ' ' || pb.title_suffix
    END AS job_title,
    
    pb.pay_grade,
    
    -- Calculating salary based on localised company rules
    CAST(
        (pb.us_midpoint * loc.cost_multiplier) * 
        (1 + ((random() * (pb.pay_range_spread * 2)) - pb.pay_range_spread))   
        --creates +/- swing around the midpoint than adds it to the salary, creating the pay range spread
    AS INT) AS annual_salary_USD,
    
    r.country,
    loc.region,
    r.manager_id,
    r.hire_date,
    r.emp_status AS status,
    
    CASE 
        WHEN r.emp_status = 'Terminated' 
        THEN r.hire_date + CAST(floor(random() * (CURRENT_DATE - r.hire_date)) AS INT)
        ELSE NULL 
    END AS termination_date

FROM reporting_lines r
LEFT JOIN location_dimension loc ON r.country = loc.country
LEFT JOIN pay_bands pb ON r.job_level = pb.job_level;
