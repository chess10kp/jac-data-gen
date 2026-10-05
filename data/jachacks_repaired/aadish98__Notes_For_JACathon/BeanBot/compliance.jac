# Deterministic validation + policy hints for task workflows
include domain;

def _nonempty(s: str) -> bool {
    return s != None and str(s).strip() != "";
}


def validate_create(draft: dict) -> dict {
    missing: list = [];
    warnings: list = [];
    if not _nonempty(str(draft.get("title", ""))) {
        missing.append("title");
    }
    if not _nonempty(str(draft.get("project_id", ""))) {
        missing.append("project_id");
    }
    if not _nonempty(str(draft.get("assignee_id", ""))) {
        missing.append("assignee_id");
    }
    if not _nonempty(str(draft.get("start_date", ""))) {
        missing.append("start_date");
    }
    if not _nonempty(str(draft.get("expected_end_date", ""))) {
        missing.append("expected_end_date");
    }
    if not _nonempty(str(draft.get("time_estimate", ""))) {
        missing.append("time_estimate");
    }
    if not _nonempty(str(draft.get("deliverable_spec", ""))) {
        missing.append("deliverable_spec");
    }
    if not _nonempty(str(draft.get("notebook_location", ""))) {
        missing.append("notebook_location");
    }
    if not _nonempty(str(draft.get("description", ""))) {
        missing.append("description");
    }
    dsc = str(draft.get("description", "")).strip();
    if dsc != "" {
        warnings.append(
            "Add enough detail in the description that someone else could pick this up later."
        );
    }
    st = str(draft.get("status", "")).strip().lower();
    suggested_status = st;
    if st == "" or st not in ["planned", "in_progress", "completed", "overdue"] {
        suggested_status = "planned";
    }
    return {
        "is_complete": len(missing) == 0,
        "missing_fields": missing,
        "warnings": warnings,
        "policy_blocks": [],
        "guidance": [],
        "suggested_status": suggested_status
    };
}


# Employees: project/assignee filled by resolve_* in chat.jac before validation.
# Required user input matches task_core_fields_present (lab core) minus project_id/assignee_id.
def validate_create_employee(draft: dict) -> dict {
    missing: list = [];
    warnings: list = [];
    if not _nonempty(str(draft.get("title", ""))) {
        missing.append("title");
    }
    if not _nonempty(str(draft.get("description", ""))) {
        missing.append("description");
    }
    if not _nonempty(str(draft.get("start_date", ""))) {
        missing.append("start_date");
    }
    if not _nonempty(str(draft.get("expected_end_date", ""))) {
        missing.append("expected_end_date");
    }
    if not _nonempty(str(draft.get("time_estimate", ""))) {
        missing.append("time_estimate");
    }
    if not _nonempty(str(draft.get("deliverable_spec", ""))) {
        missing.append("deliverable_spec");
    }
    if not _nonempty(str(draft.get("notebook_location", ""))) {
        missing.append("notebook_location");
    }
    st = str(draft.get("status", "")).strip().lower();
    suggested_status = st;
    if st == "" or st not in ["planned", "in_progress", "completed", "overdue"] {
        suggested_status = "planned";
    }
    return {
        "is_complete": len(missing) == 0,
        "missing_fields": missing,
        "warnings": warnings,
        "policy_blocks": [],
        "guidance": [],
        "suggested_status": suggested_status
    };
}


def apply_assignment_policy(
    draft: dict,
    actor_id: str,
    role: str,
    base: dict
) -> dict {
    pol: list = [];
    guid: list = [];
    complete = base["is_complete"];
    if role == "employee" {
        aid = "";
        if "assignee_id" in draft {
            aid = str(draft["assignee_id"]).strip();
        }
        if aid != "" and aid != actor_id {
            pol.append("assignee_not_self");
            guid.append(
                "Only managers can assign work to someone else. New tasks you create stay assigned to you."
            );
            complete = False;
        }
    }
    base["policy_blocks"] = pol;
    base["guidance"] = guid;
    has_missing = False;
    if "missing_fields" in base and base["missing_fields"] != [] {
        has_missing = True;
    }
    base["is_complete"] = complete and not has_missing;
    return base;
}


