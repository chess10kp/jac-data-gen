# Chat entry: intent, extraction, compliance, confirmation gate
include domain;
include compliance;

import from db {
    get_pending_action,
    save_pending_action,
    delete_pending_action,
    get_user_by_username,
    find_employee_by_name_substring,
    find_users_by_names_or_usernames,
    employee_activity_facts,
    list_active_employees,
    utc_range_for_past_days,
    create_task,
    update_task,
    get_task,
    add_comment,
    get_project_for_user,
    merge_task_row,
    ensure_chat_session,
    sync_pending_fetch_requests_into_chat,
    append_chat_message,
    list_chat_messages,
    format_chat_transcript,
    jac_assignee_check,
    jac_task_access_check,
    actor_may_access_task,
    enforce_body_username_matches_token,
    db_log_warning,
    db_log_exception,
    format_mentions_transcript_prefix,
    mention_context_json_from_message,
    coerce_dict,
    coerce_list,
    parse_manager_insight_spec,
    spec_get_str_list,
    spec_get_days
}


"Given RECENT_TRANSCRIPT (user/assistant turns) and the latest USER_MESSAGE, classify into Intent and extract TaskDraft fields. Respect transcript context for references like it, that task, the same due date. Leave unknown fields empty. Use '__clear__' to erase a field."
def parse_and_extract_llm(message: str, recent_transcript: str) -> ChatParse
    by llm();


"Ask briefly and naturally for missing_fields. Include policy_hints only if it clarifies why something is needed. Stay under 3 sentences."
def generate_followup(missing_fields: list, context: str, policy_hints: str) -> str
    by llm();


"Reply ONLY with a single JSON object, no markdown. Schema: {\"user_names\":[],\"usernames\":[],\"days\":7,\"question_type\":\"activity\"}. user_names are display name fragments; usernames are login names. Default days 7."
def extract_manager_insight_spec_llm(user_message: str) -> str
    by llm();


"FACTS_JSON is database JSON (tasks, comments, task_updates, users). DATE_RANGE is UTC. MANAGER_QUESTION is the original question. Answer in 2-6 sentences; state the date range first; if there is no activity, say so clearly; never invent tasks or people."
def synthesize_manager_insight_answer(manager_question: str, date_range: str, facts_json: str) -> str
    by llm();


def parse_intent_rule(message: str) -> Intent {
    m = message.lower();
    if "cancel" in m or "abort" in m {
        return Intent.CANCEL_PENDING;
    }
    if "comment" in m {
        return Intent.ADD_COMMENT;
    }
    if ("complete" in m or "done" in m) and ("task" in m or extract_task_id_heuristic(message) != "") {
        return Intent.MARK_COMPLETE;
    }
    if "update" in m or "change" in m or "edit" in m {
        return Intent.UPDATE_TASK;
    }
    if ("add" in m and "task" in m) or ("create" in m and "task" in m) or ("new task" in m) {
        return Intent.ADD_TASK;
    }
    if "list" in m or "show my" in m or "my tasks" in m {
        return Intent.VIEW_TASKS;
    }
    return Intent.UNKNOWN;
}


def parse_and_extract_safe(message: str, recent_transcript: str) -> ChatParse {
    rule_intent = parse_intent_rule(message);
    if rule_intent != Intent.UNKNOWN {
        try {
            parsed = parse_and_extract_llm(message, recent_transcript);
            return ChatParse(intent=rule_intent, fields=parsed.fields);
        } except Exception {
            db_log_warning("parse_and_extract_llm failed (rule intent path)");
            return ChatParse(intent=rule_intent, fields=TaskDraft());
        }
    }
    try {
        return parse_and_extract_llm(message, recent_transcript);
    } except Exception {
        db_log_warning("parse_and_extract_llm failed (unknown intent path)");
        return ChatParse(intent=Intent.UNKNOWN, fields=TaskDraft());
    }
}


def generate_followup_safe(missing_fields: list, context: str, policy_hints: str) -> str {
    hints = "";
    if policy_hints != None {
        hints = str(policy_hints);
    }
    try {
        return generate_followup(missing_fields, context, hints);
    } except Exception {
        db_log_warning("generate_followup LLM failed; using fallback");
        if hints != "" {
            parts: list = [];
            for x in missing_fields {
                parts.append(str(x));
            }
            return hints + " Please fill in: " + ", ".join(parts) + ".";
        }
        return "Please provide the missing fields (see list in this message).";
    }
}


def followup_for_validation(vc: dict, user_line: str) -> str {
    hints = compliance_hints_for_followup(vc);
    mf: list = [];
    if "missing_fields" in vc {
        mf = coerce_list(vc["missing_fields"]);
    }
    return generate_followup_safe(mf, user_line, hints);
}


