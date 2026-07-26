
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
