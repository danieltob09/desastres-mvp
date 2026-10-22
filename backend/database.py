import os

import psycopg
from dotenv import load_dotenv
from psycopg.rows import dict_row

load_dotenv()


def get_connection():
    return psycopg.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "desastres_db"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD"),
        row_factory=dict_row,
        connect_timeout=5,
    )