def extract_task_id_heuristic(message: str) -> str {
    import re;
    m = re.search(
        "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
        message
    );
    if m {
        return m.group(0);
    }
    parts = message.split();
    for p in parts {
        if p.startswith("task-") {
            return p;
        }
    }
    return "";
}


def is_confirm_message(message: str) -> bool {
    ml = message.strip().lower();
    return ml == "confirm" or ml == "yes" or ml == "ok";
}


def resolve_project_default(draft: dict, user_id: str) -> None {
    if "project_id" in draft {
        pid = draft["project_id"];
        if pid != None and str(pid).strip() != "" {
            return;
        }
    }
    proj = get_project_for_user(user_id);
    if proj {
        draft["project_id"] = proj["id"];
    }
}


def resolve_assignee(draft: dict, actor_id: str, role: str) -> None {
    if "assignee_id" in draft {
        if draft["assignee_id"] != None and str(draft["assignee_id"]).strip() != "" {
            return;
        }
    }
    an = "";
    if "assignee_name" in draft {
        an = str(draft["assignee_name"]);
    }
    if an != "" and role == "manager" {
        u = find_employee_by_name_substring(an);
        if u {
            draft["assignee_id"] = u["id"];
        }
    }
    if (not "assignee_id" in draft) or str(draft["assignee_id"]).strip() == "" {
        if role == "employee" {
            draft["assignee_id"] = actor_id;
        }
    }
}


def commit_pending_action(pending: dict, actor_id: str, role: str) -> dict {
    intent = str(pending["intent"]);
    draft = coerce_dict(pending["draft"]);
    if intent == "ADD_TASK" {
        vc = validate_create_for_actor(draft, actor_id, role);
        draft["status"] = vc["suggested_status"];
        if not vc["is_complete"] {
            return {
                "ok": False,
                "error": "validation failed",
                "missing_fields": coerce_list(vc["missing_fields"]),
                "guidance": vc["guidance"]
            };
        }
        ac = jac_assignee_check(actor_id, role, str(draft["assignee_id"]));
        if not ac["ok"] {
            return {"ok": False, "error": str(ac["error"])};
        }
        t = create_task(
            str(draft["project_id"]),
            str(draft["title"]),
            str(draft["assignee_id"]),
            actor_id,
            str(draft["status"]),
            str(draft["description"]) if "description" in draft else "",
            str(draft["time_estimate"]) if "time_estimate" in draft else "",
            str(draft["start_date"]) if "start_date" in draft else "",
            str(draft["due_date"]) if "due_date" in draft else "",
            str(draft["expected_end_date"]) if "expected_end_date" in draft else "",
            str(draft["deliverable_spec"]) if "deliverable_spec" in draft else "",
            str(draft["notebook_location"]) if "notebook_location" in draft else "",
            str(draft["result_schema_json"]) if "result_schema_json" in draft else "",
            "",
            ""
        );
        return {"ok": True, "task": t};
    }
    if intent == "UPDATE_TASK" {
        tid = str(draft["task_id"]);
        cur = get_task(tid);
        if not cur {
            return {"ok": False, "error": "task not found"};
        }
        acc = jac_task_access_check(actor_id, role, cur);
        if not acc["ok"] {
            return {"ok": False, "error": str(acc["error"])};
        }
        vu = validate_update_for_actor(draft, cur, actor_id, role);
        if not vu["is_complete"] {
            return {
                "ok": False,
                "missing_fields": coerce_list(vu["missing_fields"]),
                "guidance": vu["guidance"]
            };
        }
        st_cur = str(cur["status"]) if "status" in cur else "";
        if st_cur == "overdue" {
            vo = validate_overdue_update(draft, cur);
            if not vo["is_complete"] {
                return {"ok": False, "missing_fields": vo["missing_fields"]};
            }
        }
        fields: dict = {};
        keys = [
            "title", "description", "assignee_id", "status", "time_estimate",
            "start_date", "due_date", "expected_end_date", "deliverable_spec",
            "notebook_location", "result_schema_json", "result_summary", "data_link",
            "blocked_reason"
        ];
        for k in keys {
            if k in draft {
                fields[k] = draft[k];
            }
        }
        t = update_task(tid, fields, actor_id);
        return {"ok": True, "task": t};
    }
    if intent == "MARK_COMPLETE" {
        tid = str(draft["task_id"]);
        cur = get_task(tid);
        if not cur {
            return {"ok": False, "error": "task not found"};
        }
        acc2 = jac_task_access_check(actor_id, role, cur);
        if not acc2["ok"] {
            return {"ok": False, "error": str(acc2["error"])};
        }
        merged = merge_task_row(cur, draft);
        merged["status"] = "completed";
        vc = validate_complete(merged);
        if not vc["is_complete"] {
            return {"ok": False, "missing_fields": vc["missing_fields"]};
        }
        fields = {
            "status": "completed",
            "result_summary": str(draft["result_summary"]) if "result_summary" in draft else str(merged["result_summary"]),
            "data_link": str(draft["data_link"]) if "data_link" in draft else str(merged["data_link"]),
            "result_schema_json": str(draft["result_schema_json"]) if "result_schema_json" in merged else ""
        };
        if "result_schema_json" in draft {
            fields["result_schema_json"] = str(draft["result_schema_json"]);
        }
        t = update_task(tid, fields, actor_id);
        return {"ok": True, "task": t};
    }
    if intent == "ADD_COMMENT" {
        tid = str(draft["task_id"]);
        cur3 = get_task(tid);
        if not cur3 {
            return {"ok": False, "error": "task not found"};
        }
        acc3 = jac_task_access_check(actor_id, role, cur3);
        if not acc3["ok"] {
            return {"ok": False, "error": str(acc3["error"])};
        }
        body = str(draft["body"]) if "body" in draft else "";
        c = add_comment(tid, actor_id, body);
        return {"ok": True, "comment": c};
    }
    return {"ok": False, "error": "unknown intent"};
}