def validate_create_for_actor(draft: dict, actor_id: str, role: str) -> dict {
    if role == "employee" {
        base = validate_create_employee(draft);
    } else {
        base = validate_create(draft);
    }
    return apply_assignment_policy(draft, actor_id, role, base);
}


def validate_update(draft: dict, current: dict) -> dict {
    missing: list = [];
    warnings: list = [];
    core_keys = [
        "title",
        "project_id",
        "assignee_id",
        "description",
        "start_date",
        "expected_end_date",
        "time_estimate",
        "deliverable_spec",
        "notebook_location"
    ];
    for k in core_keys {
        eff = "";
        if k in draft {
            eff = str(draft[k]);
        } else {
            if k in current {
                eff = str(current[k]);
            }
        }
        if not _nonempty(eff) {
            missing.append(k);
        }
    }
    exp = "";
    if "expected_end_date" in draft {
        exp = str(draft["expected_end_date"]).strip();
    } else {
        exp = str(current.get("expected_end_date", "")).strip();
    }
    if _nonempty(exp) {
        blk = "";
        if "blocked_reason" in draft {
            blk = str(draft["blocked_reason"]).strip();
        } else {
            blk = str(current.get("blocked_reason", "")).strip();
        }
        st = str(current.get("status", "")).strip();
        if st == "overdue" and not _nonempty(blk) {
            warnings.append(
                "This task is overdue — a short blocked_reason helps your manager help you."
            );
        }
    }
    return {
        "is_complete": len(missing) == 0,
        "missing_fields": missing,
        "warnings": warnings,
        "policy_blocks": [],
        "guidance": []
    };
}


def validate_update_for_actor(
    draft: dict,
    current: dict,
    actor_id: str,
    role: str
) -> dict {
    base = validate_update(draft, current);
    pol: list = [];
    guid: list = [];
    if role == "employee" {
        if "assignee_id" in draft {
            na = str(draft["assignee_id"]).strip();
            cur_a = str(current.get("assignee_id", "")).strip();
            if na != "" and na != cur_a {
                pol.append("assignee_change");
                guid.append("Reassigning tasks is limited to managers.");
                base["is_complete"] = False;
            }
            if na != "" and na != actor_id {
                pol.append("assignee_not_you");
                guid.append("You can only be the assignee on your own tasks.");
                base["is_complete"] = False;
            }
        }
    }
    base["policy_blocks"] = pol;
    base["guidance"] = guid;
    return base;
}


def validate_complete(task: dict) -> dict {
    missing: list = [];
    warnings: list = [];
    if not _nonempty(str(task.get("result_summary", ""))) {
        missing.append("result_summary");
    }
    if not _nonempty(str(task.get("data_link", ""))) {
        missing.append("data_link");
    }
    rs = task.get("result_schema_json", "");
    if _nonempty(str(task.get("deliverable_spec", ""))) {
        if not _nonempty(str(rs)) {
            missing.append("result_schema_json");
        }
    }
    rsum = str(task.get("result_summary", "")).strip();
    if rsum != "" {
        warnings.append(
            "Spell out key outcomes in result_summary so completion is audit-ready."
        );
    }
    return {
        "is_complete": len(missing) == 0,
        "missing_fields": missing,
        "warnings": warnings,
        "policy_blocks": [],
        "guidance": []
    };
}


