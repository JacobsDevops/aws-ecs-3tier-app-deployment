import os
import psycopg2

def handler(event, context):
    host = os.environ['DB_HOST']
    user = os.environ['DB_USER']
    password = os.environ['DB_PASSWORD']
    dbname = os.environ['DB_NAME']

    conn = psycopg2.connect(f"host={host} user={user} password={password} dbname={dbname}")
    cur = conn.cursor()

    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS todo (
                todo_id SERIAL PRIMARY KEY,
                description VARCHAR(255)
            )
        """)
        conn.commit()
        return {"statusCode": 200, "body": "Table created successfully"}
    except Exception as e:
        return {"statusCode": 500, "body": str(e)}
    finally:
        cur.close()
        conn.close()

