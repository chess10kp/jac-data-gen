
def mark_used(value: any) -> None {
    if value {
        return;
    }
}

def html_escape(text: str) -> str {
    t: str = text.replace("&", "&amp;");
    t = t.replace("<", "&lt;");
    t = t.replace(">", "&gt;");
    return t;
}

def apply_bold(text: str) -> str {
    parts: list[str] = text.split("**");
    result: str = "";
    i: int = 0;
    for part in parts {
        if i % 2 == 1 {
            result = result + "<strong>" + part + "</strong>";
        } else {
            result = result + part;
        }
        i = i + 1;
    }
    return result;
}

def is_digit_char(c: str) -> bool {
    return c >= "0" and c <= "9";
}

def is_ol_line(line: str) -> bool {
    if len(line) < 3 { return False; }
    if is_digit_char(line[0]) and line[1] == "." and line[2] == " " { return True; }
    if len(line) >= 4 and is_digit_char(line[0]) and is_digit_char(line[1]) and line[2] == "." and line[3] == " " { return True; }
    return False;
}

def ol_content(line: str) -> str {
    if len(line) >= 3 and is_digit_char(line[0]) and line[1] == "." and line[2] == " " { return line[3:]; }
    if len(line) >= 4 and is_digit_char(line[0]) and is_digit_char(line[1]) and line[2] == "." and line[3] == " " { return line[4:]; }
    return line;
}

def lines_to_html(lines: list[str]) -> str {
    result: str = "";
    in_ul: bool = False;
    in_ol: bool = False;
    for raw_line in lines {
        line: str = raw_line.strip();
        if line.startswith("## ") {
            if in_ul { result = result + "</ul>"; in_ul = False; }
            if in_ol { result = result + "</ol>"; in_ol = False; }
            result = result + "<h3>" + apply_bold(html_escape(line[3:])) + "</h3>";
        } elif line.startswith("### ") {
            if in_ul { result = result + "</ul>"; in_ul = False; }
            if in_ol { result = result + "</ol>"; in_ol = False; }
            result = result + "<h4>" + apply_bold(html_escape(line[4:])) + "</h4>";
        } elif line.startswith("- ") or line.startswith("* ") {
            if in_ol { result = result + "</ol>"; in_ol = False; }
            if not in_ul { result = result + "<ul>"; in_ul = True; }
            result = result + "<li>" + apply_bold(html_escape(line[2:])) + "</li>";
        } elif is_ol_line(line) {
            if in_ul { result = result + "</ul>"; in_ul = False; }
            if not in_ol { result = result + "<ol>"; in_ol = True; }
            result = result + "<li>" + apply_bold(html_escape(ol_content(line))) + "</li>";
        } elif not line {
            if in_ul { result = result + "</ul>"; in_ul = False; }
            if in_ol { result = result + "</ol>"; in_ol = False; }
        } else {
            if in_ul { result = result + "</ul>"; in_ul = False; }
            if in_ol { result = result + "</ol>"; in_ol = False; }
            result = result + "<p>" + apply_bold(html_escape(line)) + "</p>";
        }
    }
    if in_ul { result = result + "</ul>"; }
    if in_ol { result = result + "</ol>"; }
    return result;
}

def format_key_label(key: str) -> str {
    parts: list[str] = key.replace("_", " ").replace("-", " ").split(" ");
    result: str = "";
    for part in parts {
        if part {
            if result { result = result + " "; }
            result = result + part[0].upper() + part[1:];
        }
    }
    return result;
}

def json_is_array(val: any) -> bool {
    if val is None { return False; }
    try {
        return bool(Array.isArray(val));  # jac:ignore[W2001]
    } except Exception {
        return False;
    }
}

def json_is_object(val: any) -> bool {
    if val is None { return False; }
    if json_is_array(val) { return False; }
    try {
        ks: any = Object.keys(val);  # jac:ignore[W2001]
        return bool(ks.length >= 0);  # jac:ignore[W2001]
    } except Exception {
        return False;
    }
}

def render_json_val(val: any, depth: int) -> str {
    if val is None { return ""; }
    if json_is_array(val) {
        inner: str = "";
        for item in val {
            if item is None { continue; }
            if json_is_object(item) {
                item_html: str = render_json_obj(item, depth + 1);
                if item_html { inner = inner + "<li class=\"rg-json-item\">" + item_html + "</li>"; }
            } elif json_is_array(item) {
                nested: str = render_json_val(item, depth + 1);
                if nested { inner = inner + "<li>" + nested + "</li>"; }
            } else {
                s: str = str(item).strip();
                if s { inner = inner + "<li>" + apply_bold(html_escape(s)) + "</li>"; }
            }
        }
        if not inner { return ""; }
        return "<ul>" + inner + "</ul>";
    }
    if json_is_object(val) {
        return render_json_obj(val, depth + 1);
    }
    s_val: str = str(val).strip();
    if not s_val or s_val == "null" or s_val == "undefined" { return ""; }
    return "<p>" + apply_bold(html_escape(s_val)) + "</p>";
}