def validate_overdue_update(draft: dict, current: dict) -> dict {
    missing: list = [];
    blk = "";
    if "blocked_reason" in draft {
        blk = str(draft["blocked_reason"]).strip();
    } else {
        blk = str(current.get("blocked_reason", "")).strip();
    }
    if not _nonempty(blk) {
        missing.append("blocked_reason");
    }
    exp = "";
    if "expected_end_date" in draft {
        exp = str(draft["expected_end_date"]).strip();
    } else {
        exp = str(current.get("expected_end_date", "")).strip();
    }
    if not _nonempty(exp) {
        missing.append("expected_end_date");
    }
    g: list = [];
    if len(missing) > 0 {
        g.append(
            "For overdue tasks we need a brief blocked_reason and a revised expected_end_date so the lab plan stays honest."
        );
    }
    return {
        "is_complete": len(missing) == 0,
        "missing_fields": missing,
        "warnings": [],
        "policy_blocks": [],
        "guidance": g
    };
}


def compliance_hints_for_followup(vc: dict) -> str {
    parts: list = [];
    if "guidance" in vc {
        for g in vc["guidance"] {
            if str(g).strip() != "" {
                parts.append(str(g));
            }
        }
    }
    if "warnings" in vc {
        for w in vc["warnings"] {
            if str(w).strip() != "" {
                parts.append(str(w));
            }
        }
    }
    return " ".join(parts);
}


def task_core_fields_present(task: dict) -> bool {
    required = [
        "title",
        "project_id",
        "assignee_id",
        "description",
        "start_date",
        "expected_end_date",
        "time_estimate",
        "deliverable_spec",
        "notebook_location"
    ];
    for k in required {
        v = task.get(k, "");
        if v == None or str(v).strip() == "" {
            return False;
        }
    }
    return True;
}


def task_compliance_issue_flags(task: dict) -> str {
    issues: list = [];
    st = str(task["status"]) if "status" in task else "";
    if st == "overdue" {
        issues.append("overdue");
    }
    if not task_core_fields_present(task) {
        issues.append("missing_fields");
    }
    if st == "completed" {
        vc = validate_complete(task);
        if not vc["is_complete"] {
            issues.append("incomplete_completion");
        }
    }
    return ",".join(issues);
}


glob CLEAR_SENTINEL = "__clear__";


def _apply_field(base: dict, key: str, val: str) -> None {
    if val == CLEAR_SENTINEL {
        base[key] = "";
    } elif val != "" {
        base[key] = val;
    }
}


def apply_draft_patch(base: dict, d: TaskDraft) -> dict {
    _apply_field(base, "title", d.title);
    _apply_field(base, "project_id", d.project_id);
    _apply_field(base, "assignee_id", d.assignee_id);
    _apply_field(base, "assignee_name", d.assignee_name);
    _apply_field(base, "start_date", d.start_date);
    _apply_field(base, "due_date", d.due_date);
    _apply_field(base, "expected_end_date", d.expected_end_date);
    _apply_field(base, "status", d.status);
    _apply_field(base, "description", d.description);
    _apply_field(base, "time_estimate", d.time_estimate);
    _apply_field(base, "deliverable_spec", d.deliverable_spec);
    _apply_field(base, "notebook_location", d.notebook_location);
    _apply_field(base, "result_schema_json", d.result_schema_json);
    _apply_field(base, "result_summary", d.result_summary);
    _apply_field(base, "data_link", d.data_link);
    _apply_field(base, "blocked_reason", d.blocked_reason);
    _apply_field(base, "task_id", d.task_id);
    _apply_field(base, "body", d.body);
    return base;
}


def draft_to_summary_lines(draft: dict, intent: str) -> str {
    keys = [
        "title", "project_id", "assignee_id", "start_date", "expected_end_date",
        "time_estimate", "deliverable_spec", "notebook_location", "status",
        "description", "task_id", "body", "result_summary", "data_link",
        "result_schema_json", "blocked_reason"
    ];
    lines: list = [intent];
    for k in keys {
        if k in draft {
            v = draft[k];
            if v != None and str(v).strip() != "" {
                lines.append("  " + k + ": " + str(v));
            }
        }
    }
    return "\n".join(lines);
}
