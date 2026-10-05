# Task list and user lookup walkers
include domain;

import from db {
    list_tasks,
    list_all_tasks_for_admin,
    list_mentionable_users,
    sync_overdue_status,
    get_user_by_username,
    ensure_user_account,
    enforce_body_username_matches_token
}


def normalized_user_role(u: dict) -> str {
    r = "employee";
    if "role" in u {
        r = str(u["role"]);
    }
    return r.strip().lower();
}


def normalize_task_filter(f: str) -> str {
    x = str(f).strip().lower();
    if x == "in-progress" {
        return "in_progress";
    }
    return x;
}


walker:priv ListTasks {
    has username: str;
    has filter_by: str = "all";

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        sync_overdue_status();
        u = get_user_by_username(self.username);
        if not u {
            report {"type": "error", "text": "Unknown user."};
            disengage;
        }
        uid = str(u["id"]);
        role_norm = normalized_user_role(u);
        fb = normalize_task_filter(self.filter_by);
        if role_norm == "manager" {
            if fb == "all" {
                report {
                    "type": "reply",
                    "tasks": list_all_tasks_for_admin(),
                    "filter": fb
                };
            } else {
                report {
                    "type": "reply",
                    "tasks": list_tasks(None, fb),
                    "filter": fb
                };
            }
        } else {
            report {
                "type": "reply",
                "tasks": list_tasks(uid, fb),
                "filter": fb
            };
        }
    }
}


walker:priv ListMentionableUsers {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        users = list_mentionable_users(self.username);
        report {"type": "reply", "users": users};
    }
}


walker:priv GetUser {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        u = get_user_by_username(self.username);
        if u {
            report {"type": "reply", "user": u};
        } else {
            report {"type": "reply", "user": None};
        }
    }
}


walker:priv GetUserByUsername {
    has username: str;

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        u = get_user_by_username(self.username);
        if u {
            report {"type": "reply", "user": u};
        } else {
            report {"type": "reply", "user": None};
        }
    }
}


walker:priv EnsureUserAccount {
    has username: str;
    has role: str;
    has display_name: str = "";

    can run with Root entry {
        auth_err = enforce_body_username_matches_token(self.username);
        if auth_err {
            report {"type": "error", "text": auth_err};
            disengage;
        }
        r = self.role.lower();
        if r != "manager" and r != "employee" {
            report {"type": "reply", "ok": False, "error": "Role must be manager or employee."};
            disengage;
        }
        try {
            u = ensure_user_account(self.username, r, self.display_name);
            report {"type": "reply", "ok": True, "user": u};
        } except Exception {
            report {"type": "reply", "ok": False, "error": "Could not create account."};
        }
    }
}