def json_val_is_empty(val: any) -> bool {
    if val is None { return True; }
    if json_is_array(val) {
        has_any: bool = False;
        for item in val {
            if item is not None and str(item) != "" {
                has_any = True;
                break;
            }
        }
        return not has_any;
    }
    s: str = str(val).strip();
    return s == "" or s == "null" or s == "None" or s == "undefined";
}

def render_json_obj(jobj: any, depth: int) -> str {
    result: str = "";
    try {
        keys: any = Object.keys(jobj);  # jac:ignore[W2001]
        for k in keys {
            raw_key: str = str(k);
            val: any = jobj[raw_key];  # jac:ignore[W2001]
            if json_val_is_empty(val) { continue; }
            label: str = format_key_label(raw_key);
            val_html: str = render_json_val(val, depth);
            if not val_html { continue; }
            result = result + "<div class=\"rg-json-section\"><div class=\"rg-json-key\">" + html_escape(label) + "</div><div class=\"rg-json-body\">" + val_html + "</div></div>";
        }
    } except Exception {
        result = "";
    }
    return result;
}

def try_json_html(text: str) -> str {
    t: str = text.strip();
    if not t { return ""; }
    if t[0] != "{" and t[0] != "[" { return ""; }
    try {
        parsed: any = JSON.parse(t);  # jac:ignore[W2001]
        if parsed is None { return ""; }
        if json_is_object(parsed) {
            rendered: str = render_json_obj(parsed, 0);
            if rendered { return rendered; }
            return "";
        }
        if json_is_array(parsed) {
            return render_json_val(parsed, 0);
        }
        return "";
    } except Exception {
        return "";
    }
}

def md_to_html(text: str) -> str {
    code_segments: list[str] = text.split("```");
    result: str = "";
    seg_i: int = 0;
    for segment in code_segments {
        if seg_i % 2 == 1 {
            code_lines: list[str] = segment.split("\n");
            content: str = segment;
            if len(code_lines) > 0 {
                first_line: str = code_lines[0].strip();
                has_lang: bool = len(first_line) > 0 and len(first_line.split(" ")) == 1;
                if has_lang and len(code_lines) > 1 {
                    body: str = "";
                    j: int = 0;
                    for cl in code_lines {
                        if j > 0 {
                            if j > 1 { body = body + "\n"; }
                            body = body + cl;
                        }
                        j = j + 1;
                    }
                    content = body.strip();
                } else {
                    content = segment.strip();
                }
            }
            result = result + "<pre><code>" + html_escape(content) + "</code></pre>";
        } else {
            inline_parts: list[str] = segment.split("`");
            inl_i: int = 0;
            for ipart in inline_parts {
                if inl_i % 2 == 1 {
                    result = result + "<code>" + html_escape(ipart) + "</code>";
                } else {
                    lines: list[str] = ipart.split("\n");
                    result = result + lines_to_html(lines);
                }
                inl_i = inl_i + 1;
            }
        }
        seg_i = seg_i + 1;
    }
    return result;
}

def tab_class(tab: str, current: str) -> str {
    if tab == current {
        return "flex-1 border-b-2 border-accent px-2.5 py-2.5 text-[14px] font-semibold text-foreground transition-colors";
    }
    return "flex-1 border-b-2 border-transparent px-2.5 py-2.5 text-[14px] text-muted transition-colors hover:text-foreground";
}

def ends_with(text: str, suffix: str) -> bool {
    if not text or not suffix {
        return False;
    }
    segments: list[str] = text.split(suffix);
    return len(segments) > 1 and segments[len(segments) - 1] == "";
}

def safe_text(value: any) -> str {
    if value is None {
        return "";
    }
    return str(value);
}

def file_ext_label(path: str) -> str {
    if not path {
        return "file";
    }
    lower: str = path.lower();
    if ends_with(lower, ".py") or ends_with(lower, ".pyi") { return "py"; }
    if ends_with(lower, ".tsx") { return "tsx"; }
    if ends_with(lower, ".jsx") { return "jsx"; }
    if ends_with(lower, ".ts") { return "ts"; }
    if ends_with(lower, ".js") or ends_with(lower, ".mjs") or ends_with(lower, ".cjs") { return "js"; }
    if ends_with(lower, ".sv.jac") { return "sv.jac"; }
    if ends_with(lower, ".cl.jac") { return "cl.jac"; }
    if ends_with(lower, ".jac") { return "jac"; }
    if ends_with(lower, ".go") { return "go"; }
    if ends_with(lower, ".rs") { return "rs"; }
    if ends_with(lower, ".java") { return "java"; }
    if ends_with(lower, ".kt") or ends_with(lower, ".kts") { return "kt"; }
    if ends_with(lower, ".cs") { return "cs"; }
    if ends_with(lower, ".cpp") or ends_with(lower, ".cc") or ends_with(lower, ".cxx") { return "cpp"; }
    if ends_with(lower, ".c") { return "c"; }
    if ends_with(lower, ".rb") { return "rb"; }
    if ends_with(lower, ".php") { return "php"; }
    if ends_with(lower, ".swift") { return "swift"; }
    if ends_with(lower, ".dart") { return "dart"; }
    if ends_with(lower, ".vue") { return "vue"; }
    if ends_with(lower, ".svelte") { return "svelte"; }
    if ends_with(lower, ".html") or ends_with(lower, ".htm") { return "html"; }
    if ends_with(lower, ".css") or ends_with(lower, ".scss") or ends_with(lower, ".sass") { return "css"; }
    if ends_with(lower, ".json") { return "json"; }
    if ends_with(lower, ".toml") { return "toml"; }
    if ends_with(lower, ".yaml") or ends_with(lower, ".yml") { return "yaml"; }
    if ends_with(lower, ".md") or ends_with(lower, ".mdx") { return "md"; }
    return "file";
}

