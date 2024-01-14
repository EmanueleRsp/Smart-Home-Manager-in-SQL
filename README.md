# SmartHome Manager using SQL

The goal was to develop a **relational database** on **Oracle MySQL DBMS** to store data related to a system that manages a smart home, with some operations and **Data Analytics** functionalities.

The project was a team work, developed with [**@RacheleCiulli**]().

- [SmartHome Manager using SQL](#smarthome-manager-using-sql)
  - [Documentation](#documentation)
  - [Project structure](#project-structure)
  - [How to run scripts](#how-to-run-scripts)
  - [Final evaluation](#final-evaluation)


---

## Documentation

> _This project was developed during "Computer Networks" course for the Bachelor's degree in Computer Engineering at the University of Pisa, so inner workings and implementation details are described in **italian**._

The **main documentation** of the project is available [here](/docs/Documentazione.pdf): it contains a quite detailed description of each step of the project, from the analysis of the problem to the implementation of the solution, including descriptions and analysis of **ER diagram**, **SQL code** used to create the database and **queries** used to perform the required operations.

For a detailed visualization of the **ER diagram** of the database, you can check the pdf file [here](/docs/Modello_ER.pdf).

If you want to check the **tasks** required for the project, you can find them in the pdf file [here](/docs/Specifiche.pdf).

---

## Project structure

The project is structured in the following way:
- **`docs/`** folder contains all the documentation of the project, including the **ER diagram** of the database, the **main documentation** and the **tasks** required for the project.
- **`scripts/`** folder contains all the **SQL code** used to create the database and the **queries** used to perform the required operations. For a description of each script, check the last chapter of the main documentation ["Implementazione su DBMS"](/docs/Documentazione.pdf).
- **`README.md`** is the **file** you are reading right now :).

---

## How to run scripts

To run the scripts, you need to have **Oracle MySQL DBMS** installed on your machine. You can download it from [here](https://dev.mysql.com/downloads/mysql/).

Once you have installed the DBMS, you can **run the scripts in the following order**:
1. **`Smart_home.sql`** to create the tables of the database.
2. **`Operazioni.sql`** to create the operations of the database.
3. **`Popolamento.sql`** to populate the tables of the database.
   
After that, you can run the **queries** and the **Data Analytics** operations you want to perform, using the remaining scripts.

To compare the results of the queries with the expected ones, you can check the last chapter of the main documentation ["Implementazione su DBMS"](/docs/Documentazione.pdf).

---

## Final evaluation

The project was evaluated with a **score of 28/30**.
