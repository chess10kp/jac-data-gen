"""
NovaDiff — Jac Frontend
Single-file full-stack React-style UI
"""
import from .main {
    GetDiffs, StageFile, UnstageFile, CommitChanges, PushChanges, StashChanges,
    BugHunterAgent, SecurityAgent, QualityAgent, SummaryAgent, ExplainWalker,
    QuizWalker, CommitWalker
}

import from "@monaco-editor/react" { default as Editor }

def:pub app() -> JsxElement {
    # -- State ------------------------------------------------------------
    has staged: list = [];
    has unstaged: list = [];
    has selected: dict = {};
    has full_diff: str = "";
    has diff_hash: str = "";
    has view_mode: str = "unified";

    # tabs: review | explain | quiz | commit
    has tab: str = "review";

    # review state
    has findings: list = [];
    has summary: str = "";
    has reviewing: bool = False;

    # explain state
    has question: str = "";
    has chat: list = [];
    has explaining: bool = False;

    # quiz state
    has quiz_qs: list = [];
    has quiz_ans: dict = {};
    has quiz_done: bool = False;
    has quiz_score: int = 0;
    has quiz_passed: bool = False;
    has strict_mode: bool = True;
    has gen_quiz: bool = False;

    # commit state
    has commit_msg: str = "";
    has commit_style: str = "conventional";
    has gen_commit: bool = False;
    has committing: bool = False;

    has err: str = "";
    has sidebar_open: bool = True;
    has activity_tab: str = "scm";

    def set_err(v: str) { err = v; }
    def set_tab(v: str) { tab = v; }
    def set_question(v: str) { question = v; }
    def set_strict_mode(v: bool) { strict_mode = v; }
    def set_commit_msg(v: str) { commit_msg = v; }
    def set_commit_style(v: str) { commit_style = v; }
    def set_view_mode(v: str) { view_mode = v; }
    def do_select(f: dict) { selected = f; }
    def update_quiz_ans(qid: str, val: int) {
        new_ans = dict(quiz_ans);
        new_ans[qid] = val;
        quiz_ans = new_ans;
    }

    async def do_init() {
        api_url = "";
        reg_payload = JSON.stringify({"identities": [{"type": "username", "value": "diffmind@dev.local"}], "credential": {"type": "password", "password": "diffmind_dev_2026"}});
        login_payload = JSON.stringify({"identity": {"type": "username", "value": "diffmind@dev.local"}, "credential": {"type": "password", "password": "diffmind_dev_2026"}});
        try {
            await fetch(str(api_url) + "/user/register", {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": reg_payload
            });
        } except Exception {}

        try {
            res: any = await fetch(str(api_url) + "/user/login", {
                "method": "POST",
                "headers": {"Content-Type": "application/json"},
                "body": login_payload
            });
            data: any = await res.json();
            if data["data"] and data["data"]["token"] {
                token: str = data["data"]["token"];
                localStorage.setItem("jac_token", token);
                await refresh();
            }
        } except Exception as e {
            err = str(e);
        }
    }

    async can with entry {
        await do_init();
    }

    # -- Actions ----------------------------------------------------------
    async def refresh() {
        try {
            r = root spawn GetDiffs();
            d = r.reports[0] if r.reports else {};
            staged = list(d["staged"]) if "staged" in d else [];
            unstaged = list(d["unstaged"]) if "unstaged" in d else [];
            full_diff = str(d["full_diff"]) if "full_diff" in d else "";
            diff_hash = str(d["diff_hash"]) if "diff_hash" in d else "";
        } except Exception as e {
            err = str(e);
        }
    }

    async def do_stage(fp: str) {
        await root spawn StageFile(file_path=fp);
        await new(Promise, lambda (resolve: any, reject: any) { setTimeout(lambda { resolve.call(None, None); }, 200); });
        await refresh();
    }

    async def do_unstage(fp: str) {
        await root spawn UnstageFile(file_path=fp);
        await new(Promise, lambda (resolve: any, reject: any) { setTimeout(lambda { resolve.call(None, None); }, 200); });
        await refresh();
    }

    async def run_review() {
        reviewing = True;
        findings = [];
        summary = "";
        try {
            diff_ctx = str(selected["diff_content"]) if "diff_content" in selected else full_diff;
            repo_ctx = "diffmind-jac";
            bug_r = root spawn BugHunterAgent(diff=diff_ctx, repo=repo_ctx);
            sec_r = root spawn SecurityAgent(diff=diff_ctx, repo=repo_ctx);
            qual_r = root spawn QualityAgent(diff=diff_ctx, repo=repo_ctx);
            all_f: list = [];
            for res in [bug_r, sec_r, qual_r] {
                reps = res.reports;
                data = reps[0] if len(reps) > 0 else {};
                cat = str(data["category"]) if "category" in data else "";
                for f in list(data["findings"]) if "findings" in data else [] {
                    f["category"] = cat;
                    all_f.append(f);
                }
            }
            sev = {"critical": 0, "warning": 1, "suggestion": 2};
            findings = all_f;
            if all_f {
                sum_r = root spawn SummaryAgent(findings=all_f);
                sum_reps = sum_r.reports;
                sum_d = sum_reps[0] if len(sum_reps) > 0 else {};
                summary = str(sum_d["summary"]) if "summary" in sum_d else "";
            } else {
                summary = "No issues found. The code changes look clean! ✅";
            }
        } except Exception as e {
            err = str(e);
        }
        reviewing = False;
    }

    async def ask() {
        if not question { return; }
        explaining = True;
        q = question;
        question = "";
        try {
            diff_ctx = str(selected["diff_content"]) if "diff_content" in selected else full_diff;
            r = root spawn ExplainWalker(diff=diff_ctx, question=q);
            reps = r.reports;
            d = reps[0] if len(reps) > 0 else {};
            ans = str(d["answer"]) if "answer" in d else "";
            chat = chat + [{"q": q, "a": ans}];
        } except Exception as e {
            err = str(e);
        }
        explaining = False;
    }

    async def make_quiz() {
        gen_quiz = True;
        quiz_qs = [];
        quiz_ans = {};
        quiz_done = False;
        try {
            r = root spawn QuizWalker(diff=full_diff, count=5, difficulty="medium", focus="comprehension");
            reps = r.reports;
            d = reps[0] if len(reps) > 0 else {};
            err_msg = str(d["error"]) if "error" in d and d["error"] else "";
            if err_msg { err = err_msg; }
            quiz_qs = list(d["questions"]) if "questions" in d else [];
        } except Exception as e {
            err = str(e);
        }
        gen_quiz = False;
    }

    def submit_quiz() {
        if not quiz_qs { return; }
        correct: int = 0;
        for q in quiz_qs {
            q_id = str(q["id"]) if "id" in q else "";
            ans_idx = int(q["answerIndex"]) if "answerIndex" in q else -1;
            user_ans = int(quiz_ans[q_id]) if q_id in quiz_ans else -1;
            if user_ans == ans_idx {
                correct = correct + 1;
            }
        }
        quiz_score = correct;
        quiz_done = True;
        quiz_passed = (correct / len(quiz_qs)) >= 0.7;
    }

    async def make_commit_msg() {
        gen_commit = True;
        try {
            staged_diff: str = "";
            for f in staged { staged_diff = staged_diff + str(f["diff_content"] if "diff_content" in f else ""); }
            r = root spawn CommitWalker(diff=staged_diff if staged_diff else full_diff, style=commit_style);
            reps = r.reports;
            d = reps[0] if len(reps) > 0 else {};
            commit_msg = str(d["message"]) if "message" in d else "";
        } except Exception as e {
            err = str(e);
        }
        gen_commit = False;
    }

    async def do_commit() {
        if not commit_msg { return; }
        if strict_mode and not quiz_passed {
            err = "⚠️ Strict Mode: Pass the quiz before committing!";
            return;
        }
        committing = True;
        r = root spawn CommitChanges(message=commit_msg);
        reps = r.reports;
        d = reps[0] if reps else {};
        if d["ok"] if "ok" in d else False {
            commit_msg = "";
            await refresh();
        } else {
            err = str(d["error"]) if "error" in d else "Commit failed";
        }
        committing = False;
    }

    async def do_push() {
        r = root spawn PushChanges();
        reps = r.reports;
        d = reps[0] if reps else {};
        if not (d["ok"] if "ok" in d else False) { err = str(d["error"]) if "error" in d else "Push failed"; }
    }

    async def do_stash() {
        root spawn StashChanges();
        await refresh();
    }

    # -- Helpers ----------------------------------------------------------
    def sev_color(s: str) -> str {
        if s == "critical" { return "#f14c4c"; }
        elif s == "warning" { return "#cca700"; }
        return "#3794ff";
    }
    def cat_icon(c: str) -> str {
        if c == "bug" { return ""; } # VS Code Error icon placeholder or just generic
        elif c == "security" { return ""; } # VS Code Warning
        return ""; # Info
    }

    def get_line_bg(line: str) -> str {
        if not line { return "transparent"; }
        c = line[0];
        if c == "+" and "+++" not in line { return "rgba(46, 160, 67, 0.2)"; }
        if c == "-" and "---" not in line { return "rgba(248, 81, 73, 0.2)"; }
        if c == "@" { return "rgba(56, 139, 253, 0.15)"; }
        return "transparent";
    }

    def get_line_color(line: str) -> str {
        if not line { return "#cccccc"; }
        c = line[0];
        if c == "+" and "+++" not in line { return "#6bbb5d"; }
        if c == "-" and "---" not in line { return "#d16969"; }
        if c == "@" { return "#569cd6"; }
        return "#cccccc";
    }

    def render_file_item_staged(f: dict) -> JsxElement {
        bg_col = "#2a2d2e" if selected.get("file_path","") == f.get("file_path","") else "transparent";
        br_col = "2px solid #007fd4" if selected.get("file_path","") == f.get("file_path","") else "2px solid transparent";
        return (
            <div key={f.get("file_path","")} onClick={lambda (_: MouseEvent) { do_select(f); }} style={{"padding":"4px 12px","cursor":"pointer","background":bg_col,"borderLeft":br_col,"display":"flex","alignItems":"center","gap":"8px","transition":"background 0.1s"}}>
                <span style={{"flex":"1","fontSize":"13px","overflow":"hidden","textOverflow":"ellipsis","whiteSpace":"nowrap","color":"#cccccc"}}>{f.get("file_path","").split("/")[-1]}</span>
                <span style={{"fontSize":"11px","color":"#6bbb5d"}}>+{f.get("additions",0)}</span>
                <span style={{"fontSize":"11px","color":"#d16969"}}>-{f.get("deletions",0)}</span>
                <button onClick={lambda (_: MouseEvent) { do_unstage(f.get("file_path","")); }} style={{"background":"transparent","border":"none","color":"#cccccc","cursor":"pointer","fontSize":"16px","lineHeight":"1"}}>-</button>
            </div>
        );
    }

    def render_file_item_unstaged(f: dict) -> JsxElement {
        bg_col = "#2a2d2e" if selected.get("file_path","") == f.get("file_path","") else "transparent";
        br_col = "2px solid #007fd4" if selected.get("file_path","") == f.get("file_path","") else "2px solid transparent";
        return (
            <div key={f.get("file_path","")} onClick={lambda (_: MouseEvent) { do_select(f); }} style={{"padding":"4px 12px","cursor":"pointer","background":bg_col,"borderLeft":br_col,"display":"flex","alignItems":"center","gap":"8px","transition":"background 0.1s"}}>
                <span style={{"flex":"1","fontSize":"13px","overflow":"hidden","textOverflow":"ellipsis","whiteSpace":"nowrap","color":"#cccccc"}}>{f.get("file_path","").split("/")[-1]}</span>
                <span style={{"fontSize":"11px","color":"#6bbb5d"}}>+{f.get("additions",0)}</span>
                <span style={{"fontSize":"11px","color":"#d16969"}}>-{f.get("deletions",0)}</span>
                <button onClick={lambda (_: MouseEvent) { do_stage(f.get("file_path","")); }} style={{"background":"transparent","border":"none","color":"#cccccc","cursor":"pointer","fontSize":"14px","lineHeight":"1"}}>+</button>
            </div>
        );
    }

    # -- Render helpers ---------------------------------------------------
    def render_file_list(files: list, is_staged: bool) -> JsxElement {
        label = "Staged Changes" if is_staged else "Changes";
        
        if is_staged {
            return (
                <div style={{"marginBottom":"12px"}}>
                    <div style={{"fontSize":"11px","fontWeight":"700","color":"#cccccc","textTransform":"uppercase","padding":"6px 20px","display":"flex","alignItems":"center","gap":"4px"}}>{icon_chevron_down()}{label} <span style={{"marginLeft":"auto","background":"#333333","padding":"1px 6px","borderRadius":"10px","color":"#cccccc"}}>{len(files)}</span></div>
                    {[render_file_item_staged(f) for f in files]}
                </div>
            );
        }
        return (
            <div style={{"marginBottom":"12px"}}>
                <div style={{"fontSize":"11px","fontWeight":"700","color":"#cccccc","textTransform":"uppercase","padding":"6px 20px","display":"flex","alignItems":"center","gap":"4px"}}>{icon_chevron_down()}{label} <span style={{"marginLeft":"auto","background":"#333333","padding":"1px 6px","borderRadius":"10px","color":"#cccccc"}}>{len(files)}</span></div>
                {[render_file_item_unstaged(f) for f in files]}
            </div>
        );
    }

    def get_finding_count() -> JsxElement {
        if findings {
            return <span style={{"fontSize":"11px","color":"#cccccc","background":"#4d4d4d","padding":"2px 6px","borderRadius":"10px"}}>{len(findings)} findings</span>;
        }
        return <div/>;
    }

    def get_summary_box() -> JsxElement {
        if summary {
            return <div style={{"background":"#2d2d2d","borderLeft":"3px solid #007fd4","padding":"10px 12px","marginBottom":"16px","fontSize":"13px","lineHeight":"1.5","color":"#cccccc"}}>{summary}</div>;
        }
        return <div/>;
    }

    def get_empty_state() -> JsxElement {
        if not findings and not reviewing and not summary {
            return <div style={{"textAlign":"center","color":"#858585","padding":"40px","fontSize":"13px"}}>Click "Run Code Review" to start 3 parallel AI agents</div>;
        }
        return <div/>;
    }

    def render_finding(f: dict, i: int) -> JsxElement {
        b_col = f"2px solid {sev_color(f.get('severity',''))}";
        s_col = sev_color(f.get("severity",""));
        return (
            <div key={i} style={{"background":"#252526","borderTop":"1px solid #3c3c3c","borderLeft":b_col,"padding":"10px 12px","marginBottom":"8px"}}>
                <div style={{"display":"flex","gap":"8px","alignItems":"center","marginBottom":"4px"}}>
                    <span style={{"fontSize":"11px","color":s_col,"textTransform":"uppercase","fontWeight":"600","letterSpacing":"0.5px"}}>{f.get("severity","")}</span>
                    <span style={{"fontSize":"13px","color":"#cccccc"}}>{f.get("title","")}</span>
                </div>
                <div style={{"fontSize":"12px","color":"#858585","lineHeight":"1.5"}}>{f.get("description","")}</div>
            </div>
        );
    }

    def render_review_tab() -> JsxElement {
        btn_op = "0.6" if reviewing else "1";
        btn_txt = "Running agents…" if reviewing else "Run Code Review";
        return (
            <div className="animate-fade" style={{"padding":"16px","overflowY":"auto","flex":"1"}}>
                <div style={{"display":"flex","gap":"8px","marginBottom":"16px","alignItems":"center","flexWrap":"wrap"}}>
                    <button
                        onClick={lambda (_: MouseEvent) { run_review(); }}
                        disabled={reviewing}
                        style={{"background":"#007fd4","border":"1px solid transparent","color":"white","padding":"4px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"12px","opacity":btn_op}}
                    >{btn_txt}</button>
                    {get_finding_count()}
                </div>
                {get_summary_box()}
                {[render_finding(f, i) for (i, f) in enumerate(findings)]}
                {get_empty_state()}
            </div>
        );
    }

    def get_empty_chat() -> JsxElement {
        if not chat {
            return <div style={{"textAlign":"center","color":"#858585","padding":"40px","fontSize":"13px"}}>Ask anything about the diff — "What changed?", "Any risks?", "Why this approach?"</div>;
        }
        return <div/>;
    }

    def get_thinking_indicator() -> JsxElement {
        if explaining {
            return <div style={{"color":"#858585","fontSize":"13px","padding":"4px 8px"}}>DiffMind is thinking…</div>;
        }
        return <div/>;
    }

    def render_chat_msg(m: dict, i: int) -> JsxElement {
        return (
            <div key={i} style={{"marginBottom":"16px"}}>
                <div style={{"background":"#2d2d2d","borderLeft":"2px solid #007fd4","padding":"8px 12px","marginBottom":"8px","fontSize":"13px","color":"#cccccc"}}>{m.get("q","")}</div>
                <div style={{"background":"transparent","padding":"0 4px","fontSize":"13px","lineHeight":"1.5","color":"#cccccc","whiteSpace":"pre-wrap"}}>{m.get("a","")}</div>
            </div>
        );
    }

    def render_explain_tab() -> JsxElement {
        return (
            <div style={{"display":"flex","flexDirection":"column","flex":"1","overflow":"hidden"}}>
                <div className="animate-fade" style={{"flex":"1","overflowY":"auto","padding":"16px"}}>
                    {get_empty_chat()}
                    {[render_chat_msg(m, i) for (i, m) in enumerate(chat)]}
                    {get_thinking_indicator()}
                </div>
                <div style={{"padding":"12px 16px","borderTop":"none","display":"flex","gap":"8px","background":"#252526"}}>
                    <input
                        value={question}
                        onChange={lambda (e: ChangeEvent) { set_question(e.target.value); }}
                        onKeyDown={lambda (e: KeyboardEvent) { if e.key == "Enter" { ask(); } }}
                        placeholder="Ask about the diff…"
                        style={{"flex":"1","background":"#3c3c3c","border":"1px solid transparent","borderRadius":"2px","padding":"6px 8px","color":"#cccccc","fontSize":"13px","outline":"none"}}
                    />
                    <button onClick={lambda (_: MouseEvent) { ask(); }} disabled={explaining} style={{"background":"#007fd4","border":"none","color":"white","padding":"6px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"13px"}}>Ask</button>
                </div>
            </div>
        );
    }

    def get_quiz_submit_btn() -> JsxElement {
        if quiz_qs and not quiz_done {
            return <button onClick={lambda (_: MouseEvent) { submit_quiz(); }} style={{"background":"#007fd4","border":"none","color":"white","padding":"6px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"13px"}}>Submit</button>;
        }
        return <div/>;
    }

    def get_quiz_result_box() -> JsxElement {
        if quiz_done {
            bg_col = "rgba(46, 160, 67, 0.15)" if quiz_passed else "rgba(248, 81, 73, 0.15)";
            br_col = "1px solid #4ade80" if quiz_passed else "1px solid #f87171";
            icon = "✔" if quiz_passed else "✖";
            txt_col = "#4ade80" if quiz_passed else "#f87171";
            msg = "Passed! Commit unlocked." if quiz_passed else "Not passed. Retake to unlock commit.";
            return <div style={{"background":bg_col,"border":br_col,"padding":"8px 12px","textAlign":"center","marginBottom":"12px"}}><div style={{"fontSize":"13px","fontWeight":"600","color":txt_col}}>{icon} {quiz_score}/{len(quiz_qs)} — {msg}</div></div>;
        }
        return <div/>;
    }



    def render_quiz_option(q: dict, opt: str, oi: int) -> JsxElement {
        q_id = str(q["id"]) if "id" in q else "";
        ans_idx = int(q["answerIndex"]) if "answerIndex" in q else -1;
        user_ans = int(quiz_ans[q_id]) if q_id in quiz_ans else -1;
        bg_col = "#2d2d2d" if user_ans == oi else "transparent";
        txt_col = "#4ade80" if quiz_done and oi == ans_idx else "#cccccc";
        txt_col = "#f87171" if quiz_done and user_ans == oi and oi != ans_idx else txt_col;
        return (
            <label key={oi} style={{"display":"flex","alignItems":"center","gap":"8px","padding":"4px 8px","cursor":"pointer","background":bg_col,"borderLeft": "2px solid #007fd4" if user_ans == oi else "2px solid transparent"}}>
                <input type="radio" name={q_id} checked={user_ans == oi} onChange={lambda (_: ChangeEvent) { update_quiz_ans(q_id, oi); }} disabled={quiz_done} />
                <span style={{"fontSize":"13px","color":txt_col}}>{opt}</span>
            </label>
        );
    }

    def render_quiz_question(q: dict, qi: int) -> JsxElement {
        q_id = str(q["id"]) if "id" in q else "";
        prompt_str = str(q["prompt"]) if "prompt" in q else "";
        opts = list(q["options"]) if "options" in q else [];
        expl = str(q["explanation"]) if "explanation" in q else "";
        expl_jsx = <div style={{"marginTop":"8px","fontSize":"12px","color":"#858585","fontStyle":"italic"}}>{expl}</div> if quiz_done else <div/>;
        
        return (
            <div key={q_id} style={{"background":"#1e1e1e","borderTop":"1px solid #2d2d2d","padding":"12px 14px","marginBottom":"12px"}}>
                <div style={{"fontSize":"13px","fontWeight":"600","color":"#cccccc","marginBottom":"8px"}}>{qi+1}. {prompt_str}</div>
                <div style={{"display":"flex","flexDirection":"column","gap":"4px"}}>
                    {[render_quiz_option(q, opt, oi) for (oi, opt) in enumerate(opts)]}
                </div>
                {expl_jsx}
            </div>
        );
    }

    def render_quiz_tab() -> JsxElement {
        btn_txt = "Generating…" if gen_quiz else "Generate Quiz";
        return (
            <div className="animate-fade" style={{"padding":"16px","overflowY":"auto","flex":"1"}}>
                <div style={{"display":"flex","gap":"8px","marginBottom":"16px","alignItems":"center","justifyContent":"space-between"}}>
                    <button
                        onClick={lambda (_: MouseEvent) { make_quiz(); }}
                        disabled={gen_quiz}
                        style={{"background":"#007fd4","border":"none","color":"white","padding":"4px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"12px"}}
                    >{btn_txt}</button>
                    <span style={{"fontSize":"11px","color":"#cca700","fontWeight":"600","textTransform":"uppercase","letterSpacing":"0.5px","opacity":"0.8"}}>
                        ⚠ Strict Mode
                    </span>
                </div>
                {[render_quiz_question(q, qi) for (qi, q) in enumerate(quiz_qs)]}
                {get_quiz_submit_btn()}
                {get_quiz_result_box()}
            </div>
        );
    }



    def get_warning_strict() -> JsxElement {
        if strict_mode and not quiz_passed {
            return <div style={{"marginTop":"8px","fontSize":"12px","color":"#cca700"}}>⚠️ Strict Mode: Pass the quiz to unlock commit.</div>;
        }
        return <div/>;
    }

    def RenderCommitStyleButton(s: str) -> JsxElement {
        bg_col = "#3c3c3c" if commit_style == s else "transparent";
        txt_col = "#ffffff" if commit_style == s else "#cccccc";
        return <button key={s} onClick={lambda (_: MouseEvent) { set_commit_style(s); }} style={{"background":bg_col,"border":"1px solid transparent","color":txt_col,"padding":"2px 8px","borderRadius":"2px","cursor":"pointer","fontSize":"12px","textTransform":"capitalize"}}>{s}</button>;
    }

    def render_commit_tab() -> JsxElement {
        staged_count = len(staged);
        gen_btn_txt = "Generating…" if gen_commit else "Auto-generate";
        gen_btn_op = "1" if staged_count else "0.5";
        com_btn_txt = "Committing…" if committing else "Commit";
        com_btn_op = "1" if commit_msg and staged_count else "0.5";
        warn_staged = <div style={{"fontSize":"12px","color":"#cca700","marginBottom":"8px"}}>Stage files first to generate a commit message.</div> if not staged_count else <div/>;

        return (
            <div className="animate-fade" style={{"padding":"16px","overflowY":"auto","flex":"1"}}>
                <div style={{"marginBottom":"12px","display":"flex","gap":"4px","flexWrap":"wrap"}}>
                    {for s in ["conventional","descriptive","simple"] { <RenderCommitStyleButton key={s} s={s} /> }}
                </div>
                <button
                    onClick={lambda (_: MouseEvent) { make_commit_msg(); }}
                    disabled={gen_commit or not staged_count or (strict_mode and not quiz_passed)}
                    style={{"background":"#007fd4","border":"none","color":"white","padding":"4px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"12px","marginBottom":"12px","opacity":gen_btn_op}}
                >{gen_btn_txt}</button>
                {warn_staged}
                <textarea
                    value={commit_msg}
                    onChange={lambda (e: ChangeEvent) { set_commit_msg(e.target.value); }}
                    placeholder="Commit message…"
                    rows={4}
                    style={{"width":"100%","background":"#3c3c3c","border":"1px solid transparent","borderRadius":"2px","padding":"8px","color":"#cccccc","fontSize":"13px","resize":"vertical","boxSizing":"border-box","outline":"none","fontFamily":"'JetBrains Mono', 'Fira Code', monospace"}}
                />
                <div style={{"display":"flex","gap":"4px","marginTop":"10px"}}>
                    <button
                        onClick={lambda (_: MouseEvent) { do_commit(); }}
                        disabled={committing or not commit_msg or not staged_count or (strict_mode and not quiz_passed)}
                        style={{"flex":"1","background":"#007fd4","border":"none","color":"white","padding":"6px","borderRadius":"2px","cursor":"pointer","fontSize":"12px","opacity":com_btn_op}}
                    >{com_btn_txt}</button>
                    <button
                        onClick={lambda (_: MouseEvent) { do_push(); }}
                        style={{"background":"transparent","border":"1px solid #3c3c3c","color":"#cccccc","padding":"6px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"12px"}}
                    >Push</button>
                    <button
                        onClick={lambda (_: MouseEvent) { do_stash(); }}
                        style={{"background":"transparent","border":"1px solid #3c3c3c","color":"#cccccc","padding":"6px 12px","borderRadius":"2px","cursor":"pointer","fontSize":"12px"}}
                    >Stash</button>
                </div>
                {get_warning_strict()}
            </div>
        );
    }

    def get_empty_files() -> JsxElement {
        if not staged and not unstaged {
            return <div style={{"textAlign":"center","color":"#858585","padding":"40px 16px","fontSize":"13px"}}>No changes detected.<br/>Make edits in your repo.</div>;
        }
        return <div/>;
    }

    def get_diff_view() -> JsxElement {
        if selected.get("diff_content","") {
            return (
                <Editor
                    height="100%"
                    defaultLanguage="diff"
                    theme="vs-dark"
                    value={selected.get("diff_content","")}
                    options={{
                        "readOnly": True,
                        "minimap": {"enabled": False},
                        "scrollBeyondLastLine": False,
                        "fontSize": 13,
                        "fontFamily": "'JetBrains Mono', 'Fira Code', monospace"
                    }}
                />
            );
        }
        return <div style={{"display":"flex","alignItems":"center","justifyContent":"center","height":"100%","color":"#858585","fontSize":"13px"}}>Select a file from the sidebar to view its diff</div>;
    }

    def get_error_bar() -> JsxElement {
        if err {
            return <div style={{"padding":"6px 12px","background":"rgba(241, 76, 76, 0.15)","borderTop":"1px solid #f14c4c","fontSize":"12px","color":"#f14c4c","display":"flex","alignItems":"center","gap":"8px"}}><span style={{"flex":"1"}}>{err}</span><button onClick={lambda (_: MouseEvent) { set_err(""); }} style={{"background":"transparent","border":"none","color":"#f14c4c","cursor":"pointer","fontSize":"14px"}}>✕</button></div>;
        }
        return <div/>;
    }

    def get_active_tab_view() -> JsxElement {
        if tab == "review" { return render_review_tab(); }
        if tab == "explain" { return render_explain_tab(); }
        if tab == "quiz" { return render_quiz_tab(); }
        return render_commit_tab();
    }

    def RenderViewModeButton(m: str) -> JsxElement {
        bg_col = "#3c3c3c" if view_mode == m else "transparent";
        txt_col = "#ffffff" if view_mode == m else "#cccccc";
        return <button key={m} onClick={lambda (_: MouseEvent) { set_view_mode(m); }} style={{"background":bg_col,"border":"1px solid transparent","color":txt_col,"padding":"2px 6px","borderRadius":"2px","cursor":"pointer","fontSize":"11px","textTransform":"capitalize"}}>{m}</button>;
    }

    def RenderTabButton(ti: tuple) -> JsxElement {
        t = ti[0];
        icon = ti[1];
        txt_col = "#ffffff" if tab == t else "#858585";
        br_col = "1px solid #007fd4" if tab == t else "1px solid transparent";
        return <button key={t} onClick={lambda (_: MouseEvent) { set_tab(t); }} style={{"flex":"1","background":"transparent","border":"none","borderTop":br_col,"color":txt_col,"padding":"8px 0","cursor":"pointer","fontSize":"11px","textTransform":"uppercase","letterSpacing":"0.5px"}}>{t}</button>;
    }

    # -- Main Render ------------------------------------------------------
    def toggle_sidebar() { sidebar_open = not sidebar_open; }

    # SVG Icons
    def icon_explorer() -> JsxElement { return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M4 2v20l-2-2V4h2z" opacity="0"/><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/></svg>; }
    def icon_search() -> JsxElement { return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>; }
    def icon_scm() -> JsxElement { return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><circle cx="18" cy="18" r="3"/><line x1="6" y1="9" x2="6" y2="15"/><line x1="9" y1="18" x2="15" y2="18"/><path d="M18 15v-2a3 3 0 0 0-3-3H6"/></svg>; }
    def icon_cog() -> JsxElement { return <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg>; }
    def icon_x() -> JsxElement { return <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>; }
    def icon_chevron_down() -> JsxElement { return <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="6 9 12 15 18 9"/></svg>; }
    
    def set_activity_tab(t: str) { activity_tab = t; sidebar_open = True; }

    def render_activity_bar() -> JsxElement {
        act_col = "#c5c5c5";
        ina_col = "#858585";
        act_border = "2px solid #007fd4";
        ina_border = "2px solid transparent";

        return (
            <div style={{"width":"48px","display":"flex","flexDirection":"column","background":"#333333","borderRight":"1px solid #252526","alignItems":"center","paddingTop":"10px","justifyContent":"space-between","zIndex":10}}>
                <div style={{"display":"flex","flexDirection":"column","gap":"16px","width":"100%","alignItems":"center"}}>
                    <div onClick={lambda (_: MouseEvent) { set_activity_tab("scm"); }} style={{"cursor":"pointer","color":act_col if activity_tab == "scm" else ina_col,"borderLeft":act_border if activity_tab == "scm" else ina_border,"width":"100%","display":"flex","justifyContent":"center"}}>{icon_scm()}</div>
                </div>
                <div style={{"paddingBottom":"16px","cursor":"pointer","color":ina_col}}>{icon_cog()}</div>
            </div>
        );
    }

    return (
        <div style={{"display":"flex","flexDirection":"column","height":"100vh","background":"#1e1e1e","color":"#cccccc","fontFamily":"'Segoe UI', Tahoma, Geneva, Verdana, sans-serif","overflow":"hidden"}}>
            <style>{"body { margin: 0; padding: 0; background-color: #1e1e1e; overflow: hidden; scrollbar-width: thin; scrollbar-color: #424242 transparent; } ::-webkit-scrollbar { width: 10px; height: 10px; } ::-webkit-scrollbar-track { background: transparent; } ::-webkit-scrollbar-thumb { background: #424242; border: 2px solid transparent; background-clip: padding-box; } ::-webkit-scrollbar-thumb:hover { background: #4f4f4f; } ::-webkit-scrollbar-thumb:active { background: #5a5a5a; } * { box-sizing: border-box; } .animate-fade { animation: fadeIn 0.3s ease-out forwards; } @keyframes fadeIn { from { opacity: 0; transform: translateY(2px); } to { opacity: 1; transform: translateY(0); } }"}</style>

            <div style={{"display":"flex","flex":"1","overflow":"hidden"}}>
                {render_activity_bar()}

                <div style={{"width":"250px","background":"#252526","borderRight":"1px solid #1e1e1e","display":("flex" if sidebar_open else "none"),"flexDirection":"column","flexShrink":"0"}}>
                    <div style={{"padding":"10px 20px","display":"flex","alignItems":"center","gap":"8px"}}>
                        <span style={{"fontSize":"11px","fontWeight":"600","color":"#cccccc","textTransform":"uppercase","letterSpacing":"0.5px"}}>{activity_tab if activity_tab != "scm" else "SOURCE CONTROL"}</span>
                        <button onClick={lambda (_: MouseEvent) { refresh(); }} style={{"marginLeft":"auto","background":"transparent","border":"none","color":"#cccccc","cursor":"pointer","fontSize":"16px","padding":"2px"}} title="Refresh">↺</button>
                    </div>

                    <div style={{"flex":"1","overflowY":"auto","paddingTop":"4px"}}>
                        {render_file_list(staged, True) if activity_tab == "scm" else <div style={{"padding":"20px","fontSize":"12px","color":"#858585"}}>Use the Source Control tab.</div>}
                        {render_file_list(unstaged, False) if activity_tab == "scm" else <div/>}
                        {get_empty_files() if activity_tab == "scm" else <div/>}
                    </div>

                    <div style={{"padding":"10px 16px","borderTop":"1px solid #1e1e1e","fontSize":"11px","color":"#858585"}}>
                        {len(staged)+len(unstaged)} pending changes
                    </div>
                </div>

                <div style={{"flex":"1","display":"flex","flexDirection":"column","overflow":"hidden","minWidth":"0","background":"#1e1e1e"}}>
                    
                    <div style={{"height":"35px","background":"#2d2d2d","display":"flex","alignItems":"center","flexShrink":"0"}}>
                        <div style={{"display":"flex","alignItems":"center","height":"100%","background":"#1e1e1e","padding":"0 10px 0 14px","borderRight":"1px solid #2d2d2d","borderTop":"1px solid #007fd4","gap":"8px","cursor":"pointer"}}>
                            <span style={{"fontSize":"13px","color":"#cccccc","overflow":"hidden","textOverflow":"ellipsis","whiteSpace":"nowrap","maxWidth":"180px"}}>
                                {selected.get("file_path","").split("/")[-1] if selected.get("file_path","") else "Welcome"}
                            </span>
                            {icon_x()}
                        </div>
                    </div>

                    <div style={{"display":"flex","flex":"1","overflow":"hidden"}}>
                        <div style={{"flex":"1","overflowY":"auto","background":"#1e1e1e"}}>
                            {get_diff_view()}
                        </div>

                        <div style={{"width":"380px","background":"#252526","borderLeft":"1px solid #3c3c3c","display":"flex","flexDirection":"column","flexShrink":"0"}}>
                            <div style={{"display":"flex","background":"#2d2d2d"}}>
                                {for x in [("review","🔍"),("explain","💬"),("quiz","🧪"),("commit","📝")] { <RenderTabButton key={x[0]} ti={x} /> }}
                            </div>
                            <div style={{"flex":"1","display":"flex","flexDirection":"column","overflow":"hidden"}}>
                                {get_active_tab_view()}
                            </div>
                            {get_error_bar()}
                        </div>
                    </div>
                </div>
            </div>
            
            <div style={{"height":"22px","background":"#007acc","color":"#ffffff","display":"flex","alignItems":"center","padding":"0 10px","fontSize":"12px","zIndex":20,"flexShrink":0}}>
                <div style={{"display":"flex","alignItems":"center","gap":"16px"}}>
                    <span style={{"cursor":"pointer","display":"flex","alignItems":"center","gap":"4px"}}>{icon_scm()} {len(staged)+len(unstaged)} changes</span>
                    <span>DiffMind</span>
                </div>
                <div style={{"marginLeft":"auto","display":"flex","gap":"12px"}}>
                    <span>{selected.get("language","") if selected.get("language","") else "UTF-8"}</span>
                    <span>Diffing</span>
                </div>
            </div>
        </div>
    );
}