def file_ext_badge_class(path: str) -> str {
    lower: str = path.lower();
    base: str = "inline-flex shrink-0 items-center rounded-md px-2 py-1 text-[11px] font-semibold ";
    if ends_with(lower, ".py") or ends_with(lower, ".pyi") { return base + "bg-blue-500/20 text-blue-300"; }
    if ends_with(lower, ".tsx") or ends_with(lower, ".jsx") { return base + "bg-cyan-500/20 text-cyan-300"; }
    if ends_with(lower, ".ts") or ends_with(lower, ".js") or ends_with(lower, ".mjs") or ends_with(lower, ".cjs") { return base + "bg-yellow-500/20 text-yellow-300"; }
    if ends_with(lower, ".jac") { return base + "bg-accent/20 text-accent"; }
    if ends_with(lower, ".go") { return base + "bg-teal-500/20 text-teal-300"; }
    if ends_with(lower, ".rs") { return base + "bg-orange-500/20 text-orange-300"; }
    if ends_with(lower, ".java") or ends_with(lower, ".kt") or ends_with(lower, ".kts") { return base + "bg-red-500/20 text-red-300"; }
    if ends_with(lower, ".md") or ends_with(lower, ".mdx") { return base + "bg-slate-500/20 text-slate-300"; }
    return base + "bg-border text-muted";
}

def section_label(text: str) -> JsxElement {
    return <div className="text-[12px] font-semibold uppercase tracking-[0.14em] text-muted">{text}</div>;
}

def card_class() -> str {
    return "min-w-0 overflow-hidden rounded-[1.2rem] border border-border bg-panel-soft/90 p-4";
}

def invoke_callback(fn: any, value: any) -> None {
    fn.call(None, value);
}

def invoke_noarg_callback(fn: any) -> None {
    fn.call(None);
}

async def invoke_async_callback(fn: any) -> None {
    await fn.call(None);
}

def status_badge_label(run_state: any, loading: bool) -> str {
    if loading {
        return "Running";
    }
    if not run_state or not run_state.execution_mode {
        return "Idle";
    }
    if run_state.execution_mode == "llm" {
        return "LLM";
    }
    if run_state.execution_mode == "hybrid" {
        return "Hybrid";
    }
    return "Fallback";
}

def status_badge_class(run_state: any, loading: bool) -> str {
    base: str = "inline-flex items-center rounded-full border px-2.5 py-1 text-[11px] font-semibold uppercase tracking-[0.08em] ";
    if loading {
        return base + "border-accent/40 bg-accent/10 text-accent";
    }
    if not run_state or not run_state.execution_mode {
        return base + "border-border bg-panel-soft text-muted";
    }
    if run_state.execution_mode == "llm" {
        return base + "border-emerald-500/40 bg-emerald-500/10 text-emerald-300";
    }
    if run_state.execution_mode == "hybrid" {
        return base + "border-sky-500/40 bg-sky-500/10 text-sky-300";
    }
    return base + "border-amber-500/40 bg-amber-500/10 text-amber-300";
}

def history_bubble_class(role: str) -> str {
    if role == "user" {
        return "ml-auto max-w-[92%] break-words rounded-[1.2rem] border border-accent/30 bg-accent/10 px-4 py-3 text-[14px] text-foreground";
    }
    return "max-w-[92%] break-words rounded-[1.2rem] border border-border bg-panel-soft px-4 py-3 text-[14px] text-foreground";
}

def widget_model_options(model_opts: list[str]) -> list[JsxElement] {
    rows: list[JsxElement] = [];
    for item in model_opts {
        rows.append(<option key={item} value={item}>{item}</option>);
    }
    if len(rows) == 0 {
        rows.append(<option key="gpt-4o-mini" value="gpt-4o-mini">gpt-4o-mini</option>);
    }
    return rows;
}

