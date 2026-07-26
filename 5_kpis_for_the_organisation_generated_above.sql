
/* 
Script name: kpis_for_the_organisation_generated_above
Description:  Creates and assigns key performance indicators to the employees in the fictional HR database,
              while also simulating that only approximately 85% of the organisation has completed this task.
*/

/*
Creating the core tables
*/
DROP TABLE IF EXISTS dim_kpi_library CASCADE;

CREATE TABLE dim_kpi_library (
    kpi_id SERIAL PRIMARY KEY,
    department VARCHAR(50),
    kpi_name VARCHAR(100),
    kpi_description TEXT
);

-- Insert KPIs
INSERT INTO dim_kpi_library (department, kpi_name, kpi_description)
VALUES
    ('Engineering', 'Engineering KPI', 'Description string'),
    ('Sales', 'Sales KPI', 'Description string'),
    ('HR', 'HR KPI', 'Description string');

-- 2. Create the KPI Assignment Fact Table
DROP TABLE IF EXISTS fact_employee_kpi CASCADE;

CREATE TABLE fact_employee_kpi AS
WITH active_employees AS (
    -- Only assign KPIs to active employees
    SELECT 
        employee_id,
        department
    FROM all_employees_in_hris5
    WHERE status = 'Active'
),
compliance_filter AS (
    -- Approximately 15% of employees forgot to set their performance indicaters
    SELECT 
        employee_id,
        department
    FROM active_employees
    WHERE random() > 0.15 
),
kpi_count_allocation AS (
    -- Allocate 1 to 3 KPIs per employee
    SELECT 
        employee_id,
        department,
        generate_series(1, floor(random() * 3 + 1)::INT) AS kpi_slot
    FROM compliance_filter
),
kpi_assignment AS (
    -- Creating kpi_assignment and preventing duplicate identical KPIs per employee
    SELECT 
        a.employee_id,
        a.department,
        a.kpi_slot,
        d.kpi_id,
        ROW_NUMBER() OVER(PARTITION BY a.employee_id ORDER BY random()) as shuffle_rank
    FROM kpi_count_allocation a
    JOIN dim_kpi_library d ON a.department = d.department
)
SELECT 
    employee_id,
    kpi_id,
    '2026-01-01'::DATE AS kpi_start_date,
    '2026-12-31'::DATE AS kpi_end_date
FROM kpi_assignment
WHERE kpi_slot = shuffle_rank;

ALTER TABLE fact_employee_kpi
ADD CONSTRAINT fk_employee FOREIGN KEY (employee_id) REFERENCES all_employees_in_hris5 (employee_id),
ADD CONSTRAINT fk_kpi FOREIGN KEY (kpi_id) REFERENCES dim_kpi_library (kpi_id);

/*
View to connect with BI tool
*/


CREATE OR REPLACE VIEW v_kpi_excel_export AS
SELECT 
    allemp.employee_id,
    allemp.department,
    allemp.job_title,
    allemp.status,
    allemp.manager_id,
    kpi_dim.kpi_name,
    kpi_dim.kpi_description,
    kpi_fact.kpi_start_date,
    kpi_fact.kpi_end_date
FROM 
    all_employees_in_hris5  allemp

LEFT JOIN 
    fact_employee_kpi kpi_fact ON allemp.employee_id = kpi_fact.employee_id
LEFT JOIN 
    dim_kpi_library kpi_dim ON kpi_fact.kpi_id = kpi_dim.kpi_id
WHERE 
    allemp.status = 'Active';

select *
from v_kpi_excel_export;
