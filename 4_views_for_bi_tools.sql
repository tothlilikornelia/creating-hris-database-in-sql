/*
---------------------------------------------------------------------
Script: 4_views_for_bi_tools
Description: Creates business views to optimalise connections with BI tools (e.g. PowerBI, Tableau)
---------------------------------------------------------------------
*/

--Main report
--View for main table
CREATE OR REPLACE VIEW hr_view_main_table AS
SELECT 
    employee_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,
    department,
    job_level,
    job_title,
    pay_grade,
    annual_salary_USD,
    country,
    region,
    hire_date,
    status,
    termination_date
FROM 
    all_employees_in_hris5;

--Main table with reporting hierarchy
CREATE OR REPLACE VIEW hr_view_main_table_with_reporting_hierarchy AS
SELECT 
    allemp.employee_id,
    allemp.first_name,
    allemp.last_name,
    allemp.first_name || ' ' || allemp.last_name AS full_name,
    allemp.department,
    allemp.job_level,
    allemp.job_title,
    allemp.pay_grade,
    allemp.annual_salary_USD,
    allemp.country,
    allemp.region,
    allemp.hire_date,
    allemp.status,
    allemp.termination_date,
    hier.manager_id,
    hier.manager_name,
    hier.manager_l2_name,
    hier.manager_l3_name,
    hier.manager_l4_name,
    hier.manager_l5_name

FROM 
    all_employees_in_hris5 AS allemp
LEFT JOIN 
    hris_flattened_hierarchy_report AS hier 
    ON allemp.employee_id = hier.employee_id;

--Flattened hierarchy

CREATE OR REPLACE VIEW hris_flattened_hierarchy_view AS
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    job_title,
    job_level,
    department,
    status,
    manager_id,
    manager_name,
    manager_job_title,
    manager_l2_id,
    manager_l2_name,
    manager_l2_job_title,
    manager_l3_id,
    manager_l3_name,
    manager_l3_job_title,
    manager_l4_id,
    manager_l4_name,
    manager_l4_job_title,
    manager_l5_id,
    manager_l5_name,
    manager_l5_job_title

    FROM hris_flattened_hierarchy_report;


-- KPIs
CREATE OR REPLACE VIEW kpi_excel_export_view AS
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

