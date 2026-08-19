"""Chat history sidebar — ports ui/components/sidebar.tsx.

Chats are grouped by day (most-recent first) under TODAY / ISO-date micro-labels;
each row reveals REN / DEL actions on hover. REN swaps the title for an inline
input (Enter/blur commits via onRename, Escape cancels). The footer MEM gauge
shows resident vs total RAM as `{used} / {ram} GB` plus an 8-cell ▮/░ bar."""

import from ..shared.Button { Button }

def _repeat(ch: str, n: int) -> str {
    s = "";
    i = 0;
    while i < n {
        s = s + ch;
        i = i + 1;
    }
    return s;
}

# Group consecutive chats (already sorted newest-first) by their updated_at day.
def _groups(chats: list) -> list[dict] {
    out: list[dict] = [];
    for c in chats {
        day = str(c.updated_at)[:10];
        if len(out) > 0 and out[len(out) - 1]["day"] == day {
            out[len(out) - 1]["chats"].append(c);
        } else {
            out.append({"day": day, "chats": [c]});
        }
    }
    return out;
}

# JsxElement defs compile to props-object components — params must be optional
# and call sites pass one dict (the _cell/_cmpRow idiom in Train/Evals).
def _mem_gauge(used: any = None, total: any = None) -> JsxElement {
    u = float(str(used or 0.0));
    t = float(str(total or 0.0));
    filled = 0;
    if t > 0.0 {
        filled = int(round(u / t * 8.0));
    }
    if filled > 8 { filled = 8; }
    if filled < 0 { filled = 0; }
    return <div className="dashed-rule pt-3 font-mono text-[10px] text-muted-foreground">
        MEM {f"{u:.1f}"} / {str(int(t))} GB{" "}
        <span className="text-foreground/80">{_repeat("▮", filled)}</span>{_repeat("░", 8 - filled)}
    </div>;
}

def:pub Sidebar(
    chats: list,
    activeId: str,
    ramGb: float,
    residentGb: float,
    todayIso: str,
    busy: bool,
    onNew: Callable[([], None)],
    onOpen: Callable[([str], None)],
    onDelete: Callable[([str], None)],
    onRename: Callable[([str, str], None)]
) -> JsxElement {
    has editingId: str = "",
        draft: str = "";

    def startEdit(id: str, title: str) -> None {
        editingId = id;
        draft = title;
    }

    def commitRename -> None {
        if editingId {
            t = draft.strip();
            if t {
                onRename(editingId, t);
            }
        }
        editingId = "";
        draft = "";
    }

    return <aside className="flex w-56 shrink-0 flex-col border-r border-border bg-card p-3">
        <div className="micro-label mb-3">CHATS</div>
        <Button
            variant="outline"
            onClick={lambda e: MouseEvent { if not busy { onNew(); } }}
            disabled={busy}
            className="mb-3"
        >
            + new chat
        </Button>
        <div className="flex-1 overflow-y-auto">
            {if len(chats) == 0 {
                <p key="empty" className="px-2 font-mono text-[10px] text-muted-foreground/70">no chats yet</p>
                skip;
            }}
            {for grp in _groups(chats) {
                <div key={str(grp["day"])}>
                    <div className="micro-label mb-1 mt-2">{"TODAY" if grp["day"] == todayIso else str(grp["day"])}</div>
                    <div className="space-y-0.5">
                        {for c in list(grp["chats"]) {
                            <div
                                key={str(c.id)}
                                onClick={lambda e: MouseEvent { if not busy { onOpen(str(c.id)); } }}
                                className={"group flex cursor-pointer items-center justify-between rounded-md px-2 py-1.5 text-xs " + (
                                    "bg-accent text-foreground" if str(c.id) == activeId
                                    else "text-muted-foreground hover:bg-muted"
                                ) + (" opacity-50" if busy else "")}
                            >
                                {if editingId == str(c.id) {
                                    <input
                                        key="edit"
                                        autoFocus={True}
                                        value={draft}
                                        onClick={lambda e: MouseEvent { e.stopPropagation(); }}
                                        onChange={lambda e: ChangeEvent { draft = str(e.target.value); }}
                                        onKeyDown={lambda e: KeyboardEvent {
                                            if e.key == "Enter" {
                                                commitRename();
                                            } elif e.key == "Escape" {
                                                editingId = "";
                                                draft = "";
                                            }
                                        }}
                                        onBlur={lambda e: FocusEvent { commitRename(); }}
                                        className="w-full rounded border border-input bg-popover px-1 py-0.5 text-xs text-foreground outline-none"
                                    />
                                    skip;
                                }}
                                {if editingId != str(c.id) {
                                    <span key="title" className="truncate" title={str(c.title)}>{c.title if c.title else "untitled"}</span>
                                    skip;
                                }}
                                {if editingId != str(c.id) {
                                    <div key="acts" className="hidden shrink-0 group-hover:flex">
                                        <Button
                                            variant="ghost"
                                            onClick={lambda e: MouseEvent { e.stopPropagation(); if not busy { startEdit(str(c.id), str(c.title) if c.title else ""); } }}
                                            className="px-1 py-0"
                                        >REN</Button>
                                        <Button
                                            variant="ghost"
                                            onClick={lambda e: MouseEvent { e.stopPropagation(); if not busy { onDelete(str(c.id)); } }}
                                            className="px-1 py-0"
                                        >DEL</Button>
                                    </div>
                                    skip;
                                }}
                            </div>
                        }}
                    </div>
                </div>
            }}
        </div>
        {_mem_gauge({"used": residentGb, "total": ramGb})}
    </aside>;
}