def intent_to_str(i: Intent) -> str {
    if i == Intent.ADD_TASK {
        return "ADD_TASK";
    }
    if i == Intent.UPDATE_TASK {
        return "UPDATE_TASK";
    }
    if i == Intent.MARK_COMPLETE {
        return "MARK_COMPLETE";
    }
    if i == Intent.ADD_COMMENT {
        return "ADD_COMMENT";
    }
    if i == Intent.VIEW_TASKS {
        return "VIEW_TASKS";
    }
    if i == Intent.CANCEL_PENDING {
        return "CANCEL_PENDING";
    }
    return "UNKNOWN";
}


def transcript_for_session(session_id: str) -> str {
    recent = list_chat_messages(session_id, 30);
    return format_chat_transcript(recent);
}


def looks_like_task_operation_message(message: str) -> bool {
    m = message.lower();
    tid_h = extract_task_id_heuristic(message);
    if ("add" in m or "create" in m or "new task" in m) and "task" in m {
        return True;
    }
    if ("update" in m or "change" in m or "edit" in m) and ("task" in m or tid_h != "") {
        return True;
    }
    if "comment" in m {
        return True;
    }
    if ("complete" in m or "done" in m) and ("task" in m or tid_h != "") {
        return True;
    }
    if "cancel" in m or "abort" in m {
        return True;
    }
    return False;
}


def _insight_fact_count(facts: dict, key: str) -> int {
    if not facts or not (key in facts) {
        return 0;
    }
    v = facts[key];
    if v == None {
        return 0;
    }
    try {
        return len(v);
    } except Exception {
        return 0;
    }
}


def format_manager_insight_fallback(facts: dict, date_range: str) -> str {
    nu = _insight_fact_count(facts, "users");
    nt = _insight_fact_count(facts, "tasks");
    nc = _insight_fact_count(facts, "comments");
    nup = _insight_fact_count(facts, "updates");
    if nt == 0 and nc == 0 and nup == 0 {
        return (
            "For "
            + date_range
            + ", there is no recorded task activity in BeanBot for the selected people in that window."
        );
    }
    return (
        "For "
        + date_range
        + ", I could not summarize automatically. The data shows "
        + str(nt)
        + " related task(s), "
        + str(nc)
        + " comment(s), and "
        + str(nup)
        + " field update(s) across "
        + str(nu)
        + " profile(s). Try naming someone with @username or asking about a shorter time range."
    );
}


def looks_like_manager_insight_question(message: str, role: str) -> bool {
    if role != "manager" {
        return False;
    }
    if looks_like_task_operation_message(message) {
        return False;
    }
    m = message.lower();
    if "cancel" in m or "abort" in m {
        return False;
    }
    score: int = 0;
    if "?" in message {
        score = score + 1;
    }
    if "what " in m or "who " in m or "how many" in m or "show " in m or "list " in m {
        score = score + 1;
    }
    if "working" in m or "last " in m or "past " in m or "day" in m or "week" in m {
        score = score + 1;
    }
    if "overdue" in m or "blocked" in m or "progress" in m or "status" in m {
        score = score + 1;
    }
    if "activity" in m or "everyone" in m or "team" in m {
        score = score + 1;
    }
    return score >= 3;
}


