"""studio - OSP graph persistence for chats + messages (replaces SQLite).

`root --> Chat --> Msg`. Chats live on the shared root graph and survive restarts.
`jid(node)` is the stable cross-RPC id. Ported from server/db.py (chats/messages).
"""

import datetime;

def _now() -> str {
    return datetime.datetime.now(datetime.UTC).replace(tzinfo=None).isoformat() + "Z";
}

"""Current UTC date as YYYY-MM-DD — the sidebar groups chats by day and labels the
current day TODAY. Computed server-side so the client needs no Date object (both
this and chat timestamps are UTC, so the grouping lines up)."""
def:pub today_utc() -> str {
    return datetime.datetime.now(datetime.UTC).date().isoformat();
}

obj ChatView {
    has id: str = "",
        title: str = "",
        workspace: str = "01",
        created_at: str = "",
        updated_at: str = "";
}

obj MsgView {
    has id: str = "",
        role: str = "",
        content: str = "",
        model_id: str = "",
        stats_json: str = "",
        pair_group: str = "",
        created_at: str = "";
}

node Chat {
    has title: str = "",
        workspace: str = "01",
        created_at: str = "",
        updated_at: str = "";

    def to_view -> ChatView {
        return ChatView(
            id=jid(self), title=self.title, workspace=self.workspace,
            created_at=self.created_at, updated_at=self.updated_at
        );
    }
}

node Msg {
    has role: str = "",
        content: str = "",
        model_id: str = "",
        stats_json: str = "",
        pair_group: str = "",
        created_at: str = "";

    def to_view -> MsgView {
        return MsgView(
            id=jid(self), role=self.role, content=self.content,
            model_id=self.model_id, stats_json=self.stats_json,
            pair_group=self.pair_group, created_at=self.created_at
        );
    }
}

def _find_chat(chat_id: str) -> Chat | None {
    for c in [root -->][?:Chat] {
        if jid(c) == chat_id {
            return c;
        }
    }
    return None;
}

"""Workspace of a chat. Pre-workspace nodes lack the field on disk; the dataclass
default resolves them to "01" via class-attr lookup (verified in the jaclang 0.16.1
serializer). try/except is belt-and-braces against any future default_factory."""
def _ws_of(c: Chat) -> str {
    try {
        w = c.workspace;
        return w if w else "01";
    } except Exception {
        return "01";
    }
}

"""Chats in one workspace, most-recently-updated first (matches old
`ORDER BY updated_at DESC`). Old chats with no workspace field read as "01"."""
def:pub list_chats(workspace: str = "01") -> list[ChatView] {
    out: list[ChatView] = [];
    for c in [root -->][?:Chat] {
        if _ws_of(c) == workspace {
            out.append(c.to_view());
        }
    }
    out.sort(key=lambda v: ChatView -> str { return v.updated_at; }, reverse=True);
    return out;
}

def:pub create_chat(title: str, workspace: str = "01") -> ChatView {
    now = _now();
    c = (root ++> Chat(title=title, workspace=workspace, created_at=now, updated_at=now))[0];
    return c.to_view();
}

def:pub rename_chat(chat_id: str, title: str) -> bool {
    c = _find_chat(chat_id);
    if c {
        c.title = title;
        c.updated_at = _now();
        return True;
    }
    return False;
}

def:pub delete_chat(chat_id: str) -> bool {
    c = _find_chat(chat_id);
    if c {
        for m in [c -->][?:Msg] {
            del m;
        }
        del c;
        return True;
    }
    return False;
}

def:pub get_messages(chat_id: str) -> list[MsgView] {
    c = _find_chat(chat_id);
    out: list[MsgView] = [];
    if c {
        for m in [c -->][?:Msg] {
            out.append(m.to_view());
        }
    }
    return out;
}

def:pub add_message(
    chat_id: str, role: str, content: str, model_id: str, stats_json: str, pair_group: str
) -> MsgView {
    c = _find_chat(chat_id);
    if not c {
        return MsgView();
    }
    m = (c ++> Msg(
        role=role, content=content, model_id=model_id,
        stats_json=stats_json, pair_group=pair_group, created_at=_now()
    ))[0];
    c.updated_at = _now();
    return m.to_view();
}
