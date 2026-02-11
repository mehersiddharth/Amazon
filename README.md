# Project Title

**Natural Language SQL Query Assistant**

---

# Project Overview

This project is an AI-driven data assistant designed to bridge the gap between natural language queries and structured database analysis.  
The system allows users to ask questions in plain English, automatically converts them into optimized SQL queries using a language model, executes them against a relational database, and presents the results in a structured tabular format.

The goal of the project was to simulate how modern analytics tools and AI-assisted BI systems enable non-technical users to explore data without writing SQL.

---

# Problem Statement

Business users often struggle with SQL despite needing frequent access to analytical insights. Traditional BI tools require manual query writing or predefined dashboards, which limits flexibility.

This project addresses that problem by:

- Enabling natural language interaction with a database  
- Automatically generating SQL queries  
- Safely executing queries  
- Presenting results like professional database tools (pgAdmin / SQL Server)

---

# Database Design

Relational e-commerce schema including:

- Customers  
- Orders  
- Order Items  
- Products  
- Category  
- Payments  
- Shipping  
- Inventory  
- Sellers  

---

# Core Features

## 1. Natural Language → SQL Conversion

Users can input questions like:

- “Top 5 products by revenue”  
- “Successful vs failed payments per customer”  
- “Orders returned last month”  

The LLM dynamically generates SQL queries based on schema context.

---

## 2. SQL Safety Guardrails

To prevent unsafe operations:

- Only SELECT queries allowed  
- SQL cleaned to remove trailing semicolons  
- Query validation before execution  

---

## 3. Pagination & Large Dataset Handling

Implemented server-side pagination using:

- LIMIT  
- OFFSET  

This prevents UI overload and ensures scalability.

---

## 4. Token-Safe LLM Integration

Avoided token overflow and rate limit errors by:

- Never sending full result sets to the LLM  
- Passing only summaries + sample rows  
- Using compact schema descriptions  

---

## 5. Tabular Result Rendering

Query outputs displayed in structured table format similar to:

- pgAdmin  
- SQL Server Management Studio  
