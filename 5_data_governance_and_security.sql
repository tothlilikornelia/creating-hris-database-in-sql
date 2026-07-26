/*
---------------------------------------------------------------------
Script: 5_data_governance_and_security
Description: Defines levels of data access, giving HR full permission and leaders only access to their reporting line
---------------------------------------------------------------------
*/

DROP ROLE IF EXISTS hr_admin_role;
DROP ROLE IF EXISTS department_leader_role;

CREATE ROLE hr_admin_role;
CREATE ROLE department_leader_role;

--Adding permissions

-- HR will have full access in this case
GRANT SELECT ON all_employees_in_hris5 TO hr_admin_role;
GRANT SELECT ON hris_flattened_hierarchy_report TO hr_admin_role;
GRANT SELECT ON v_kpi_excel_export TO hr_admin_role;

-- Leaders will only receive the required access (assumption: they need to audit their own reporting line, and sometimes want to check key performance indicators)
GRANT SELECT ON hris_flattened_hierarchy_report TO department_leader_role;
GRANT SELECT ON v_kpi_excel_export TO department_leader_role;

-- Row level-security
ALTER TABLE hris_flattened_hierarchy_report ENABLE ROW LEVEL SECURITY;

--HR: full access
CREATE POLICY hr_hierarchy_access 
ON hris_flattened_hierarchy_report
FOR SELECT TO hr_admin_role
USING (true);

-- Leaders will only be able to see rows where their employee ID appears in the reporting chain
CREATE POLICY leader_hierarchy_access 
ON hris_flattened_hierarchy_report
FOR SELECT TO department_leader_role
USING (
    current_setting('hris.current_user_id')::INT IN ( manager_id, manager_l2_id, manager_l3_id, manager_l4_id, manager_l5_id )
);

ALTER TABLE fact_employee_kpi ENABLE ROW LEVEL SECURITY;

--HR: full access
CREATE POLICY hr_kpi_access 
ON fact_employee_kpi
FOR SELECT TO hr_admin_role
USING (true);

--Leader access: only their own deparments
CREATE POLICY leader_kpi_access 
ON fact_employee_kpi
FOR SELECT TO department_leader_role
USING (
    employee_id IN (
        SELECT employee_id 
        FROM hris_flattened_hierarchy_report 
        WHERE current_setting('hris.current_user_id')::INT IN (manager_id, manager_l2_id, manager_l3_id, manager_l4_id, manager_l5_id)
    )
);
--Applying row level security to the views as well
ALTER VIEW v_kpi_excel_export SET (security_invoker = true);
ALTER VIEW hris_flattened_hierarchy_view SET (security_invoker = true);
