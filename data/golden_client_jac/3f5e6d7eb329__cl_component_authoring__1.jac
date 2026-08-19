"""App navigation — the split layout: workspaces CENTERED in a slim top bar
(brand left), the active workspace's sections in a left rail. AppShell renders
NavRail twice: part="top" and part="side". Terminal theme only; workspace
accent = dot + active bar, interiors stay monochrome."""

glob WS_ORDER: list[str] = ["01", "02", "03"];
glob WS_NAME: dict = {"01": "SFT/DPO", "02": "RL/GRPO", "03": "CPT"};
glob WS_DOT: dict = {"01": "var(--ws01)", "02": "var(--ws02)", "03": "var(--ws03)"};
# Uniform: every workspace exposes the same five sections. What each page shows
# is workspace-specific (01 results = eval runs; 02 train = the deployed
# best-of-k generator, GRPO trained offline; 03 results = CPT run compare).
glob SECTIONS: dict = {
    "01": ["chat", "data", "train", "results", "plan"],
    "02": ["chat", "data", "train", "results", "plan"],
    "03": ["chat", "data", "train", "results", "plan"]
};
glob LABELS: dict = {
    "chat": "CHAT", "data": "DATA", "train": "TRAIN",
    "results": "RESULTS", "plan": "PLAN"
};

# props-component convention: called as {_glyph({"s": ...})} from JSX, so the
# param is optional any and arrives as the mapped prop value at runtime.
def _glyph(s: any = None) -> JsxElement {
    if s == "chat" {
        return <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.25">
            <path d="M2 3h12v8H6l-3 3v-3H2z" strokeLinejoin="miter" />
        </svg>;
    }
    if s == "train" {
        return <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.25">
            <path d="M2 13h12" stroke="var(--input)" />
            <path d="M2 3c3 0 3 7 6 7 2 0 3-2 6-2" />
        </svg>;
    }
    if s == "data" {
        return <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.25">
            <rect x="3" y="2" width="10" height="3.4" />
            <rect x="3" y="6.3" width="10" height="3.4" />
            <rect x="3" y="10.6" width="10" height="3.4" />
        </svg>;
    }
    if s == "plan" {
        return <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.25">
            <path d="M3 4h7M3 8h5M3 12h4" />
            <path d="M10.5 11.5l1.5 1.5L14.5 10" />
        </svg>;
    }
    # results: sparkline + point
    return <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.25">
        <path d="M2 13h12" stroke="var(--input)" />
        <path d="M2 11l3-3 3 2 5-6" strokeLinejoin="miter" />
        <circle cx="13" cy="4" r="1.2" fill="currentColor" stroke="none" />
    </svg>;
}

def WsBtn(w: any = None, workspace: any = None, onWorkspace: any = None) -> JsxElement {
    active = str(w) == str(workspace);
    tone = "bg-muted text-foreground" if active else "text-muted-foreground hover:bg-popover hover:text-foreground/80";
    return <button
        key={str(w)}
        title={str(w) + " " + str(WS_NAME[str(w)])}
        onClick={lambda e: MouseEvent { onWorkspace(str(w)); }}
        className={"relative flex h-8 items-center gap-2 rounded-md px-2.5 transition-colors " + tone}
    >
        <span className="h-2 w-2 shrink-0 rounded-full" style={{"background": str(WS_DOT[str(w)]), "opacity": (1.0 if active else 0.4)}} />
        <span className="font-mono text-[10px] tracking-[0.12em]">{str(w)} {str(WS_NAME[str(w)])}</span>
    </button>;
}

def SecBtn(s: any = None, section: any = None, onSection: any = None) -> JsxElement {
    active = str(s) == str(section);
    tone = "bg-muted text-foreground" if active else "text-muted-foreground/70 hover:bg-popover hover:text-foreground/80";
    return <button
        key={str(s)}
        title={str(LABELS[str(s)])}
        onClick={lambda e: MouseEvent { onSection(str(s)); }}
        className={"relative flex h-9 items-center gap-3 rounded-md px-3 transition-colors " + tone}
    >
        {active and <span className="absolute left-0 top-2 bottom-2 w-[2px]" style={{"background": "var(--ws-accent)"}} />}
        {_glyph({"s": str(s)})}
        <span className="font-mono text-[11px] tracking-[0.15em]">{LABELS[str(s)]}</span>
    </button>;
}

def:pub NavRail(
    workspace: str, section: str,
    onWorkspace: Callable[([str], None)], onSection: Callable[([str], None)],
    part: str = ""
) -> JsxElement {
    has mode: str = "dark";

    can with entry {
        win: any = window;
        try {
            saved: any = win.localStorage.getItem("jacml.mode");
            if saved == "light" or saved == "dark" { mode = str(saved); }
        } except Exception { }
    }

    def toggleMode() -> None {
        m = "light" if mode == "dark" else "dark";
        mode = m;
        doc: any = document;
        win: any = window;
        if m == "light" {
            doc.documentElement.setAttribute("data-theme", "light");
        } else {
            doc.documentElement.removeAttribute("data-theme");
        }
        try {
            win.localStorage.setItem("jacml.mode", m);
        } except Exception { }
    }

    if part == "top" {
        return <nav className="grid h-12 w-full shrink-0 grid-cols-[1fr_auto_1fr] items-center border-b border-border bg-card px-4">
            <span className="micro-label justify-self-start">JAC MODEL STUDIO</span>
            <div className="flex items-center gap-1 justify-self-center rounded-lg border border-border bg-background p-1">
                {for w in WS_ORDER {
                    <WsBtn key={w} w={w} workspace={workspace} onWorkspace={onWorkspace} />
                }}
            </div>
            <div className="flex items-center gap-3 justify-self-end">
                <button
                    onClick={lambda e: MouseEvent { toggleMode(); }}
                    title="toggle light/dark"
                    className="micro-label rounded-md border border-input px-2 py-1 transition-colors hover:border-ring hover:text-foreground/80"
                >
                    {"☀ LIGHT" if mode == "dark" else "☾ DARK"}
                </button>
                <span className="micro-label text-muted-foreground/70">v4</span>
            </div>
        </nav>;
    }
    return <nav className="flex w-44 shrink-0 flex-col gap-1 border-r border-border bg-card px-2 py-4">
        <span className="micro-label mb-2 px-2 text-muted-foreground/70">{str(WS_NAME[workspace])}</span>
        {for s in list(SECTIONS[workspace]) {
            <SecBtn key={s} s={s} section={section} onSection={onSection} />
        }}
        <div className="flex-1" />
    </nav>;
}
