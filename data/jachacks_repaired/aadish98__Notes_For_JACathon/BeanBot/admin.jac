# Manager admin walkers: snapshots, compliance run, agent fetch
include domain;

import from compliance {
    validate_complete,
    task_compliance_issue_flags
}
import from db {
    sync_overdue_status,
    list_tasks_for_assignees_map,
    list_active_employees,
    create_snapshot,
    get_latest_snapshot,
    get_summaries_for_snapshot,
    save_employee_summary,
    create_agent_fetch_request,
    list_pending_fetch_requests,
    acknowledge_fetch_request_as_employee,
    prune_old_snapshots,
    today_iso_date,
    get_user_by_username,
    enforce_body_username_matches_token,
    db_log_warning
}


"Turn a dry compliance summary into a short actionable paragraph."
def summarize_report(full_report: str) -> str
    by llm();


def _manager_gate(username: str) -> dict {
    u = get_user_by_username(username);
    if not u {
        return {"ok": False, "user": {}};
    }
    if str(u["role"]) != "manager" {
        return {"ok": False, "user": u};
    }
    return {"ok": True, "user": u};
}


def _rebuild_weekly_snapshot() -> dict {
    sync_overdue_status();
    week_start = today_iso_date();
    snap = create_snapshot(week_start);
    snapshot_id = snap["id"];
    employees = list_active_employees();
    eids: list = [];
    for emp in employees {
        eids.append(str(emp["id"]));
    }
    tasks_by_eid = list_tasks_for_assignees_map(eids, "all");
    summaries: list = [];
    for emp in employees {
        eid = str(emp["id"]);
        ename = str(emp["name"]) if "name" in emp else eid;
        etasks = tasks_by_eid[eid] if eid in tasks_by_eid else [];
        total = len(etasks);
        overdue_c: int = 0;
        miss_c: int = 0;
        compl_miss: int = 0;
        compliant_c: int = 0;
        detail_lines: list = [];
        for t in etasks {
            fl = task_compliance_issue_flags(t);
            if "overdue" in fl {
                overdue_c = overdue_c + 1;
            }
            if "missing_fields" in fl {
                miss_c = miss_c + 1;
            }
            if "incomplete_completion" in fl {
                compl_miss = compl_miss + 1;
            }
            if fl == "" {
                compliant_c = compliant_c + 1;
            }
            if fl != "" {
                ttl = str(t["title"]) if "title" in t else "";
                detail_lines.append(ttl + " [" + str(fl) + "]");
            }
        }
        raw = (
            str(ename) + ": " + str(total) + " tasks. "
            + "Overdue flags: " + str(overdue_c)
            + ". Missing fields: " + str(miss_c) + ". "
            + "Details: " + "; ".join(detail_lines)
        );
        narr = str(raw);
        try {
            narr = str(summarize_report(raw));
        } except Exception {
            db_log_warning("summarize_report LLM failed; using raw snapshot text");
            narr = str(raw);
        }
        save_employee_summary(
            str(snapshot_id),
            str(eid),
            total,
            compliant_c,
            overdue_c,
            miss_c,
            compl_miss,
            str(narr)
        );
        summaries.append({
            "employee_id": eid,
            "employee_name": ename,
            "total": total,
            "narrative": narr
        });
    }
    prune_old_snapshots(10);
    return {
        "snapshot": snap,
        "summaries": summaries
    };
}


walker:priv RefreshSummary {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        mg = _manager_gate(self.username);
        if not mg["ok"] {
            report {"type": "error", "text": "Managers only."};
            disengage;
        }
        result = _rebuild_weekly_snapshot();
        report {"type": "success", "data": result};
    }
}


walker:priv GetSnapshot {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        mg = _manager_gate(self.username);
        if not mg["ok"] {
            report {"type": "error", "text": "Managers only."};
            disengage;
        }
        snap = get_latest_snapshot();
        if not snap {
            report {"type": "reply", "snapshot": None, "summaries": []};
        } else {
            sums = get_summaries_for_snapshot(str(snap["id"]));
            report {
                "type": "reply",
                "snapshot": snap,
                "summaries": sums
            };
        }
    }
}


walker:priv GetFetchRequests {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        u = get_user_by_username(self.username);
        if not u {
            report {"type": "error", "text": "Unknown user."};
            disengage;
        }
        eid = str(u["id"]);
        reqs = list_pending_fetch_requests(eid);
        report {"type": "reply", "requests": reqs};
    }
}


walker:priv AckFetchRequest {
    has username: str;
    has request_id: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        u = get_user_by_username(self.username);
        if not u {
            report {"type": "error", "text": "Unknown user."};
            disengage;
        }
        ok = acknowledge_fetch_request_as_employee(
            self.request_id,
            str(u["id"])
        );
        if not ok {
            report {
                "type": "error",
                "text": "Request not found or already handled."
            };
            disengage;
        }
        report {"type": "success", "text": "Acknowledged."};
    }
}


"Write a short personalized nudge listing overdue work and blockers for one lab member."
def agent_fetch_draft(employee_name: str, bullet_issues: str) -> str
    by llm();


walker:priv AgentFetch {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        mg = _manager_gate(self.username);
        if not mg["ok"] {
            report {"type": "error", "text": "Managers only."};
            disengage;
        }
        m = mg["user"];
        manager_id = str(m["id"]);
        sync_overdue_status();
        employees = list_active_employees();
        eids2: list = [];
        for emp in employees {
            eids2.append(str(emp["id"]));
        }
        tasks_by_eid2 = list_tasks_for_assignees_map(eids2, "all");
        out: list = [];
        for emp in employees {
            eid = str(emp["id"]);
            ename = str(emp["name"]) if "name" in emp else eid;
            etasks = tasks_by_eid2[eid] if eid in tasks_by_eid2 else [];
            bullets: list = [];
            for t in etasks {
                st = str(t["status"]) if "status" in t else "";
                ttl = str(t["title"]) if "title" in t else "";
                due = str(t["expected_end_date"]) if "expected_end_date" in t else "";
                if st == "overdue" {
                    bullets.append(
                        "Overdue: " + ttl + " (was due " + due + ")"
                    );
                }
                fl = task_compliance_issue_flags(t);
                if "missing_fields" in fl {
                    bullets.append("Needs fields: " + ttl);
                }
                if "incomplete_completion" in fl {
                    bullets.append(
                        "Marked complete but missing result link/summary: " + ttl
                    );
                }
            }
            if len(bullets) > 0 {
                btext = "\n".join(bullets);
                prompt_text = "Hi " + ename + ", please update BeanBot on:\n" + btext;
                try {
                    prompt_text = str(agent_fetch_draft(ename, btext));
                } except Exception {
                    prompt_text = "Hi " + ename + ", please update BeanBot on:\n" + btext;
                }
                create_agent_fetch_request(
                    str(manager_id),
                    str(eid),
                    str(prompt_text)
                );
                out.append(
                    {"employee_id": eid, "prompt": prompt_text}
                );
            }
        }
        report {"type": "success", "fetches": out};
    }
}
