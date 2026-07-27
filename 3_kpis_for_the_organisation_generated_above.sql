
/* 
---------------------------------------------------------------------
Script name: kpis_for_the_organisation_generated_above
Description:  Creates and assigns key performance indicators to the employees in the fictional HR database,
              while also simulating that only approximately 85% of the organisation has completed this task.
---------------------------------------------------------------------
*/

/*
Creating the core tables
*/
DROP TABLE IF EXISTS kpi_options_table CASCADE;

CREATE TABLE kpi_options_table (
    kpi_id SERIAL PRIMARY KEY,
    department VARCHAR(50),
    kpi_name VARCHAR(100),
    kpi_description TEXT
);

-- Insert KPIs
INSERT INTO kpi_options_table (department, kpi_name, kpi_description)
VALUES
    ('Engineering', 'Engineering KPI1', 'Description string'),
    ('Engineering', 'Engineering KPI2', 'Description string'),
    ('Engineering', 'Engineering KPI3', 'Description string'),
    ('Sales', 'Sales KPI1', 'Description string'),
    ('Sales', 'Sales KPI2', 'Description string'),
    ('Sales', 'Sales KPI3', 'Description string'),
    ('HR', 'HR KPI1', 'Description string'),
    ('HR', 'HR KPI2', 'Description string'),
    ('HR', 'HR KPI3', 'Description string'),
    ('Finance', 'Finance KPI1', 'Description string'),
    ('Finance', 'Finance KPI2', 'Description string'),
    ('Finance', 'Finance KPI3', 'Description string'),
    ('Marketing', 'Marketing KPI1', 'Description string'),
    ('Marketing', 'Marketing KPI2', 'Description string'),
    ('Marketing', 'Marketing KPI3', 'Description string'),
    ('Operations', 'Operations KPI1', 'Description string'),
    ('Operations', 'Operations KPI2', 'Description string'),
    ('Operations', 'Operations KPI3', 'Description string'),
    ('Executive', 'Executive KPI1', 'Description string'),
    ('Executive', 'Executive KPI2', 'Description string'),
    ('Executive', 'Executive KPI3', 'Description string');

-- 2. Create the KPI Assignment Fact Table
DROP TABLE IF EXISTS fact_employee_kpi CASCADE;

CREATE TABLE fact_employee_kpi AS
WITH active_employees AS (
    SELECT 
        employee_id,
        department
    FROM all_employees_in_hris5
    WHERE status = 'Active'
),
compliance_filter AS (
    -- ~85% has KPIs, between 1 and 3 per person
    SELECT 
        employee_id,
        department,
        floor(random() * 3 + 1)::INT AS target_kpi_count
    FROM active_employees
    WHERE random() > 0.15 
),
shuffled_kpis AS (
    -- Join employees to all available KPIs in their department and shuffle them
    SELECT 
        c.employee_id,
        c.target_kpi_count,
        d.kpi_id,
        ROW_NUMBER() OVER(PARTITION BY c.employee_id ORDER BY random()) as shuffle_rank
    FROM compliance_filter c
    JOIN dim_kpi_library d ON c.department = d.department
)
-- Only keep the top n random KPIs up to their target count
SELECT 
    employee_id,
    kpi_id,
    '2026-01-01'::DATE AS kpi_start_date,
    '2026-12-31'::DATE AS kpi_end_date
FROM shuffled_kpis
WHERE shuffle_rank <= target_kpi_count;
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
