from openai import OpenAI
import sqlite3
import json
import re
import threading
from flask import Flask, render_template, request

app = Flask(__name__)
client = OpenAI(api_key='')  # Uses OPENAI_API_KEY 

PAGE_SIZE = 25
db_lock = threading.Lock()  # SERIALIZES SQLITE ACCESS



# COMPACT SCHEMA (ONLY THIS GOES TO LLM)


SCHEMA_SUMMARY = """
category(category_id, category_name)
customers(customer_id, first_name, last_name, state)
sellers(seller_id, seller_name, origin)
products(product_id, product_name, price, cogs, category_id)
orders(order_id, order_date, customer_id, seller_id, order_status)
order_items(order_item_id, order_id, product_id, quantity, price_per_unit)
payments(payment_id, order_id, payment_date, payment_status)
shippings(shipping_id, order_id, shipping_date, return_date, delivery_status)
inventory(inventory_id, product_id, stock, warehouse_id, last_stock_date)
"""


# UTILITIES


def clean_sql(sql: str) -> str:
    """Remove trailing semicolons and whitespace (SQLite-safe)."""
    return sql.strip().rstrip(";")

def strip_limit_offset(query: str) -> str:
    """Remove LIMIT/OFFSET for COUNT queries."""
    return re.sub(
        r"\s+limit\s+\d+(\s+offset\s+\d+)?",
        "",
        query,
        flags=re.IGNORECASE
    )

def needs_llm_explanation(question: str) -> bool:
    keywords = [
        "total", "sum", "average", "avg",
        "top", "highest", "lowest",
        "trend", "revenue", "profit", "count"
    ]
    return any(k in question.lower() for k in keywords)


#  LLM → SQL


def create_query(question: str) -> str:
    prompt = f"""
You are a SQLite expert.

Return JSON exactly like:
{{ "sql": "<SQL QUERY>" }}

Rules:
- ONLY SELECT queries
- Use proper joins
- Revenue = quantity * price_per_unit
- Combine customer name using:
  customers.first_name || ' ' || customers.last_name AS customer_name

Schema:
{SCHEMA_SUMMARY}

User question:
{question}
"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"}
    )

    sql = json.loads(response.choices[0].message.content)["sql"]
    return clean_sql(sql)


# DATABASE ACCESS (SERIALIZED + SAFE)


def get_connection():
    return sqlite3.connect(
        "ecommerce.db",
        timeout=10,
        check_same_thread=False
    )

def run_query(query, limit, offset):
    query = clean_sql(query)

    if not query.lower().startswith("select"):
        raise ValueError("Only SELECT queries allowed")

    if "limit" not in query.lower():
        query += f" LIMIT {limit} OFFSET {offset}"

    with db_lock:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(query)

        rows = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]

        conn.close()

    return columns, rows

def get_total_rows(query):
    clean_query = strip_limit_offset(clean_sql(query))
    count_query = f"SELECT COUNT(*) FROM ({clean_query}) AS total"

    with db_lock:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute(count_query)
        total = cursor.fetchone()[0]
        conn.close()

    return total


# MAIN ORCHESTRATOR

def get_question_and_return_answer(question, page):
    offset = (page - 1) * PAGE_SIZE

    query = create_query(question)
    columns, rows = run_query(query, PAGE_SIZE, offset)
    total_rows = get_total_rows(query)
    total_pages = (total_rows + PAGE_SIZE - 1) // PAGE_SIZE

    if needs_llm_explanation(question):
        answer = interpret_results(question, columns, rows)
    else:
        answer = "Detailed results are shown in the table."

    return {
        "query": query,
        "columns": columns,
        "rows": rows,
        "answer": answer,
        "page": page,
        "total_pages": total_pages,
        "question": question
    }


# FLASK ROUTE


@app.route("/", methods=["GET", "POST"])
def index():
    result = None
    page = int(request.args.get("page", 1))

    if request.method == "POST":
        question = request.form["text"]
        result = get_question_and_return_answer(question, 1)

    elif request.method == "GET" and "question" in request.args:
        question = request.args.get("question")
        result = get_question_and_return_answer(question, page)

    return render_template("index.html", result=result)


# START SERVER (RELOADER OFF)


if __name__ == "__main__":
    app.run(debug=True, use_reloader=False)



