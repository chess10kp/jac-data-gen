"""SQLite-backed persistence for analysis runs and events."""

import json;
import sqlite3;
import from pathlib { Path }

import from api.models { AnalysisEvent, PortfolioSummary, RunRecord }

class RunStorage {
    has db_path: Path;

    def __init__(self: RunStorage, db_path: str) {
        self.db_path = Path(db_path);
        self.db_path.parent.mkdir(parents=True, exist_ok=True);
        self._initialize();
    }

    def _connect(self: RunStorage) -> sqlite3.Connection {
        connection = sqlite3.connect(str(self.db_path));
        connection.row_factory = sqlite3.Row;
        return connection;
    }

    def _initialize(self: RunStorage) {
        with self._connect() as connection {
            connection.executescript(
                """
                CREATE TABLE IF NOT EXISTS analysis_runs (
                    run_id TEXT PRIMARY KEY,
                    status TEXT NOT NULL,
                    progress REAL NOT NULL,
                    portfolio_summary TEXT NOT NULL,
                    request_payload TEXT NOT NULL,
                    normalized_holdings TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    started_at TEXT,
                    finished_at TEXT,
                    result TEXT,
                    error TEXT
                );

                CREATE TABLE IF NOT EXISTS analysis_events (
                    run_id TEXT NOT NULL,
                    seq INTEGER NOT NULL,
                    timestamp TEXT NOT NULL,
                    agent TEXT NOT NULL,
                    stage TEXT NOT NULL,
                    message TEXT NOT NULL,
                    PRIMARY KEY (run_id, seq),
                    FOREIGN KEY (run_id) REFERENCES analysis_runs (run_id)
                );
                """
            );
        }
    }

    def create_run(self: RunStorage, run: RunRecord) {
        with self._connect() as connection {
            connection.execute(
                """
                INSERT INTO analysis_runs (
                    run_id, status, progress, portfolio_summary, request_payload,
                    normalized_holdings, created_at, started_at, finished_at, result, error
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    run.run_id,
                    run.status,
                    run.progress,
                    json.dumps(run.portfolio_summary.to_dict()),
                    json.dumps(run.request_payload),
                    json.dumps(run.normalized_holdings),
                    run.created_at,
                    run.started_at,
                    run.finished_at,
                    json.dumps(run.result) if run.result is not None else None,
                    json.dumps(run.error) if run.error is not None else None
                )
            );
        }
    }

    def get_run(self: RunStorage, run_id: str) -> RunRecord | None {
        with self._connect() as connection {
            row = connection.execute(
                "SELECT * FROM analysis_runs WHERE run_id = ?",
                (run_id,)
            ).fetchone();
        }
        if row is None {
            return None;
        }
        return self._row_to_run(row);
    }

    def update_run(
        self: RunStorage,
        run_id: str,
        status: str | None = None,
        progress: float | None = None,
        started_at: str | None = None,
        finished_at: str | None = None,
        result: dict | None = None,
        error: dict | None = None
    ) -> None {
        fields: list[str] = [];
        values: list[any] = [];
        if status is not None {
            fields.append("status = ?");
            values.append(status);
        }
        if progress is not None {
            fields.append("progress = ?");
            values.append(progress);
        }
        if started_at is not None {
            fields.append("started_at = ?");
            values.append(started_at);
        }
        if finished_at is not None {
            fields.append("finished_at = ?");
            values.append(finished_at);
        }
        if result is not None {
            fields.append("result = ?");
            values.append(json.dumps(result));
        }
        if error is not None {
            fields.append("error = ?");
            values.append(json.dumps(error));
        }
        if len(fields) == 0 {
            return;
        }
        values.append(run_id);
        with self._connect() as connection {
            connection.execute(
                "UPDATE analysis_runs SET " + ", ".join(fields) + " WHERE run_id = ?",
                tuple(values)
            );
        }
    }

    def list_events(self: RunStorage, run_id: str, after_seq: int = 0) -> list[AnalysisEvent] {
        with self._connect() as connection {
            rows = connection.execute(
                """
                SELECT seq, timestamp, agent, stage, message
                FROM analysis_events
                WHERE run_id = ? AND seq > ?
                ORDER BY seq ASC
                """,
                (run_id, after_seq)
            ).fetchall();
        }
        out: list[AnalysisEvent] = [];
        for row in rows {
            out.append(
                AnalysisEvent(
                    seq=row["seq"],
                    timestamp=row["timestamp"],
                    agent=row["agent"],
                    stage=row["stage"],
                    message=row["message"]
                )
            );
        }
        return out;
    }

    def append_event(self: RunStorage, run_id: str, event: AnalysisEvent) {
        with self._connect() as connection {
            connection.execute(
                """
                INSERT OR IGNORE INTO analysis_events (
                    run_id, seq, timestamp, agent, stage, message
                )
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    run_id,
                    event.seq,
                    event.timestamp,
                    event.agent,
                    event.stage,
                    event.message
                )
            );
        }
    }

    def next_seq(self: RunStorage, run_id: str) -> int {
        with self._connect() as connection {
            row = connection.execute(
                "SELECT COALESCE(MAX(seq), 0) AS last_seq FROM analysis_events WHERE run_id = ?",
                (run_id,)
            ).fetchone();
        }
        return int(row["last_seq"]) + 1;
    }

    def mark_incomplete_runs_failed(self: RunStorage, error_payload: dict[str, any]) -> int {
        with self._connect() as connection {
            cursor = connection.execute(
                """
                UPDATE analysis_runs
                SET status = 'failed',
                    progress = CASE WHEN progress > 0.99 THEN 0.99 ELSE progress END,
                    finished_at = COALESCE(finished_at, CURRENT_TIMESTAMP),
                    error = ?
                WHERE status IN ('queued', 'running')
                """,
                (json.dumps(error_payload),)
            );
            return cursor.rowcount;
        }
    }

    def _row_to_run(self: RunStorage, row: sqlite3.Row) -> RunRecord {
        ps_raw = json.loads(row["portfolio_summary"]);
        psummary = PortfolioSummary(
            holdings_count=ps_raw["holdings_count"],
            total_weight=ps_raw["total_weight"]
        );
        return RunRecord(
            run_id=row["run_id"],
            status=row["status"],
            progress=float(row["progress"]),
            portfolio_summary=psummary,
            request_payload=json.loads(row["request_payload"]),
            normalized_holdings=json.loads(row["normalized_holdings"]),
            created_at=row["created_at"],
            started_at=row["started_at"],
            finished_at=row["finished_at"],
            result=json.loads(row["result"]) if row["result"] else None,
            error=json.loads(row["error"]) if row["error"] else None
        );
    }
}
