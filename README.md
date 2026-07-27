#  Artificial HRIS data generator and database in PostgreSQL


> Disclaimer: All data in this repository is 100% fictional and synthetically generated. Any domain-specific rules are built strictly on publicly available, generalised industry standards.


Hi, I'm Lili, a Data Analyst specialising in the HR domain. I recently started a project building resources I wish I had when I first started learning SQL (and actually Excel before that). This repository is the first part of hopefully many. :)

### Project Overview
This project is an end-to-end SQL data generation, transformation, and governance solution. It simulates a corporate HRIS environment, building a database with fictional employee data from scratch using realistic HR domain rules, creates views to enhance the connection stability of with BI tools such as PowerBI or Tableau (dashboard coming soon) and introduces row-level security for different access levels. The aim was to move away from the idealised or oversimplified practice bases, since (let's be honest) real-world business data is also not like the textbooks.

### Who is it for
* I believe this project has 2 main applications:
  * Feel free to use this if you want to deepdive into database generations, CTEs, window and similar functions and looking for a working model.
  * However, you are also very welcome if you are just searching for a more realistic database to practice your Excel (including Power Query) or Power BI skills.


### Domain-realism
* Simulates an international company with 13 in-scope countries with salaries adjusted to local cost-of-living.
* 6 layers seniority, from Associate till CEO, each with their own compansation level and pay range spread.
* Fully functional reporting lines with 6 departments, each layer reports to the layer above in the same department
* Terminated employees
* Not every employee has assigned key-performance indicators -> chance to do analysis


### Technical skills required to read the code:

#### Main topics
* **PostgreSQL**
* **Database Architecture:**
* **Data Engineering** 
* **Data Security & Governance:** 

#### More details
* Data generation via CTEs to simulate business rules accompanied by using randomized filters
* Sequential self-joins illustrate corporate hierarchy (from Associate to CEO)
* Differentiation between aiming for normalisation in data storage and BI-ready denormalised reports as they would be expected by non-tech colleagues
* Role-based access control and row-level security: Enforced the principle of least privilege by creating distinct database roles (hr_admin_role and department_leader_role) paired with dynamic security policies (leader_hierarchy_access) tied to runtime session variables.
* Power Query Integration:
  * Structured Excel and Power BI data connections to route securely through views rather than raw tables.
  * Automated and easily refreshable reports via Advanced editor

## Repository Structure

| File Name | Purpose |
| :--- | :--- |
| `01_schema_and_data_generation.sql` | Creates tables and algorithms to generate 3000 "employees" in accordance to "business rules". |
| `02_kpi_generation.sql` | Builds a Star Schema for the key performance metrics |
| `03_flattened_hierarchy.sql`| Creates a flat org tree for each employee using sequential joins. |
| `04_business_views.sql` | Creates views for differring access needs. |
| `05_data_governance_and_security.sql` | Establishes role-based access control and row level secutity. |
