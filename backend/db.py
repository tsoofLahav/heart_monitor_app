"""Azure SQL connection helpers for experiment APIs."""

from __future__ import annotations

import logging
import os
from contextlib import contextmanager
from typing import Any, Iterator

logger = logging.getLogger(__name__)

_CONNECTION_STRING_ENV = "AZURE_SQL_CONNECTION_STRING"


def _build_connection_string() -> str | None:
    direct = os.environ.get(_CONNECTION_STRING_ENV, "").strip()
    if direct:
        return direct

    server = os.environ.get("SQL_SERVER", "").strip()
    database = os.environ.get("SQL_DATABASE", "").strip()
    user = os.environ.get("SQL_USER", "").strip()
    password = os.environ.get("SQL_PASSWORD", "").strip()
    if not (server and database and user and password):
        return None

    driver = os.environ.get("SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    return (
        f"Driver={{{driver}}};"
        f"Server=tcp:{server},1433;"
        f"Database={database};"
        f"Uid={user};"
        f"Pwd={password};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )


def is_db_configured() -> bool:
    return _build_connection_string() is not None


@contextmanager
def get_connection() -> Iterator[Any]:
    """Yield a pyodbc connection; raises RuntimeError if not configured."""
    conn_str = _build_connection_string()
    if not conn_str:
        raise RuntimeError(
            f"Database not configured. Set {_CONNECTION_STRING_ENV} "
            "or SQL_SERVER/SQL_DATABASE/SQL_USER/SQL_PASSWORD."
        )
    try:
        import pyodbc
    except ImportError as exc:
        raise RuntimeError("pyodbc is required for experiment DB access") from exc

    conn = pyodbc.connect(conn_str)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def row_to_dict(cursor, row) -> dict[str, Any]:
    if row is None:
        return {}
    columns = [col[0] for col in cursor.description]
    return {columns[i]: row[i] for i in range(len(columns))}