def:pub WidgetShell(
    bundle: any = None,
    runState: any = None,
    meetingText: str = "",
    contextFileName: str = "",
    contextLoading: bool = False,
    queryLoading: bool = False,
    loading: bool = False,
    error: str = "",
    activeWidgetTab: str = "context",
    repoPath: str = "",
    ownership: list[any] = [],
    decisions: list[any] = [],
    statusMessage: str = "",
    hasProcessedContext: bool = False,
    followUpPrompt: str = "",
    followUpHistory: list[dict[str, str]] = [],
    setRepoPath: any = None,
    setMeetingText: any = None,
    setContextFileName: any = None,
    setActiveWidgetTab: any = None,
    setFollowUpPrompt: any = None,
    processContext: any = None,
    askAboutRun: any = None,
    processLabel: str = "Process Context",
    promptNewGhost: any = None,
    confirmingNewGhost: bool = False,
    cancelNewGhost: any = None,
    confirmNewGhost: any = None,
    themeMode: str = "dark",
    contrastMode: str = "standard",
    settingsEditorOpen: bool = False,
    selectedModel: str = "gpt-4o-mini",
    modelOptions: list[str] = ["gpt-4o-mini"],
    userApiKey: str = "",
    rememberSettings: bool = True,
    toggleTheme: any = None,
    toggleContrast: any = None,
    toggleSettingsEditor: any = None,
    saveApiSettings: any = None,
    clearApiSettings: any = None,
    updateSelectedModel: any = None,
    updateUserApiKey: any = None,
    updateRememberSettings: any = None
) -> JsxElement {
    files: list[any] = [];
    blockers: list[any] = [];
    tasks: list[any] = [];
    tickets: list[any] = [];
    transcriptSummary: str = "";
    runSummary: str = statusMessage;
    projectName: str = "repoGhost";
    projectType: str = "";
    nextSteps: list[str] = [];

    if bundle {
        files = bundle.relevant_files or [];
        blockers = bundle.blockers or [];
        tasks = bundle.tasks or [];
        tickets = bundle.tickets or [];
        if bundle.meeting_summary and bundle.meeting_summary.summary {
            transcriptSummary = bundle.meeting_summary.summary;
        }
        if bundle.repo_summary {
            if bundle.repo_summary.project_name {
                projectName = bundle.repo_summary.project_name;
            }
            if bundle.repo_summary.project_type {
                projectType = bundle.repo_summary.project_type;
            }
        }
        if bundle.handoff and bundle.handoff.next_actions {
            nextSteps = bundle.handoff.next_actions;
        } elif bundle.standup and bundle.standup.next {
            nextSteps = bundle.standup.next;
        }
    }
    if runState and runState.summary {
        runSummary = runState.summary;
    }

    def open_context_tab() -> None {
        if setActiveWidgetTab {
            invoke_callback(setActiveWidgetTab, "context");
        }
    }

    def open_tasks_tab() -> None {
        if setActiveWidgetTab {
            invoke_callback(setActiveWidgetTab, "tasks");
        }
    }

    def open_summary_tab() -> None {
        if setActiveWidgetTab {
            invoke_callback(setActiveWidgetTab, "summary");
        }
    }

    async def process_current_context() -> None {
        if processContext {
            await invoke_async_callback(processContext);
        }
    }

    async def ask_current_run() -> None {
        if askAboutRun {
            await invoke_async_callback(askAboutRun);
        }
    }

    async def handle_transcript_upload(e: any) -> None {
        file_list: any = e.target.files;
        if file_list is None or file_list.length == 0 {
            return;
        }
        file: any = file_list[0];
        file_text: any = await file.text();
        if setMeetingText {
            invoke_callback(setMeetingText, str(file_text));
        }
        if setContextFileName {
            invoke_callback(setContextFileName, str(file.name));
        }
    }

    fileRows: list[JsxElement] = [];
    for item in files {
        itemPath: str = safe_text(item.path);
        itemKey: str = itemPath + "::" + str(len(fileRows));
        fileRows.append(
            <div key={itemKey} className="flex min-w-0 items-center gap-3 rounded-xl border border-border/70 bg-panel px-3 py-2 overflow-hidden">
                <span className={file_ext_badge_class(itemPath)}>{file_ext_label(itemPath)}</span>
                <span className="truncate text-[14px] text-foreground" title={itemPath}>{itemPath}</span>
            </div>
        );
    }

    ownershipRows: list[JsxElement] = [];
    for item in ownership {
        ownerKey: str = safe_text(item.area) + "::" + safe_text(item.owner) + "::" + str(len(ownershipRows));
        ownershipRows.append(
            <div key={ownerKey} className="rounded-xl border border-border/70 bg-panel px-3 py-3">
                <div className="text-[14px] font-semibold text-foreground">{safe_text(item.area)}</div>
                <div className="mt-1 text-[13px] text-muted">{safe_text(item.owner)}</div>
            </div>
        );
        if len(ownershipRows) >= 3 {
            break;
        }
    }

    taskCards: list[JsxElement] = [];
    for item in tasks {
        fileTags: list[JsxElement] = [];
        likelyFiles: list[str] = item.likely_files or [];
        for filePath in likelyFiles {
            fileKey: str = safe_text(item.title) + "::file::" + str(len(fileTags));
            fileTags.append(
                <span key={fileKey} className="max-w-full truncate rounded-full border border-border px-2 py-0.5 text-[11px] text-muted">
                    {filePath}
                </span>
            );
            if len(fileTags) >= 3 {
                break;
            }
        }
        taskCards.append(
            <div key={safe_text(item.title) + "::" + str(len(taskCards))} className="min-w-0 overflow-hidden rounded-[1.3rem] border border-border bg-panel-soft/90 p-4">
                <div className="break-words text-[15px] font-semibold text-foreground">{safe_text(item.title)}</div>
                <div className="mt-2 break-words text-[14px] leading-6 text-muted">{safe_text(item.summary)}</div>
                <div className="mt-3 flex flex-wrap gap-2">{fileTags}</div>
            </div>
        );
        if len(taskCards) >= 3 {
            break;
        }
    }

    ticketRows: list[JsxElement] = [];
    for item in tickets {
        ticketRows.append(
            <div key={safe_text(item.title) + "::" + str(len(ticketRows))} className="min-w-0 overflow-hidden rounded-xl border border-border/70 bg-panel px-3 py-3">
                <div className="break-words text-[14px] font-semibold text-foreground">{safe_text(item.title)}</div>
                <div className="mt-1 break-words text-[13px] text-muted">{safe_text(item.summary)}</div>
            </div>
        );
        if len(ticketRows) >= 2 {
            break;
        }
    }

    decisionRows: list[JsxElement] = [];
    for item in decisions {
        decisionRows.append(
            <div key={safe_text(item.title) + "::" + str(len(decisionRows))} className="min-w-0 overflow-hidden rounded-xl border border-border/70 bg-panel px-3 py-3">
                <div className="break-words text-[14px] font-semibold text-foreground">{safe_text(item.title)}</div>
                <div className="mt-1 break-words text-[13px] text-muted">{safe_text(item.detail)}</div>
            </div>
        );
        if len(decisionRows) >= 3 {
            break;
        }
    }

    blockerRows: list[JsxElement] = [];
    for item in blockers {
        blockerRows.append(
            <div key={safe_text(item.title) + "::" + str(len(blockerRows))} className="min-w-0 overflow-hidden rounded-xl border border-danger/20 bg-danger/5 px-3 py-3">
                <div className="break-words text-[14px] font-semibold text-foreground">{safe_text(item.title)}</div>
                <div className="mt-1 break-words text-[13px] text-muted">{safe_text(item.detail)}</div>
            </div>
        );
        if len(blockerRows) >= 2 {
            break;
        }
    }

    nextStepRows: list[JsxElement] = [];
    for item in nextSteps {
        nextStepRows.append(
            <div key={item + "::" + str(len(nextStepRows))} className="min-w-0 break-words rounded-xl border border-border/70 bg-panel px-3 py-3 text-[14px] text-foreground">
                {item}
            </div>
        );
        if len(nextStepRows) >= 3 {
            break;
        }
    }

    historyWindow: list[dict[str, str]] = followUpHistory;
    if len(historyWindow) > 4 {
        historyWindow = historyWindow[len(historyWindow) - 4:];
    }

    queryRows: list[JsxElement] = [];
    for item in historyWindow {
        role: str = item["role"];
        content: str = item["content"];
        item_key: str = role + "::" + str(len(queryRows));
        if role == "assistant" {
            rendered_html: str = md_to_html(content);
            queryRows.append(
                <div key={item_key} className="flex">
                    <div
                        className={history_bubble_class(role) + " rg-markdown"}
                        dangerouslySetInnerHTML={{"__html": rendered_html}}
                    />
                </div>
            );
        } else {
            queryRows.append(
                <div key={item_key} className="flex">
                    <div className={history_bubble_class(role)}>{content}</div>
                </div>
            );
        }
    }

    errorBanner: JsxElement = <div />;
    if error {
        errorBanner = <div className="mx-5 mt-4 rounded-2xl border border-danger/40 bg-danger/10 px-4 py-3 text-[14px] text-foreground">
            {error}
        </div>;
    }

    processedContextBody: JsxElement = <div className="space-y-3 min-w-0">
        <div className={card_class() + " space-y-3"}>
            <div className="flex items-center justify-between gap-3">
                {section_label("Grounded Files")}
                <span className="text-[12px] text-muted">{str(len(files)) + " files"}</span>
            </div>
            <div className="space-y-2 min-w-0 max-h-[260px] overflow-y-auto repoghost-scroll pr-1">{fileRows}</div>
        </div>
        {(
            <div className={card_class() + " space-y-3"}>
                {section_label("Ownership Map")}
                <div className="grid grid-cols-1 gap-3">{ownershipRows}</div>
            </div>
            if len(ownershipRows) > 0
            else <div />
        )}
    </div>;

    emptyContextBody: JsxElement = <div className={card_class()}>
        <div className="text-[14px] font-semibold text-foreground">Add a repo and transcript, then process context.</div>
    </div>;

    contextTail: JsxElement = emptyContextBody;
    if hasProcessedContext {
        contextTail = processedContextBody;
    }

    contextContent: JsxElement = <div className="space-y-4">
        <div className={card_class() + " space-y-4"}>
            <div className="flex items-center justify-between gap-3">
                {section_label("Context Input")}
                <span className={status_badge_class(runState, loading)}>{status_badge_label(runState, loading)}</span>
            </div>
            <div>
                <div className="mb-2 text-[14px] font-semibold text-foreground">Repository Path</div>
                <input
                    type="text"
                    value={repoPath}
                    onChange={lambda (e: any) -> None { if setRepoPath { invoke_callback(setRepoPath, e.target.value); } }}
                    placeholder="C:/path/to/repo or https://github.com/user/repo"
                    className="w-full rounded-2xl border border-border bg-panel px-4 py-3 text-[15px] text-foreground outline-none placeholder:text-muted focus:border-accent transition-colors"
                />
            </div>
            <div>
                <div className="mb-2 text-[14px] font-semibold text-foreground">Meeting / Transcript</div>
                <textarea
                    value={meetingText}
                    onChange={lambda (e: any) -> None {
                        if setContextFileName { invoke_callback(setContextFileName, ""); }
                        if setMeetingText { invoke_callback(setMeetingText, e.target.value); }
                    }}
                    placeholder="Paste transcript notes, decisions, or discussion highlights..."
                    rows={5}
                    className="w-full rounded-2xl border border-border bg-panel px-4 py-3 text-[15px] text-foreground outline-none placeholder:text-muted focus:border-accent transition-colors resize-none"
                />
            </div>
            <div>
                <div className="mb-2 text-[14px] font-semibold text-foreground">Text File Upload</div>
                <input
                    type="file"
                    accept=".txt,.md,.mdx,.log,text/plain,text/markdown"
                    onChange={handle_transcript_upload}
                    className="w-full rounded-2xl border border-border bg-panel px-4 py-3 text-[14px] text-foreground"
                />
                <div className="mt-2 text-[12px] text-muted">
                    {contextFileName if contextFileName else "Upload fills the transcript field."}
                </div>
            </div>
            <button
                onClick={process_current_context}
                disabled={contextLoading}
                className="w-full inline-flex items-center justify-center gap-2.5 rounded-2xl bg-accent px-5 py-3 text-[15px] font-semibold text-background transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60"
            >
                {(<span className="rg-spinner" /> if contextLoading else <span />)}
                {(processLabel if contextLoading else "Process Context")}
            </button>
        </div>
        {contextTail}
    </div>;

    processedTasksBody: JsxElement = <div className="space-y-3 min-w-0">
        {(
            <div className={card_class() + " space-y-3"}>
                {section_label("Execution Tasks")}
                <div className="grid grid-cols-1 gap-3 min-w-0">{taskCards}</div>
            </div>
            if len(taskCards) > 0
            else <div className={card_class()}>
                <div className="text-[14px] text-muted">No tasks generated for this run.</div>
            </div>
        )}
        {(
            <div className={card_class() + " space-y-3"}>
                {section_label("Ticket Preview")}
                <div className="grid grid-cols-1 gap-3 min-w-0">{ticketRows}</div>
            </div>
            if len(ticketRows) > 0
            else <div />
        )}
    </div>;

    emptyTasksBody: JsxElement = <div className={card_class()}>
        <div className="text-[14px] font-semibold text-foreground">Process context to generate tasks.</div>
    </div>;

    tasksContent: JsxElement = emptyTasksBody;
    if hasProcessedContext {
        tasksContent = processedTasksBody;
    }

    processedSummaryBody: JsxElement = <div className="space-y-3 min-w-0">
        <div className={card_class()}>
            {section_label("Project / Run Summary")}
            <div className="mt-3 text-[15px] font-semibold text-foreground">{projectName}</div>
            <div className="mt-2 break-words text-[14px] leading-6 text-muted">{runSummary}</div>
            {(<div /> if not projectType else <div className="mt-3 inline-flex rounded-full border border-accent/30 bg-accent/10 px-3 py-1 text-[12px] font-medium text-accent">{projectType}</div>)}
        </div>
        {(
            <div className={card_class()}>
                {section_label("Transcript Summary")}
                <div className="mt-3 break-words text-[14px] leading-6 text-foreground">{transcriptSummary}</div>
            </div>
            if transcriptSummary
            else <div />
        )}
        {(
            <div className={card_class() + " space-y-3"}>
                {section_label("Decisions")}
                <div className="grid grid-cols-1 gap-3">{decisionRows}</div>
            </div>
            if len(decisionRows) > 0
            else <div />
        )}
        {(
            <div className={card_class() + " space-y-3"}>
                {section_label("Current Blockers")}
                <div className="grid grid-cols-1 gap-3">{blockerRows}</div>
            </div>
            if len(blockerRows) > 0
            else <div />
        )}
        {(
            <div className={card_class() + " space-y-3"}>
                {section_label("Next Steps")}
                <div className="grid grid-cols-1 gap-3">{nextStepRows}</div>
            </div>
            if len(nextStepRows) > 0
            else <div />
        )}
        <div className={card_class() + " flex flex-col gap-3"}>
            {section_label("Ask About This Run")}
            {(<div className="flex flex-col gap-3 max-h-[420px] overflow-y-auto repoghost-scroll pr-1">{queryRows}</div> if len(queryRows) > 0 else <div />)}
            <textarea
                value={followUpPrompt}
                onChange={lambda (e: any) -> None { if setFollowUpPrompt { invoke_callback(setFollowUpPrompt, e.target.value); } }}
                placeholder="Ask about this run."
                rows={3}
                className="w-full rounded-2xl border border-border bg-panel px-4 py-3 text-[15px] text-foreground outline-none placeholder:text-muted focus:border-accent transition-colors resize-none"
            />
            <button
                onClick={ask_current_run}
                disabled={queryLoading}
                className="w-full inline-flex items-center justify-center rounded-2xl bg-accent px-5 py-3 text-[15px] font-semibold text-background transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60"
            >
                {("Thinking..." if queryLoading else "Ask")}
            </button>
        </div>
    </div>;

    emptySummaryBody: JsxElement = <div className={card_class()}>
        <div className="text-[14px] font-semibold text-foreground">Process context to unlock the summary.</div>
    </div>;

    summaryContent: JsxElement = emptySummaryBody;
    if hasProcessedContext {
        summaryContent = processedSummaryBody;
    }

    tabContent: JsxElement = contextContent;
    if activeWidgetTab == "tasks" {
        tabContent = tasksContent;
    } elif activeWidgetTab == "summary" {
        tabContent = summaryContent;
    }

    subtitle: str = "Repo sidecar";

    def do_prompt_new_ghost() -> None {
        if promptNewGhost {
            invoke_noarg_callback(promptNewGhost);
        }
    }

    def do_cancel_new_ghost() -> None {
        if cancelNewGhost {
            invoke_noarg_callback(cancelNewGhost);
        }
    }

    def do_confirm_new_ghost() -> None {
        if confirmNewGhost {
            invoke_noarg_callback(confirmNewGhost);
        }
    }

    def do_toggle_theme() -> None {
        if toggleTheme { invoke_noarg_callback(toggleTheme); }
    }

    def do_toggle_contrast() -> None {
        if toggleContrast { invoke_noarg_callback(toggleContrast); }
    }

    def do_toggle_settings_editor() -> None {
        if toggleSettingsEditor {
            invoke_noarg_callback(toggleSettingsEditor);
        }
    }

    def do_save_api_settings() -> None {
        if saveApiSettings { invoke_noarg_callback(saveApiSettings); }
    }

    def do_clear_api_settings() -> None {
        if clearApiSettings { invoke_noarg_callback(clearApiSettings); }
    }

    destroy_btn: JsxElement = <div />;
    if confirmingNewGhost {
        destroy_btn = <div className="flex items-center gap-2">
            <span className="text-[12px] text-muted">Destroy session?</span>
            <button
                onClick={do_confirm_new_ghost}
                className="inline-flex h-8 items-center justify-center rounded-full bg-danger/80 px-3 text-[12px] font-semibold text-white transition hover:bg-danger"
            >
                Yes
            </button>
            <button
                onClick={do_cancel_new_ghost}
                className="inline-flex h-8 items-center justify-center rounded-full border border-border bg-panel/85 px-3 text-[12px] font-medium text-foreground transition hover:bg-panel-elevated"
            >
                No
            </button>
        </div>;
    } else {
        destroy_btn = <button
            onClick={do_prompt_new_ghost}
            className="inline-flex h-8 items-center justify-center rounded-full border border-border/60 bg-panel/60 px-3 text-[12px] font-medium text-muted transition hover:border-danger/50 hover:bg-danger/10 hover:text-danger"
            title="Destroy session and start over"
        >
            Destroy Session
        </button>;
    }

    headerIconBtn: str = "inline-flex h-10 w-10 shrink-0 aspect-square items-center justify-center rounded-full border border-border bg-panel/85 text-[18px] leading-none text-foreground transition hover:bg-panel-elevated";
    headerActionBtn: str = "inline-flex h-10 items-center justify-center rounded-full border border-border bg-panel/85 px-4 text-[13px] font-medium text-foreground transition hover:bg-panel-elevated";
    headerActionBtnActive: str = "inline-flex h-10 items-center justify-center rounded-full border border-accent/60 bg-accent/10 px-4 text-[13px] font-medium text-accent transition";

    settings_content: JsxElement = <div className="flex flex-col gap-4">
        <div>
            <div className="mb-1.5 text-[13px] font-semibold text-foreground">Model</div>
            <select
                value={selectedModel}
                onChange={lambda (e: any) -> None { if updateSelectedModel { invoke_callback(updateSelectedModel, e.target.value); } }}
                className="w-full rounded-xl border border-border bg-panel px-3 py-2 text-[14px] text-foreground outline-none focus:border-accent transition-colors"
            >
                {widget_model_options(modelOptions)}
            </select>
        </div>
        <div>
            <div className="mb-1.5 text-[13px] font-semibold text-foreground">API Key</div>
            <input
                type="password"
                value={userApiKey}
                onChange={lambda (e: any) -> None { if updateUserApiKey { invoke_callback(updateUserApiKey, e.target.value); } }}
                placeholder="sk-..."
                className="w-full rounded-xl border border-border bg-panel px-3 py-2 text-[14px] text-foreground outline-none placeholder:text-muted focus:border-accent transition-colors"
            />
        </div>
        <div className="flex items-center gap-2">
            <input
                type="checkbox"
                id="widget-remember"
                checked={rememberSettings}
                onChange={lambda (e: any) -> None { if updateRememberSettings { invoke_callback(updateRememberSettings, e.target.checked); } }}
                className="h-4 w-4 rounded accent-accent"
            />
            <label htmlFor="widget-remember" className="cursor-pointer text-[13px] text-muted">Remember on this device</label>
        </div>
        <div className="flex gap-2">
            <button
                onClick={do_save_api_settings}
                className="inline-flex flex-1 items-center justify-center rounded-xl bg-accent px-4 py-2 text-[13px] font-semibold text-background transition hover:brightness-110"
            >
                Save
            </button>
            <button
                onClick={do_clear_api_settings}
                className="inline-flex items-center justify-center rounded-xl border border-border px-4 py-2 text-[13px] font-medium text-muted transition hover:bg-danger/10 hover:text-danger"
            >
                Clear Key
            </button>
        </div>
    </div>;

    desktop_settings_panel: JsxElement = <div />;
    if settingsEditorOpen {
        desktop_settings_panel = <div className="hidden border-b border-border px-5 py-4 md:block">
            {settings_content}
        </div>;
    }

    return <div className="repoghost-widget flex h-[calc(100vh-32px)] w-full min-w-0 max-w-none flex-col overflow-hidden rounded-[1.7rem] border border-border bg-panel/95 shadow-[var(--shadow-glow)]">
        <div className="border-b border-border px-4 py-3.5">
            <div className="flex min-w-0 items-center justify-between gap-3">
                <div className="flex min-w-0 items-center gap-3">
                    <span className="text-[22px]">👻</span>
                    <div className="min-w-0">
                        <div className="text-[18px] font-semibold tracking-tight text-foreground">repoGhost</div>
                        <div className="truncate text-[12px] text-muted">{subtitle}</div>
                    </div>
                </div>
                <div className="flex shrink-0 flex-wrap items-center justify-end gap-1.5">
                    <select
                        value={selectedModel}
                        onChange={lambda (e: any) -> None { if updateSelectedModel { invoke_callback(updateSelectedModel, e.target.value); } }}
                        className="h-10 max-w-[160px] rounded-full border border-border bg-panel/85 px-4 text-[13px] text-foreground outline-none transition-colors focus:border-accent"
                    >
                        {widget_model_options(modelOptions)}
                    </select>
                    <button
                        onClick={do_toggle_theme}
                        className={headerIconBtn}
                        title={"Switch to light mode" if themeMode == "dark" else "Switch to dark mode"}
                    >
                        {"☀" if themeMode == "dark" else "☾"}
                    </button>
                    <button
                        onClick={do_toggle_contrast}
                        className={headerIconBtn}
                        title={"High contrast" if contrastMode == "standard" else "Standard contrast"}
                    >
                        {"◐" if contrastMode == "standard" else "◎"}
                    </button>
                    <button
                        onClick={do_toggle_settings_editor}
                        className={(headerActionBtnActive if settingsEditorOpen else headerActionBtn)}
                        title="API Key settings"
                    >
                        🔑 API Key
                    </button>
                    {destroy_btn}
                </div>
            </div>
        </div>
        {desktop_settings_panel}

        {errorBanner}

        <div className="flex border-b border-border">
            <button onClick={open_context_tab} className={tab_class("context", activeWidgetTab)}>Context</button>
            <button onClick={open_tasks_tab} className={tab_class("tasks", activeWidgetTab)}>Tasks</button>
            <button onClick={open_summary_tab} className={tab_class("summary", activeWidgetTab)}>Summary</button>
        </div>

        <div className="repoghost-scroll flex-1 min-w-0 overflow-y-auto overflow-x-hidden px-5 py-4">
            {tabContent}
        </div>
    </div>;
}
