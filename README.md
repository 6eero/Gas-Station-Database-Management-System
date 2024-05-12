# About
The project proposes a management system for gas stations and owning companies. Each station is identified by a code and linked to a company with details about its location, types of fuel, and pumps. The companies, with a unique code, have a regional manager and a specific office. Employees, identified by their fiscal code, work at company stations, with monitoring of the weekly plan. The goal is to simplify the management of operations and human resources, paying attention to possible inconsistencies.

![ER-Schema](https://github.com/6eero/Gas-Station-Database-Management-System/assets/114809573/f9ddb4f8-bb0c-44c7-b06d-1e32a3d18829)



# Components
- [ER Diagram](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/ER-Schema.png)
- [SQL Schema and triggers](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/fuelstationdatabase.sql)
- [R for populating the tables](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/populate_tables.R)
- [SQL Operations Script](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/operazioni.sql)

# Usage

1. **Clone the Repository from GitHub**:
   ```
   git clone https://github.com/6eero/Gas-Station-Database-Management-System
   ```

2. **Navigate to the Cloned Project Directory**:
   Use the `cd` command to navigate into the directory of the cloned project:
   ```
   cd Gas-Station-Database-Management-System
   ```

3. **Start PostgreSQL Shell (psql)**:
   Start the PostgreSQL shell by typing the command:
   ```
   psql -U postgres
   ```

5. **Create the Database**:
   Once inside the PostgreSQL shell, create a new database using the command:
   ```
   CREATE DATABASE fuelstationdatabase;
   ```

6. **Exit PostgreSQL Shell**:
   To exit the PostgreSQL shell, type `exit` and press Enter.

7. **Reopen PostgreSQL Shell with Specified Database**:
   Re-enter the PostgreSQL shell specifying the created database and the `postgres` user using the command:
   ```
   psql -d fuelstationdatabase -U postgres
   ```

8. **Run the SQL Script**:
   Inside the PostgreSQL shell, run the SQL script using the command:
   ```
   \i fuelstationdatabase.sql
   ```

9. **Run the R Script**:
   In another shell with PostgreSQL open, launch the R script using the command:
   ```
   Rscript populate_tables.R
   ```

These commands will allow you to set up your environment and run the necessary scripts for your project, including database setup and executing the R script. Now, to see contents from tables you can use:
```
SELECT * FROM table_name;
```
