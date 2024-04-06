# About
Il progetto propone un sistema di gestione per stazioni di rifornimento e aziende proprietarie. Ogni stazione è identificata da un codice e collegata a un'azienda con dettagli sulla posizione, tipi di carburante e pompe. Le aziende, con un codice univoco, hanno un responsabile regionale e un ufficio specifico. I dipendenti, identificati dal codice fiscale, lavorano presso le stazioni aziendali, con un monitoraggio del piano settimanale. L'obiettivo è semplificare la gestione delle operazioni e delle risorse umane, prestando attenzione alle possibili inconsistenze.


# Components
- [ER Diagram](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/ER-Schema.png)
- [SQL Schema](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/schema.sql) and [triggers](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/triggers.sql)
- [R for populating the tables](https://github.com/6eero/Gas-Station-Database-Management-System/blob/main/populate_tabs.R)
- [Sample Queries]

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
   Start the PostgreSQL shell by typing `psql -U postgres`.

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
