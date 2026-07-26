DROP TABLE IF EXISTS hris_flattened_hierarchy_report CASCADE;

CREATE TABLE hris_flattened_hierarchy_report AS

SELECT 
    -- 1. Base Employee Information
    allemp.employee_id,
    allemp.first_name,
    allemp.last_name,
    allemp.job_title,
    allemp.job_level,
    allemp.department,
    allemp.status,
    
    -- 2. Direct Manager (Level 1)
    allemp.manager_id,
    mgr1.first_name || ' ' || mgr1.last_name AS manager_name,
    mgr1.job_title AS manager_job_title,
    
    -- 3. Manager's Manager (Level 2)
    mgr1.manager_id AS manager_l2_id,
    mgr2.first_name || ' ' || mgr2.last_name AS manager_l2_name,
    mgr2.job_title AS manager_l2_job_title,
    
    -- 4. Manager + 3 (Level 3)
    mgr2.manager_id AS manager_l3_id,
    mgr3.first_name || ' ' || mgr3.last_name AS manager_l3_name,
    mgr3.job_title AS manager_l3_job_title,
    
    -- 5. Manager + 4 (Level 4)
    mgr3.manager_id AS manager_l4_id,
    mgr4.first_name || ' ' || mgr4.last_name AS manager_l4_name,
    mgr4.job_title AS manager_l4_job_title,
    
    -- 6. Manager + 5 (Level 5 / CEO for entry-level employees)
    mgr4.manager_id AS manager_l5_id,
    mgr5.first_name || ' ' || mgr5.last_name AS manager_l5_name,
    mgr5.job_title AS manager_l5_job_title

FROM 
    all_employees_in_hris5 AS allemp


LEFT JOIN 
    all_employees_in_hris5 AS mgr1 
    ON allemp.manager_id = mgr1.employee_id

LEFT JOIN 
    all_employees_in_hris5 AS mgr2 
    ON mgr1.manager_id = mgr2.employee_id

LEFT JOIN 
    all_employees_in_hris5 AS mgr3 
    ON mgr2.manager_id = mgr3.employee_id

LEFT JOIN 
    all_employees_in_hris5 AS mgr4 
    ON mgr3.manager_id = mgr4.employee_id

LEFT JOIN 
    all_employees_in_hris5 AS mgr5 
    ON mgr4.manager_id = mgr5.employee_id

ORDER BY 
    allemp.department, 
    allemp.job_level DESC, 
    allemp.last_name;

/* 
-----------------------------------------------------------------------------
Data governance 
*/
ALTER TABLE hris_flattened_hierarchy_report 
ADD PRIMARY KEY (employee_id);

Create INDEX idx_department ON hris_flattened_hierarchy_report(department);
Create INDEX idx_job_level ON hris_flattened_hierarchy_report(job_level);
create INDEX idx_status ON hris_flattened_hierarchy_report(status);
create INDEX idx_manager_id ON hris_flattened_hierarchy_report(manager_id);



--Create view to connect it with BI tool
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