def run_manager_insight_answer(message: str, session_id: str) -> None {
    import json;
    spec_raw = "{}";
    try {
        spec_raw = extract_manager_insight_spec_llm(message);
    } except Exception {
        db_log_warning("extract_manager_insight_spec_llm failed");
    }
    spec = parse_manager_insight_spec(spec_raw);
    days: int = spec_get_days(spec, 7);
    names = spec_get_str_list(spec, "user_names");
    uns = spec_get_str_list(spec, "usernames");
    targets = find_users_by_names_or_usernames(names, uns);
    if len(targets) == 0 {
        targets = list_active_employees();
    }
    user_ids = [str(t["id"]) for t in targets];
    pr = utc_range_for_past_days(days);
    start_r = pr[0];
    end_r = pr[1];
    facts = employee_activity_facts(user_ids, start_r, end_r);
    facts_json = json.dumps(facts);
    date_range = start_r + " – " + end_r;
    answer = format_manager_insight_fallback(facts, date_range);
    try {
        syn = synthesize_manager_insight_answer(message, date_range, facts_json);
        if syn != None {
            s2 = str(syn).strip();
            if s2 != "" {
                answer = s2;
            }
        }
    } except Exception {
        db_log_warning("synthesize_manager_insight_answer failed");
    }
    append_chat_message(session_id, "assistant", answer, "reply");
    report {"type": "reply", "text": answer, "session_id": session_id};
}


walker:priv EnsureChatSession {
    has username: str;
    has session_id: str = "";

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        actor = get_user_by_username(self.username);
        if not actor {
            report {"type": "error", "text": "Unknown user."};
            disengage;
        }
        sid_in = "";
        if self.session_id != None {
            sid_in = str(self.session_id);
        }
        sess = ensure_chat_session(str(actor["id"]), sid_in);
        sid = str(sess["id"]);
        role_a = "";
        if "role" in actor {
            role_a = str(actor["role"]);
        }
        role_lc = role_a.strip().lower();
        if role_lc == "employee" {
            sync_pending_fetch_requests_into_chat(sid, str(actor["id"]));
        }
        msgs = list_chat_messages(sid, 200);
        report {
            "type": "reply",
            "session_id": sid,
            "messages": msgs
        };
    }
}


walker:priv CreateEmployeeTask {
    has username: str;
    has title: str;
    has description: str;
    has start_date: str;
    has expected_end_date: str;
    has time_estimate: str;
    has deliverable_spec: str;
    has notebook_location: str;
    has session_id: str = "";

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        actor = get_user_by_username(self.username);
        if not actor {
            report {"type": "error", "text": "Unknown user."};
            disengage;
        }
        role_e = "";
        if "role" in actor {
            role_e = str(actor["role"]);
        }
        if role_e != "employee" {
            report {"type": "error", "text": "Only employees use this form."};
            disengage;
        }
        actor_id = str(actor["id"]);
        draft: dict = {};
        draft["title"] = str(self.title);
        draft["description"] = str(self.description);
        draft["start_date"] = str(self.start_date);
        draft["expected_end_date"] = str(self.expected_end_date);
        draft["time_estimate"] = str(self.time_estimate);
        draft["deliverable_spec"] = str(self.deliverable_spec);
        draft["notebook_location"] = str(self.notebook_location);
        resolve_project_default(draft, actor_id);
        resolve_assignee(draft, actor_id, role_e);
        vc = validate_create_for_actor(draft, actor_id, role_e);
        draft["status"] = vc["suggested_status"];
        if not vc["is_complete"] {
            report {
                "type": "error",
                "text": "Missing required fields.",
                "missing_fields": coerce_list(vc["missing_fields"])
            };
            disengage;
        }
        ac = jac_assignee_check(actor_id, role_e, str(draft["assignee_id"]));
        if not ac["ok"] {
            report {"type": "error", "text": str(ac["error"])};
            disengage;
        }
        t = create_task(
            str(draft["project_id"]),
            str(draft["title"]),
            str(draft["assignee_id"]),
            actor_id,
            str(draft["status"]),
            str(draft["description"]),
            str(draft["time_estimate"]),
            str(draft["start_date"]),
            "",
            str(draft["expected_end_date"]),
            str(draft["deliverable_spec"]),
            str(draft["notebook_location"]),
            "",
            "",
            ""
        );
        sid_n = str(self.session_id).strip();
        if sid_n != "" {
            tx_ok = "Saved new task: " + str(t["title"]) + ".";
            append_chat_message(sid_n, "assistant", tx_ok, "success");
        }
        report {"type": "success", "task": t};
    }
}


