"""Local SQLite DB — persistent storage for SMS logs, walker runs, and notifications."""

import from os { getcwd }
import from os.path { join }
import from sqlite3 { connect }
import from json { dumps, loads }
import from datetime { datetime }

glob _db_path: str = join(getcwd(), ".jac", "data", "app.db");
glob _tables_ready: bool = False;

def _ensure_tables() -> None {
    if _tables_ready {
        return;
    }
    conn = connect(_db_path);
    conn.execute(
        "CREATE TABLE IF NOT EXISTS sms_messages ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "from_number TEXT, to_number TEXT, body TEXT, "
        "direction TEXT, sid TEXT, unit_id TEXT, "
        "tenant_name TEXT, timestamp TEXT)"
    );
    conn.execute(
        "CREATE TABLE IF NOT EXISTS walker_logs ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "walker TEXT, unit_id TEXT, input_data TEXT, "
        "output_data TEXT, duration_ms INTEGER, timestamp TEXT)"
    );
    conn.execute(
        "CREATE TABLE IF NOT EXISTS notifications ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "type TEXT, payload TEXT, ticket_id TEXT, "
        "read_flag INTEGER DEFAULT 0, timestamp TEXT)"
    );
    conn.commit();
    conn.close();
    _tables_ready = True;
}


def:pub log_sms(from_number: str, to_number: str, body: str, direction: str, sid: str = "", unit_id: str = "", tenant_name: str = "") -> dict {
    try {
        _ensure_tables();
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S");
        conn = connect(_db_path);
        conn.execute(
            "INSERT INTO sms_messages (from_number, to_number, body, direction, sid, unit_id, tenant_name, timestamp) VALUES (?,?,?,?,?,?,?,?)",
            (from_number, to_number, body, direction, sid, unit_id, tenant_name, ts)
        );
        conn.commit();
        row_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0];
        conn.close();
        return {"success": True, "id": row_id};
    } except Exception {
        return {"success": False};
    }
}

def:pub get_sms_history(phone: str = "", limit_count: int = 50) -> list {
    try {
        _ensure_tables();
        conn = connect(_db_path);
        if phone {
            rows = conn.execute(
                "SELECT * FROM sms_messages WHERE from_number=? OR to_number=? ORDER BY id DESC LIMIT ?",
                (phone, phone, limit_count)
            ).fetchall();
        } else {
            rows = conn.execute(
                "SELECT * FROM sms_messages ORDER BY id DESC LIMIT ?",
                (limit_count,)
            ).fetchall();
        }
        conn.close();
        results = [];
        for r in rows {
            results.append({
                "id": r[0], "from": r[1], "to": r[2], "body": r[3],
                "direction": r[4], "sid": r[5], "unit_id": r[6],
                "tenant_name": r[7], "timestamp": r[8]
            });
        }
        return results;
    } except Exception {
        return [];
    }
}


def:pub log_walker_run(walker_name: str, unit_id: str, input_data: dict, output_data: dict, duration_ms: int = 0) -> dict {
    try {
        _ensure_tables();
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S");
        conn = connect(_db_path);
        conn.execute(
            "INSERT INTO walker_logs (walker, unit_id, input_data, output_data, duration_ms, timestamp) VALUES (?,?,?,?,?,?)",
            (walker_name, unit_id, dumps(input_data), dumps(output_data), duration_ms, ts)
        );
        conn.commit();
        conn.close();
        return {"success": True};
    } except Exception {
        return {"success": False};
    }
}


def:pub create_notification(notification_type: str, payload: dict, ticket_id: str = "") -> dict {
    try {
        _ensure_tables();
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S");
        conn = connect(_db_path);
        conn.execute(
            "INSERT INTO notifications (type, payload, ticket_id, read_flag, timestamp) VALUES (?,?,?,0,?)",
            (notification_type, dumps(payload), ticket_id, ts)
        );
        conn.commit();
        conn.close();
        return {"success": True};
    } except Exception {
        return {"success": False};
    }
}

def:pub get_notifications(unread_only: bool = True, limit_count: int = 20) -> list {
    try {
        _ensure_tables();
        conn = connect(_db_path);
        if unread_only {
            rows = conn.execute(
                "SELECT * FROM notifications WHERE read_flag=0 ORDER BY id DESC LIMIT ?",
                (limit_count,)
            ).fetchall();
        } else {
            rows = conn.execute(
                "SELECT * FROM notifications ORDER BY id DESC LIMIT ?",
                (limit_count,)
            ).fetchall();
        }
        conn.close();
        results = [];
        for r in rows {
            payload = {};
            try { payload = loads(r[2]); } except Exception {}
            results.append({
                "id": r[0], "type": r[1], "payload": payload,
                "ticket_id": r[3], "read": bool(r[4]), "timestamp": r[5]
            });
        }
        return results;
    } except Exception {
        return [];
    }
}


def:pub db_insert(collection: str, doc: dict) -> dict {
    try {
        _ensure_tables();
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S");
        doc["created_at"] = ts;
        conn = connect(_db_path);
        conn.execute(
            "CREATE TABLE IF NOT EXISTS " + collection + " (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, created_at TEXT)"
        );
        conn.execute(
            "INSERT INTO " + collection + " (data, created_at) VALUES (?,?)",
            (dumps(doc), ts)
        );
        conn.commit();
        row_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0];
        conn.close();
        return {"success": True, "id": row_id};
    } except Exception {
        return {"success": False};
    }
}

def:pub db_find(collection: str, query: dict = {}, limit_count: int = 50) -> list {
    try {
        _ensure_tables();
        conn = connect(_db_path);
        conn.execute(
            "CREATE TABLE IF NOT EXISTS " + collection + " (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, created_at TEXT)"
        );
        rows = conn.execute(
            "SELECT data FROM " + collection + " ORDER BY id DESC LIMIT ?",
            (limit_count,)
        ).fetchall();
        conn.close();
        results = [];
        for r in rows {
            try { results.append(loads(r[0])); } except Exception {}
        }
        return results;
    } except Exception {
        return [];
    }
}


def:pub check_db_health() -> dict {
    try {
        _ensure_tables();
        conn = connect(_db_path);
        tables = [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()];
        conn.close();
        return {"ok": True, "backend": "sqlite", "path": _db_path, "tables": tables};
    } except Exception {
        return {"ok": False, "backend": "sqlite", "path": _db_path};
    }
}