walker:priv ChatMessage {
    has message: str;
    has username: str;
    has session_id: str = "";
    can run with Root entry {
        auth_err2 = enforce_body_username_matches_token(self.username);
        if auth_err2 {
            report {"type": "error", "text": auth_err2};
            disengage;
        }
        actor = get_user_by_username(self.username);
        if not actor {
            report {"type": "reply", "text": "Unknown user."};
            disengage;
        }
        actor_id = str(actor["id"]);
        role = str(actor["role"]);
        sess_row = ensure_chat_session(actor_id, str(self.session_id));
        session_id = str(sess_row["id"]);
        role_lc_msg = str(role).strip().lower();
        if role_lc_msg == "employee" {
            sync_pending_fetch_requests_into_chat(session_id, actor_id);
        }
        append_chat_message(session_id, "user", self.message, "text");
        transcript = transcript_for_session(session_id);
        mj = mention_context_json_from_message(self.message, self.username);
        mention_prefix = format_mentions_transcript_prefix(mj);
        if mention_prefix != "" {
            transcript = str(mention_prefix) + str(transcript);
        }
        if str(role) == "manager"
            and looks_like_manager_insight_question(self.message, role)
            and not is_confirm_message(self.message) {
            run_manager_insight_answer(self.message, session_id);
            disengage;
        }
        pending = get_pending_action(actor_id, session_id);
        if pending and is_confirm_message(self.message) {
            if not pending["awaiting_confirm"] {
                tx0 = "Nothing to confirm.";
                append_chat_message(session_id, "assistant", tx0, "reply");
                report {"type": "reply", "text": tx0, "session_id": session_id};
                disengage;
            }
            result = commit_pending_action(pending, actor_id, role);
            if result["ok"] {
                delete_pending_action(actor_id, session_id);
                tx1 = "Done.";
                append_chat_message(session_id, "assistant", tx1, "success");
                report {
                    "type": "success",
                    "text": tx1,
                    "result": result,
                    "session_id": session_id
                };
            } else {
                miss_list = [];
                if "missing_fields" in result {
                    miss_list = coerce_list(result["missing_fields"]);
                }
                tid_cancel = None;
                if "target_task_id" in pending {
                    tid_cancel = pending["target_task_id"];
                }
                save_pending_action(
                    actor_id,
                    session_id,
                    str(pending["intent"]),
                    coerce_dict(pending["draft"]),
                    miss_list,
                    False,
                    tid_cancel,
                    ""
                );
                tx2 = "Could not complete. Please fix missing fields.";
                if "error" in result {
                    if str(result["error"]) != "" {
                        tx2 = str(result["error"]);
                    }
                }
                append_chat_message(session_id, "assistant", tx2, "followup");
                report {
                    "type": "followup",
                    "text": tx2,
                    "missing": miss_list,
                    "session_id": session_id
                };
            }
            disengage;
        }
        if pending and pending["awaiting_confirm"] and not is_confirm_message(self.message) {
            parsed_patch = parse_and_extract_safe(self.message, transcript);
            patch = parsed_patch.fields;
            draft = coerce_dict(pending["draft"]);
            draft = apply_draft_patch(draft, patch);
            intent_str = str(pending["intent"]);
            save_pending_action(
                actor_id,
                session_id,
                intent_str,
                draft,
                [],
                False,
                pending["target_task_id"] if "target_task_id" in pending else None,
                ""
            );
            if intent_str == "ADD_TASK" {
                resolve_project_default(draft, actor_id);
                resolve_assignee(draft, actor_id, role);
                vc = validate_create_for_actor(draft, actor_id, role);
                draft["status"] = vc["suggested_status"];
                if not vc["is_complete"] {
                    fo = followup_for_validation(vc, self.message);
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        coerce_list(vc["missing_fields"]),
                        False,
                        None,
                        fo
                    );
                    append_chat_message(session_id, "assistant", fo, "followup");
                    report {
                        "type": "followup",
                        "text": fo,
                        "missing": coerce_list(vc["missing_fields"]),
                        "session_id": session_id
                    };
                } else {
                    summ = draft_to_summary_lines(
                        draft,
                        "Confirm create task with:"
                    );
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        [],
                        True,
                        None,
                        summ
                    );
                    append_chat_message(session_id, "assistant", summ, "action_confirm");
                    report {
                        "type": "action_confirm",
                        "summary": summ,
                        "draft": draft,
                        "intent": intent_str,
                        "session_id": session_id
                    };
                }
            }
            if intent_str == "MARK_COMPLETE" {
                tid = "";
                if "task_id" in draft {
                    tid = str(draft["task_id"]);
                }
                cur = get_task(tid);
                base_m = {};
                if cur {
                    base_m = cur;
                }
                merged = merge_task_row(base_m, draft);
                merged["status"] = "completed";
                vc = validate_complete(merged);
                if not vc["is_complete"] {
                    fo = followup_for_validation(vc, self.message);
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        coerce_list(vc["missing_fields"]),
                        False,
                        tid,
                        fo
                    );
                    append_chat_message(session_id, "assistant", fo, "followup");
                    report {
                        "type": "followup",
                        "text": fo,
                        "missing": coerce_list(vc["missing_fields"]),
                        "session_id": session_id
                    };
                } else {
                    summ = draft_to_summary_lines(
                        draft,
                        "Confirm complete task:"
                    );
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        [],
                        True,
                        tid,
                        summ
                    );
                    append_chat_message(session_id, "assistant", summ, "action_confirm");
                    report {
                        "type": "action_confirm",
                        "summary": summ,
                        "draft": draft,
                        "intent": intent_str,
                        "session_id": session_id
                    };
                }
            }
            if intent_str == "ADD_COMMENT" {
                if (not "body" in draft) or str(draft["body"]).strip() == "" {
                    fo = generate_followup_safe(["body"], self.message, "");
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        ["body"],
                        False,
                        draft["task_id"] if "task_id" in draft else None,
                        fo
                    );
                    append_chat_message(session_id, "assistant", fo, "followup");
                    report {
                        "type": "followup",
                        "text": fo,
                        "missing": ["body"],
                        "session_id": session_id
                    };
                } else {
                    tid2 = str(draft["task_id"]);
                    curc = get_task(tid2);
                    if not curc or not actor_may_access_task(actor_id, role, curc) {
                        txb = "You can only comment on tasks assigned to you.";
                        save_pending_action(
                            actor_id,
                            session_id,
                            intent_str,
                            draft,
                            [],
                            False,
                            tid2,
                            ""
                        );
                        append_chat_message(session_id, "assistant", txb, "reply");
                        report {
                            "type": "reply",
                            "text": txb,
                            "session_id": session_id
                        };
                        disengage;
                    }
                    summ = "Confirm add comment on task " + tid2 + ": " + str(draft["body"]);
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        [],
                        True,
                        tid2,
                        summ
                    );
                    append_chat_message(session_id, "assistant", summ, "action_confirm");
                    report {
                        "type": "action_confirm",
                        "summary": summ,
                        "draft": draft,
                        "intent": intent_str,
                        "session_id": session_id
                    };
                }
            }
            if intent_str == "UPDATE_TASK" {
                tid3 = str(draft["task_id"]);
                cur2 = get_task(tid3);
                if not cur2 {
                    txnf = "Task not found.";
                    append_chat_message(session_id, "assistant", txnf, "reply");
                    report {"type": "reply", "text": txnf, "session_id": session_id};
                    disengage;
                }
                if not actor_may_access_task(actor_id, role, cur2) {
                    txd = "You can only update tasks assigned to you.";
                    append_chat_message(session_id, "assistant", txd, "reply");
                    report {"type": "reply", "text": txd, "session_id": session_id};
                    disengage;
                }
                vu = validate_update_for_actor(draft, cur2, actor_id, role);
                if not vu["is_complete"] {
                    fo = followup_for_validation(vu, self.message);
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        coerce_list(vu["missing_fields"]),
                        False,
                        tid3,
                        fo
                    );
                    append_chat_message(session_id, "assistant", fo, "followup");
                    report {
                        "type": "followup",
                        "text": fo,
                        "missing": coerce_list(vu["missing_fields"]),
                        "session_id": session_id
                    };
                } else {
                    st_cur = str(cur2["status"]) if "status" in cur2 else "";
                    if st_cur == "overdue" {
                        vo = validate_overdue_update(draft, cur2);
                        if not vo["is_complete"] {
                            fo = followup_for_validation(vo, self.message);
                            save_pending_action(
                                actor_id,
                                session_id,
                                intent_str,
                                draft,
                                coerce_list(vo["missing_fields"]),
                                False,
                                tid3,
                                fo
                            );
                            append_chat_message(session_id, "assistant", fo, "followup");
                            report {
                                "type": "followup",
                                "text": fo,
                                "missing": coerce_list(vo["missing_fields"]),
                                "session_id": session_id
                            };
                            disengage;
                        }
                    }
                    summ = draft_to_summary_lines(
                        draft,
                        "Confirm update task:"
                    );
                    save_pending_action(
                        actor_id,
                        session_id,
                        intent_str,
                        draft,
                        [],
                        True,
                        tid3,
                        summ
                    );
                    append_chat_message(session_id, "assistant", summ, "action_confirm");
                    report {
                        "type": "action_confirm",
                        "summary": summ,
                        "draft": draft,
                        "intent": intent_str,
                        "session_id": session_id
                    };
                }
            }
            disengage;
        }
        parsed = parse_and_extract_safe(self.message, transcript);
        intent = parsed.intent;
        it = intent_to_str(intent);
        if it == "CANCEL_PENDING" {
            delete_pending_action(actor_id, session_id);
            txc = "Cancelled pending action.";
            append_chat_message(session_id, "assistant", txc, "reply");
            report {"type": "reply", "text": txc, "session_id": session_id};
            disengage;
        }
        if it == "VIEW_TASKS" {
            txt = "Use the task tabs to filter by status.";
            append_chat_message(session_id, "assistant", txt, "reply");
            report {"type": "reply", "text": txt, "session_id": session_id};
            disengage;
        }
        if it == "UNKNOWN" {
            txu = "Try: add task ..., update task ..., comment ..., mark complete ...";
            append_chat_message(session_id, "assistant", txu, "reply");
            report {"type": "reply", "text": txu, "session_id": session_id};
            disengage;
        }
        tid_h = extract_task_id_heuristic(self.message);
        draft2: dict = {};
        draft2 = apply_draft_patch(draft2, parsed.fields);
        if tid_h != "" {
            draft2["task_id"] = tid_h;
        }
        if it == "ADD_TASK" {
            resolve_project_default(draft2, actor_id);
            resolve_assignee(draft2, actor_id, role);
            vc2 = validate_create_for_actor(draft2, actor_id, role);
            draft2["status"] = vc2["suggested_status"];
            if not vc2["is_complete"] {
                fo2 = followup_for_validation(vc2, self.message);
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    coerce_list(vc2["missing_fields"]),
                    False,
                    None,
                    fo2
                );
                append_chat_message(session_id, "assistant", fo2, "followup");
                report {
                    "type": "followup",
                    "text": fo2,
                    "missing": coerce_list(vc2["missing_fields"]),
                    "session_id": session_id
                };
                disengage;
            }
            summ2 = draft_to_summary_lines(draft2, "Confirm create task with:");
            save_pending_action(actor_id, session_id, it, draft2, [], True, None, summ2);
            append_chat_message(session_id, "assistant", summ2, "action_confirm");
            report {
                "type": "action_confirm",
                "summary": summ2,
                "draft": draft2,
                "intent": it,
                "session_id": session_id
            };
            disengage;
        }
        if it == "UPDATE_TASK" {
            if (not "task_id" in draft2) or str(draft2["task_id"]).strip() == "" {
                fo3 = generate_followup_safe(["task_id"], self.message, "");
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    ["task_id"],
                    False,
                    None,
                    fo3
                );
                append_chat_message(session_id, "assistant", fo3, "followup");
                report {
                    "type": "followup",
                    "text": fo3,
                    "missing": ["task_id"],
                    "session_id": session_id
                };
                disengage;
            }
            tcur = get_task(str(draft2["task_id"]));
            if not tcur {
                txn = "Task not found.";
                append_chat_message(session_id, "assistant", txn, "reply");
                report {"type": "reply", "text": txn, "session_id": session_id};
                disengage;
            }
            if not actor_may_access_task(actor_id, role, tcur) {
                txp = "You can only update tasks assigned to you.";
                append_chat_message(session_id, "assistant", txp, "reply");
                report {"type": "reply", "text": txp, "session_id": session_id};
                disengage;
            }
            vu2 = validate_update_for_actor(draft2, tcur, actor_id, role);
            if not vu2["is_complete"] {
                fo4 = followup_for_validation(vu2, self.message);
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    coerce_list(vu2["missing_fields"]),
                    False,
                    str(draft2["task_id"]),
                    fo4
                );
                append_chat_message(session_id, "assistant", fo4, "followup");
                report {
                    "type": "followup",
                    "text": fo4,
                    "missing": coerce_list(vu2["missing_fields"]),
                    "session_id": session_id
                };
                disengage;
            }
            if str(tcur["status"]) == "overdue" {
                vo2 = validate_overdue_update(draft2, tcur);
                if not vo2["is_complete"] {
                    fo5 = followup_for_validation(vo2, self.message);
                    save_pending_action(
                        actor_id,
                        session_id,
                        it,
                        draft2,
                        coerce_list(vo2["missing_fields"]),
                        False,
                        str(draft2["task_id"]),
                        fo5
                    );
                    append_chat_message(session_id, "assistant", fo5, "followup");
                    report {
                        "type": "followup",
                        "text": fo5,
                        "missing": coerce_list(vo2["missing_fields"]),
                        "session_id": session_id
                    };
                    disengage;
                }
            }
            summ3 = draft_to_summary_lines(draft2, "Confirm update task:");
            save_pending_action(
                actor_id,
                session_id,
                it,
                draft2,
                [],
                True,
                str(draft2["task_id"]),
                summ3
            );
            append_chat_message(session_id, "assistant", summ3, "action_confirm");
            report {
                "type": "action_confirm",
                "summary": summ3,
                "draft": draft2,
                "intent": it,
                "session_id": session_id
            };
            disengage;
        }
        if it == "ADD_COMMENT" {
            if (not "task_id" in draft2) or str(draft2["task_id"]).strip() == "" {
                fo6 = generate_followup_safe(["task_id"], self.message, "");
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    ["task_id"],
                    False,
                    None,
                    fo6
                );
                append_chat_message(session_id, "assistant", fo6, "followup");
                report {
                    "type": "followup",
                    "text": fo6,
                    "missing": ["task_id"],
                    "session_id": session_id
                };
                disengage;
            }
            tcomm = get_task(str(draft2["task_id"]));
            if not tcomm or not actor_may_access_task(actor_id, role, tcomm) {
                txq = "You can only comment on tasks assigned to you.";
                append_chat_message(session_id, "assistant", txq, "reply");
                report {"type": "reply", "text": txq, "session_id": session_id};
                disengage;
            }
            if (not "body" in draft2) or str(draft2["body"]).strip() == "" {
                fo7 = generate_followup_safe(["body"], self.message, "");
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    ["body"],
                    False,
                    str(draft2["task_id"]),
                    fo7
                );
                append_chat_message(session_id, "assistant", fo7, "followup");
                report {
                    "type": "followup",
                    "text": fo7,
                    "missing": ["body"],
                    "session_id": session_id
                };
                disengage;
            }
            summ4 = (
                "Confirm add comment on task " + str(draft2["task_id"]) + ": " + str(draft2["body"])
            );
            save_pending_action(
                actor_id,
                session_id,
                it,
                draft2,
                [],
                True,
                str(draft2["task_id"]),
                summ4
            );
            append_chat_message(session_id, "assistant", summ4, "action_confirm");
            report {
                "type": "action_confirm",
                "summary": summ4,
                "draft": draft2,
                "intent": it,
                "session_id": session_id
            };
            disengage;
        }
        if it == "MARK_COMPLETE" {
            if (not "task_id" in draft2) or str(draft2["task_id"]).strip() == "" {
                fo8 = generate_followup_safe(["task_id"], self.message, "");
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    ["task_id"],
                    False,
                    None,
                    fo8
                );
                append_chat_message(session_id, "assistant", fo8, "followup");
                report {
                    "type": "followup",
                    "text": fo8,
                    "missing": ["task_id"],
                    "session_id": session_id
                };
                disengage;
            }
            tcur3 = get_task(str(draft2["task_id"]));
            if not tcur3 {
                txnf2 = "Task not found.";
                append_chat_message(session_id, "assistant", txnf2, "reply");
                report {"type": "reply", "text": txnf2, "session_id": session_id};
                disengage;
            }
            if not actor_may_access_task(actor_id, role, tcur3) {
                txr = "You can only complete tasks assigned to you.";
                append_chat_message(session_id, "assistant", txr, "reply");
                report {"type": "reply", "text": txr, "session_id": session_id};
                disengage;
            }
            merged2 = merge_task_row(tcur3, draft2);
            merged2["status"] = "completed";
            vc3 = validate_complete(merged2);
            if not vc3["is_complete"] {
                fo9 = followup_for_validation(vc3, self.message);
                save_pending_action(
                    actor_id,
                    session_id,
                    it,
                    draft2,
                    coerce_list(vc3["missing_fields"]),
                    False,
                    str(draft2["task_id"]),
                    fo9
                );
                append_chat_message(session_id, "assistant", fo9, "followup");
                report {
                    "type": "followup",
                    "text": fo9,
                    "missing": coerce_list(vc3["missing_fields"]),
                    "session_id": session_id
                };
                disengage;
            }
            summ5 = draft_to_summary_lines(draft2, "Confirm complete task:");
            save_pending_action(
                actor_id,
                session_id,
                it,
                draft2,
                [],
                True,
                str(draft2["task_id"]),
                summ5
            );
            append_chat_message(session_id, "assistant", summ5, "action_confirm");
            report {
                "type": "action_confirm",
                "summary": summ5,
                "draft": draft2,
                "intent": it,
                "session_id": session_id
            };
            disengage;
        }
        txns = "Unsupported intent.";
        append_chat_message(session_id, "assistant", txns, "reply");
        report {"type": "reply", "text": txns, "session_id": session_id};
    }
}
