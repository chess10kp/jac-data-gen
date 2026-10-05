import from react { useState, useEffect, useRef }
import from "@jac/runtime" {
    jacSpawn,
    jacLogin,
    jacSignup,
    jacLogout,
    __invalidateEndpoint
}

    import "./beanbot.css";

    # Single dict param so compiled JS matches calls (multi-arg JSX helpers become props objects).
    def adminButton(props: dict) -> JsxElement {
        return <button
            type="button"
            className="admin-btn"
            disabled={props["disabled"]}
            onClick={props["onClick"]}
        >
            {props["label"]}
        </button>;
    }

    def chatRowStr(row: any, snake: str, camel: str) -> str {
        try {
            if row == None {
                return "";
            }
            v = row[snake];
            if v != None and str(v) != "" {
                return str(v);
            }
        } except Exception {
            ;
        }
        try {
            v2 = row[camel];
            if v2 != None {
                return str(v2);
            }
        } except Exception {
            ;
        }
        return "";
    }

    def msgClass(t: str) -> str {
        if t == "action_confirm" {
            return "msg msg-confirm";
        }
        if t == "followup" {
            return "msg msg-followup";
        }
        if t == "success" {
            return "msg msg-success";
        }
        if t == "manager_nudge" {
            return "msg msg-nudge";
        }
        return "msg msg-reply";
    }

    def parseManagerNudgeContent(raw: str) -> dict {
        try {
            o: any = JSON.parse(str(raw));
            fid = "";
            body = "";
            if o {
                if o.fetch_request_id {
                    fid = str(o.fetch_request_id);
                }
                if o.prompt_text {
                    body = str(o.prompt_text);
                }
            }
            if fid != "" {
                return {"fetch_id": fid, "body": body};
            }
        } except Exception {
            ;
        }
        return {"fetch_id": "", "body": str(raw)};
    }

    def msgRoleLabel(r: str) -> str {
        lr = str(r).lower();
        if lr == "assistant" {
            return "Assistant";
        }
        if lr == "user" {
            return "You";
        }
        return str(r);
    }

    # Param must be named `props` for client JSX compile (other names get wrapped as {row: {...}}).
    def draftPreviewRow(props: dict) -> JsxElement {
        label = str(props["label"]);
        val = props["val"];
        vx = "";
        if val != None {
            vx = str(val);
        }
        if vx.strip() == "" {
            return <span className="bb-void" />;
        }
        return <div className="bb-confirm-row">
            <span className="bb-confirm-label">{label}</span>
            <span className="bb-confirm-val">{vx}</span>
        </div>;
    }

    # Server/bridge may hand back draft as a plain object or another value; avoid
    # `"key" in d` here — it compiles to JS `in`, which throws if d is not an Object.
    # Jac `None` does not cover JS `undefined`; bracket read on undefined throws (e.g. e[i]).
    def draftField(d: any, key: str) -> str {
        try {
            if d == None {
                return "";
            }
            v = d[key];
            if v == None {
                return "";
            }
            return str(v);
        } except Exception {
            return "";
        }
    }

    def confirmDraftPanel(props: dict) -> JsxElement {
        d = props["d"];
        summaryText = "";
        if "summaryText" in props {
            summaryText = str(props["summaryText"]);
        }
        return <div className="bb-confirm-panel bb-rise-stagger">
            <div className="bb-confirm-panel-head">Review this change</div>
            {( <p className="bb-confirm-lede">{summaryText}</p> ) if summaryText != "" else (None)}
            <div className="bb-confirm-grid">
                {draftPreviewRow({"label": "Title", "val": draftField(d, "title")})}
                {draftPreviewRow({"label": "Task ID", "val": draftField(d, "task_id")})}
                {draftPreviewRow({"label": "Status", "val": draftField(d, "status")})}
                {draftPreviewRow({"label": "Assignee", "val": draftField(d, "assignee_id")})}
                {draftPreviewRow({"label": "Start", "val": draftField(d, "start_date")})}
                {draftPreviewRow({"label": "Due", "val": draftField(d, "due_date")})}
                {draftPreviewRow({"label": "Expected end", "val": draftField(d, "expected_end_date")})}
                {draftPreviewRow({"label": "Description", "val": draftField(d, "description")})}
            </div>
        </div>;
    }

    def complianceChipLabel(key: str) -> str {
        if key == "missing_fields" {
            return "Missing fields";
        }
        if key == "incomplete_completion" {
            return "Incomplete completion";
        }
        if key == "overdue" {
            return "Overdue";
        }
        if key == "blocked" {
            return "Blocked";
        }
        return key;
    }

    def relativeRefreshedAt(iso: str) -> str {
        raw = str(iso).strip();
        if raw == "" {
            return "";
        }
        try {
            ms: any = Date.parse(raw);
            if ms != ms {
                return raw;
            }
            diff = Date.now() - ms;
            if diff < 0 {
                diff = 0;
            }
            mins = Math.floor(diff / 60000);
            if mins < 1 {
                return "just now";
            }
            if mins < 60 {
                return str(mins) + "m ago";
            }
            hrs = Math.floor(mins / 60);
            if hrs < 24 {
                return str(hrs) + "h ago";
            }
            days = Math.floor(hrs / 24);
            if days < 30 {
                return str(days) + "d ago";
            }
            d: any = Reflect.construct(Date, [ms]);
            return d.toLocaleDateString("en-US", {"month": "short", "day": "numeric", "year": "numeric"});
        } except Exception {
            return raw;
        }
    }

    def taskScheduleLine(tab: str, tk: any) -> str {
        sd = "";
        due = "";
        exp = "";
        upd = "";
        if tk {
            if tk.start_date {
                sd = str(tk.start_date);
            }
            if tk.due_date {
                due = str(tk.due_date);
            }
            if tk.expected_end_date {
                exp = str(tk.expected_end_date);
            }
            if tk.updated_at {
                upd = str(tk.updated_at);
            }
        }
        if tab == "planned" {
            if sd != "" {
                return "Starts " + sd;
            }
            if due != "" {
                return "Due " + due;
            }
            return "Schedule TBD";
        }
        if tab == "in-progress" {
            line = "Target end " + (exp if exp != "" else "—");
            if due != "" and due != exp {
                line = line + " · Due " + due;
            }
            return line;
        }
        if tab == "completed" {
            if upd != "" {
                return "Finished " + upd;
            }
            return "Completed";
        }
        if tab == "overdue" {
            if due != "" {
                return "Was due " + due;
            }
            if exp != "" {
                return "Target was " + exp;
            }
            return "Overdue";
        }
        return "";
    }

    def taskTabEmptyMessage(tab: str) -> str {
        if tab == "planned" {
            return "No planned work.";
        }
        if tab == "in-progress" {
            return "Nothing in progress.";
        }
        if tab == "completed" {
            return "No completed tasks yet.";
        }
        if tab == "overdue" {
            return "No overdue tasks in this view.";
        }
        return "No tasks in this view.";
    }

    def:pub beanbot_ui() -> JsxElement {
        has userId: str = "";
        has username: str = "";
        has roleChoice: str = "employee";
        has password: str = "";
        has authMode: str = "signin";
        has isAuthed: bool = False;
        has role: str = "employee";
        has messages: list = [];
        has msgCounter: int = 0;
        has inputText: str = "";
        has tasks: list = [];
        has taskTab: str = "planned";
        has loadingChat: bool = False;
        has mainTab: str = "work";
        has adminMessage: str = "";
        has messagesContainerRef: any = useRef(None);
        has snapshot: dict = {};
        has summaries: list = [];
        has adminBusy: bool = False;
        has apiAuthError: str = "";
        has sessionId: str = "";
        has mentionDirectory: list = [];
        has showMentionPicker: bool = False;
        has mentionQuery: str = "";
        has mentionHighlight: int = 0;
        has messagesEndRef: any = useRef(None);
        has tasksLoading: bool = False;
        has mentionFiltered: list = [];
        has mentionPickUserId: str = "";
        has empStep: int = 1;
        has empTaskTitle: str = "";
        has empTaskDesc: str = "";
        has empTaskStart: str = "";
        has empTaskExpectedEnd: str = "";
        has empTimeEst: str = "";
        has empDeliverable: str = "";
        has empNotebook: str = "";
        has empFormError: str = "";

        async def loadMentionDirectory() -> None {
            if username.strip() == "" or not isAuthed {
                mentionDirectory = [];
                return;
            }
            try {
                result: any = await jacSpawn(
                    "ListMentionableUsers",
                    "",
                    {"username": username.strip()}
                );
                if result.reports and len(result.reports) > 0 {
                    r0 = result.reports[0];
                    if r0.users {
                        mentionDirectory = r0.users;
                    } else {
                        mentionDirectory = [];
                    }
                } else {
                    mentionDirectory = [];
                }
            } except Exception {
                mentionDirectory = [];
            }
        }

        async def loadUser() -> None {
            if username.strip() == "" {
                return;
            }
            result: any = await jacSpawn("GetUser", "", {"username": username.strip()});
            role = "employee";
            if result.reports and len(result.reports) > 0 {
                first = result.reports[0];
                if first.user {
                    role = first.user.role;
                    userId = first.user.id;
                }
            }
            if role != "manager" {
                mainTab = "work";
            }
        }

        async def loadUserByUsername(uname: str) -> dict | None {
            result: any = await jacSpawn("GetUserByUsername", "", {"username": uname});
            if result.reports and len(result.reports) > 0 and result.reports[0].user {
                return result.reports[0].user;
            }
            return None;
        }

        async def loadTasks() -> None {
            if username.strip() == "" {
                tasks = [];
                return;
            }
            tasksLoading = True;
            fb = taskTab;
            if fb == "in-progress" {
                fb = "in_progress";
            }
            try {
                result: any = await jacSpawn(
                    "ListTasks",
                    "",
                    {"username": username.strip(), "filter_by": fb}
                );
                if result.reports and len(result.reports) > 0 {
                    r0 = result.reports[0];
                    if r0.type and str(r0.type) == "error" {
                        tasks = [];
                    } elif r0.tasks {
                        tasks = r0.tasks;
                    } else {
                        tasks = [];
                    }
                } else {
                    tasks = [];
                }
            } except Exception {
                tasks = [];
            }
            tasksLoading = False;
        }

        async def loadSnapshot() -> None {
            if username.strip() == "" {
                return;
            }
            result: any = await jacSpawn(
                "GetSnapshot",
                "",
                {"username": username.strip()}
            );
            if result.reports and len(result.reports) > 0 {
                d = result.reports[0];
                snapshot = d.snapshot;
                if d.summaries {
                    summaries = d.summaries;
                } else {
                    summaries = [];
                }
            }
        }

        async def hydrateChatSession() -> None {
            if username.strip() == "" {
                return;
            }
            try {
                result: any = await jacSpawn(
                    "EnsureChatSession",
                    "",
                    {"username": username.strip(), "session_id": sessionId}
                );
                if result.reports and len(result.reports) > 0 {
                    r0 = result.reports[0];
                    if r0.type and str(r0.type) == "error" {
                        messages = [
                            {
                                "id": 1,
                                "role": "bot",
                                "text": "Could not load chat history.",
                                "type": "reply"
                            }
                        ];
                        msgCounter = 1;
                        return;
                    }
                    if r0.session_id {
                        sessionId = str(r0.session_id);
                    }
                    messages = [];
                    msgCounter = 0;
                    rows = [];
                    if r0.messages {
                        rows = r0.messages;
                    }
                    for row in rows {
                        msgCounter = msgCounter + 1;
                        mt = chatRowStr(row, "message_type", "messageType");
                        if mt == "" {
                            mt = "reply";
                        }
                        tx = chatRowStr(row, "content", "content");
                        rl = chatRowStr(row, "role", "role");
                        if rl == "" {
                            rl = "bot";
                        }
                        msg_entry = {"id": msgCounter, "role": rl, "text": tx, "type": mt};
                        if mt == "manager_nudge" {
                            rawc = chatRowStr(row, "content", "content");
                            nd = parseManagerNudgeContent(rawc);
                            msg_entry["text"] = nd["body"];
                            msg_entry["fetch_id"] = nd["fetch_id"];
                        }
                        messages.append(msg_entry);
                    }
                }
            } except Exception {
                messages = [
                    {
                        "id": 1,
                        "role": "bot",
                        "text": "Could not load chat session.",
                        "type": "reply"
                    }
                ];
                msgCounter = 1;
            }
        }

        def employeeTaskFormComplete() -> bool {
            return (
                empTaskTitle.strip() != ""
                and empTaskDesc.strip() != ""
                and empTaskStart.strip() != ""
                and empTaskExpectedEnd.strip() != ""
                and empTimeEst.strip() != ""
                and empDeliverable.strip() != ""
                and empNotebook.strip() != ""
            );
        }

        async def deliverChatTurn(userLine: str) -> None {
            loadingChat = True;
            result: any = None;
            try {
                result: any = await jacSpawn(
                    "ChatMessage",
                    "",
                    {
                        "message": userLine,
                        "username": username.strip(),
                        "session_id": sessionId
                    }
                );
            } except Exception {
                result: any = None;
            }
            loadingChat = False;
            if not result or not result.reports or len(result.reports) == 0 {
                messages.append(
                    {
                        "id": msgCounter,
                        "role": "bot",
                        "text": "No response from the server. Check your connection and try again.",
                        "type": "reply"
                    }
                );
                msgCounter = msgCounter + 1;
                await loadTasks();
                return;
            }
            bot: any = result.reports[0];
            if bot.type and str(bot.type) == "error" {
                et = "Something went wrong.";
                if bot.text {
                    et = str(bot.text);
                }
                messages.append({"id": msgCounter, "role": "bot", "text": et, "type": "reply"});
                msgCounter = msgCounter + 1;
                await loadTasks();
                return;
            }
            if bot.session_id {
                sessionId = str(bot.session_id);
            }
            mt = "reply";
            if bot.type {
                mt = str(bot.type);
            }
            tx = "";
            if bot.text {
                tx = bot.text;
            }
            if bot.summary {
                tx = bot.summary;
            }
            msg_entry = {"id": msgCounter, "role": "bot", "text": tx, "type": mt};
            if bot.intent {
                msg_entry["intent"] = bot.intent;
            }
            if bot.missing {
                msg_entry["missing"] = bot.missing;
            }
            if bot.draft {
                try {
                    msg_entry["draft"] = JSON.parse(JSON.stringify(bot.draft)) as any;
                } except Exception {
                    msg_entry["draft"] = bot.draft;
                }
            }
            if bot.summary {
                msg_entry["summary"] = str(bot.summary);
            }
            if role == "employee" {
                await hydrateChatSession();
                if bot.type and str(bot.type) == "action_confirm" and bot.draft {
                    ix = len(messages) - 1;
                    while ix >= 0 {
                        rowm: any = messages[ix];
                        if rowm.type == "action_confirm" {
                            patched = JSON.parse(JSON.stringify(rowm));
                            try {
                                patched["draft"] = JSON.parse(JSON.stringify(bot.draft));
                            } except Exception {
                                patched["draft"] = bot.draft;
                            }
                            if bot.summary {
                                patched["summary"] = str(bot.summary);
                            }
                            if bot.intent {
                                patched["intent"] = bot.intent;
                            }
                            messages[ix] = patched;
                            break;
                        }
                        ix = ix - 1;
                    }
                }
            } else {
                messages.append(msg_entry);
                msgCounter = msgCounter + 1;
            }
            await loadTasks();
        }

        async def sendChat() -> None {
            if inputText.strip() == "" {
                return;
            }
            msg = inputText.strip();
            messages.append({"id": msgCounter, "role": "user", "text": msg, "type": "user"});
            msgCounter = msgCounter + 1;
            inputText = "";
            showMentionPicker = False;
            await deliverChatTurn(msg);
        }

        def employeeWizardNext(e: any) -> None {
            empFormError = "";
            if empStep == 1 {
                if empTaskTitle.strip() == "" or empTaskDesc.strip() == "" {
                    empFormError = "Title and description are required.";
                    return;
                }
                empStep = 2;
                return;
            }
            if empStep == 2 {
                if (
                    empTaskStart.strip() == ""
                    or empTaskExpectedEnd.strip() == ""
                    or empTimeEst.strip() == ""
                ) {
                    empFormError = "Start date, target end, and time estimate are required.";
                    return;
                }
                empStep = 3;
            }
        }

        def employeeWizardBack(e: any) -> None {
            empFormError = "";
            if empStep > 1 {
                empStep = empStep - 1;
            }
        }

        async def submitEmployeeWizard(e: any) -> None {
            if role == "manager" {
                return;
            }
            empFormError = "";
            if not employeeTaskFormComplete() {
                empFormError = "Title, description, start date, target end date, time estimate, deliverable, and notebook location are required.";
                return;
            }
            loadingChat = True;
            try {
                result: any = await jacSpawn(
                    "CreateEmployeeTask",
                    "",
                    {
                        "username": username.strip(),
                        "title": empTaskTitle.strip(),
                        "description": empTaskDesc.strip(),
                        "start_date": empTaskStart.strip(),
                        "expected_end_date": empTaskExpectedEnd.strip(),
                        "time_estimate": empTimeEst.strip(),
                        "deliverable_spec": empDeliverable.strip(),
                        "notebook_location": empNotebook.strip(),
                        "session_id": sessionId
                    }
                );
                ok_run = False;
                if result.reports and len(result.reports) > 0 {
                    r0 = result.reports[0];
                    if r0.type and str(r0.type) == "success" {
                        ok_run = True;
                    }
                }
                if ok_run {
                    empTaskTitle = "";
                    empTaskDesc = "";
                    empTaskStart = "";
                    empTaskExpectedEnd = "";
                    empTimeEst = "";
                    empDeliverable = "";
                    empNotebook = "";
                    empStep = 1;
                    await hydrateChatSession();
                    await loadTasks();
                } else {
                    tx_err = "Could not create task.";
                    if result.reports and len(result.reports) > 0 {
                        r1 = result.reports[0];
                        if r1.text {
                            tx_err = str(r1.text);
                        }
                    }
                    empFormError = tx_err;
                }
            } except Exception {
                empFormError = "Could not create task. Try again.";
            }
            loadingChat = False;
        }

        async def onConfirm() -> None {
            loadingChat = True;
            result: any = None;
            try {
                result: any = await jacSpawn(
                    "ChatMessage",
                    "",
                    {
                        "message": "confirm",
                        "username": username.strip(),
                        "session_id": sessionId
                    }
                );
            } except Exception {
                result: any = None;
            }
            loadingChat = False;
            if result and result.reports and len(result.reports) > 0 {
                bot: any = result.reports[0];
                if bot.session_id {
                    sessionId = str(bot.session_id);
                }
                if bot.type and str(bot.type) == "error" {
                    et = "Could not confirm.";
                    if bot.text {
                        et = str(bot.text);
                    }
                    messages.append({"id": msgCounter, "role": "bot", "text": et, "type": "reply"});
                    msgCounter = msgCounter + 1;
                } elif role != "manager" {
                    await hydrateChatSession();
                    if bot.type and str(bot.type) == "success" {
                        empTaskTitle = "";
                        empTaskDesc = "";
                        empTaskStart = "";
                        empTaskExpectedEnd = "";
                        empTimeEst = "";
                        empDeliverable = "";
                        empNotebook = "";
                        empStep = 1;
                    }
                } else {
                    tx = "Done.";
                    if bot.text {
                        tx = bot.text;
                    }
                    mt = "success";
                    if bot.type {
                        mt = bot.type;
                    }
                    messages.append({"id": msgCounter, "role": "bot", "text": tx, "type": mt});
                    msgCounter = msgCounter + 1;
                }
            } else {
                messages.append(
                    {
                        "id": msgCounter,
                        "role": "bot",
                        "text": "Could not confirm. Try again.",
                        "type": "reply"
                    }
                );
                msgCounter = msgCounter + 1;
            }
            await loadTasks();
        }

        async def runRefresh() -> None {
            if role != "manager" {
                return;
            }
            adminBusy = True;
            adminMessage = "Refreshing compliance snapshot…";
            try {
                result: any = await jacSpawn(
                    "RefreshSummary",
                    "",
                    {"username": username.strip()}
                );
                ok = False;
                if result.reports and len(result.reports) > 0 {
                    r0 = result.reports[0];
                    if r0.type and str(r0.type) == "success" {
                        ok = True;
                    }
                }
                if ok {
                    __invalidateEndpoint("walker:GetSnapshot");
                    adminMessage = "Summary rebuilt from latest task data.";
                    await loadSnapshot();
                } else {
                    adminMessage = "Could not refresh summary. Try again.";
                    __invalidateEndpoint("walker:GetSnapshot");
                    await loadSnapshot();
                }
            } except Exception {
                adminMessage = "Could not refresh summary. Check your connection and try again.";
            }
            adminBusy = False;
        }

        async def runAgentFetch() -> None {
            if role != "manager" {
                return;
            }
            adminBusy = True;
            adminMessage = "Creating personalized nudges…";
            try {
                result: any = await jacSpawn(
                    "AgentFetch",
                    "",
                    {"username": username.strip()}
                );
                if result.reports and len(result.reports) > 0 {
                    r0 = result.reports[0];
                    if r0.type and str(r0.type) == "error" {
                        tx = "Could not queue nudges.";
                        if r0.text {
                            tx = str(r0.text);
                        }
                        adminMessage = tx;
                    } else {
                        n = 0;
                        if r0.fetches {
                            n = len(r0.fetches);
                        }
                        if n > 0 {
                            adminMessage = "Queued " + str(n) + " nudge(s) for team members.";
                        } else {
                            adminMessage = "No nudges queued — no overdue or incomplete tasks matched any employee.";
                        }
                    }
                } else {
                    adminMessage = "Could not queue nudges. Try again in a moment.";
                }
            } except Exception {
                adminMessage = "Could not queue nudges. Try again in a moment.";
            }
            adminBusy = False;
        }

        async def ackFetchRequest(reqId: str) -> None {
            await jacSpawn(
                "AckFetchRequest",
                "",
                {"request_id": reqId, "username": username.strip()}
            );
            await hydrateChatSession();
        }

        async def createAppAccount(uname: str, selectedRole: str) -> dict {
            result: any = await jacSpawn(
                "EnsureUserAccount",
                "",
                {"username": uname, "role": selectedRole, "display_name": uname}
            );
            if result.reports and len(result.reports) > 0 {
                return result.reports[0];
            }
            return {"ok": False, "error": "Could not create user profile."};
        }

        async def signInOrCreate() -> None {
            apiAuthError = "";
            if username.strip() == "" or password.strip() == "" {
                apiAuthError = "Enter username and password.";
                return;
            }

            if authMode == "signup" {
                su: any = await jacSignup(username.strip(), password);
                if not su.success {
                    if su.error and su.error.message {
                        apiAuthError = str(su.error.message);
                    } elif su.error {
                        apiAuthError = str(su.error);
                    } else {
                        apiAuthError = "Could not create login.";
                    }
                    return;
                }
                created: any = await createAppAccount(username.strip(), roleChoice);
                if not created.ok {
                    if created.error and created.error.message {
                        apiAuthError = str(created.error.message);
                    } elif created.error {
                        apiAuthError = str(created.error);
                    } else {
                        apiAuthError = "Could not create app profile.";
                    }
                    return;
                }
                userId = created.user.id;
                role = created.user.role;
                isAuthed = True;
                apiAuthError = "";
                mainTab = "work";
                await loadTasks();
                await hydrateChatSession();
                if role == "manager" {
                    await loadSnapshot();
                    (runRefresh() as any).catch(lambda (e: any) {});
                } else {
                    snapshot = {};
                    summaries = [];
                }
                await loadMentionDirectory();
                return;
            }

            ok: any = await jacLogin(username.strip(), password);
            if not ok {
                apiAuthError = "Invalid username or password.";
                return;
            }
            u: any = await loadUserByUsername(username.strip());
            if not u {
                created2: any = await createAppAccount(username.strip(), "employee");
                if not created2.ok {
                    if created2.error and created2.error.message {
                        apiAuthError = str(created2.error.message);
                    } elif created2.error {
                        apiAuthError = str(created2.error);
                    } else {
                        apiAuthError = "Could not create app profile.";
                    }
                    return;
                }
                u: any = created2.user;
            }
            userId = u.id;
            role = u.role;
            isAuthed = True;
            apiAuthError = "";
            mainTab = "work";
            await loadTasks();
            await hydrateChatSession();
            if role == "manager" {
                await loadSnapshot();
                (runRefresh() as any).catch(lambda (e: any) {});
            } else {
                snapshot = {};
                summaries = [];
            }
            await loadMentionDirectory();
        }

        async def signOut() -> None {
            jacLogout();
            isAuthed = False;
            userId = "";
            username = "";
            role = "employee";
            mainTab = "work";
            tasks = [];
            summaries = [];
            snapshot = {};
            messages = [];
            inputText = "";
            password = "";
            sessionId = "";
            mentionDirectory = [];
            showMentionPicker = False;
            empTaskTitle = "";
            empTaskDesc = "";
            empTaskStart = "";
            empTaskExpectedEnd = "";
            empTimeEst = "";
            empDeliverable = "";
            empNotebook = "";
            empStep = 1;
            empFormError = "";
        }

        useEffect(lambda -> None {
            if isAuthed {
                (loadTasks() as any).catch(lambda (e: any) {});
            }
        }, [taskTab]);

        useEffect(lambda -> None {
            if isAuthed and username.strip() != "" {
                (loadMentionDirectory() as any).catch(lambda (e: any) {});
            }
        }, [isAuthed, username]);

        useEffect(lambda () {
            if not isAuthed or role == "manager" or username.strip() == "" {
                return;
            }
            (hydrateChatSession() as any).catch(lambda (e: any) {});
            tid = globalThis.setInterval(
                lambda () {
                    (hydrateChatSession() as any).catch(lambda (e: any) {});
                },
                45000
            );
            return lambda () { globalThis.clearInterval(tid); };
        }, [isAuthed, role, username]);

        useEffect(lambda -> None {
            c = messagesContainerRef.current;
            if c {
                c.scrollTop = c.scrollHeight;
            }
        }, [messages, loadingChat]);

        async def handleAdminTab(e: any) -> None {
            mainTab = "admin";
            adminMessage = "";
            __invalidateEndpoint("walker:GetSnapshot");
            await loadSnapshot();
        }

        def handleWorkTab(e: any) -> None {
            mainTab = "work";
        }

        async def handleSignInClick(e: any) -> None {
            await signInOrCreate();
        }

        async def handleSendClick(e: any) -> None {
            await sendChat();
        }

        async def handleConfirmClick(e: any) -> None {
            await onConfirm();
        }

        def onChatInputChange(e: any) -> None {
            v = e.target.value;
            inputText = v;
            tv = str(v);
            showMentionPicker = False;
            mentionQuery = "";
            mentionHighlight = 0;
            mentionFiltered = [];
            mentionPickUserId = "";
            li = tv.rfind("@");
            if li >= 0 {
                after = tv[li + 1:];
                if after.find(" ") < 0 and after.find("\n") < 0 {
                    mentionQuery = after.lower();
                    showMentionPicker = True;
                    mq2 = mentionQuery;
                    for u3 in mentionDirectory {
                        un3 = str(u3["username"]).lower();
                        nm3 = str(u3["name"]).lower();
                        if mq2 == "" or un3.find(mq2) == 0 or nm3.find(mq2) >= 0 {
                            mentionFiltered.append(u3);
                        }
                    }
                    if len(mentionFiltered) == 0 {
                        showMentionPicker = False;
                    } else {
                        mentionPickUserId = str(mentionFiltered[0]["id"]);
                    }
                }
            }
        }

        def insertMentionPick(uname: str) -> None {
            tv = inputText;
            li = tv.rfind("@");
            if li >= 0 {
                inputText = tv[:li] + "@" + uname + " ";
            }
            showMentionPicker = False;
            mentionQuery = "";
            mentionHighlight = 0;
            mentionFiltered = [];
            mentionPickUserId = "";
        }

        def onChatKeyDown(e: any) -> None {
            if not showMentionPicker {
                return;
            }
            filt = mentionFiltered;
            key = str(e.key);
            if key == "Escape" {
                showMentionPicker = False;
                mentionFiltered = [];
                mentionPickUserId = "";
                e.preventDefault();
                return;
            }
            if key == "ArrowDown" {
                if len(filt) > 0 {
                    cur = 0;
                    i = 0;
                    while i < len(filt) {
                        if str(filt[i]["id"]) == mentionPickUserId {
                            cur = i;
                            break;
                        }
                        i = i + 1;
                    }
                    nxt = (cur + 1) % len(filt);
                    mentionPickUserId = str(filt[nxt]["id"]);
                }
                e.preventDefault();
                return;
            }
            if key == "ArrowUp" {
                if len(filt) > 0 {
                    cur = 0;
                    i = 0;
                    while i < len(filt) {
                        if str(filt[i]["id"]) == mentionPickUserId {
                            cur = i;
                            break;
                        }
                        i = i + 1;
                    }
                    prv = (cur - 1 + len(filt)) % len(filt);
                    mentionPickUserId = str(filt[prv]["id"]);
                }
                e.preventDefault();
                return;
            }
            if key == "Enter" and len(filt) > 0 {
                pickU = "";
                j = 0;
                while j < len(filt) {
                    if str(filt[j]["id"]) == mentionPickUserId {
                        pickU = str(filt[j]["username"]);
                        break;
                    }
                    j = j + 1;
                }
                if pickU != "" {
                    insertMentionPick(pickU);
                }
                e.preventDefault();
            }
        }

        async def handleSignOutClick(e: any) -> None {
            signOut();
        }

        async def handleRefreshClick(e: any) -> None {
            await runRefresh();
        }

        async def handleAgentFetchClick(e: any) -> None {
            await runAgentFetch();
        }

        return <div className="beanbot-app">
            {( <p className="bb-error">{apiAuthError}</p> ) if apiAuthError != "" else (None)}
            {( <section className="bb-admin bb-auth">
                    <h2>{("Create account") if authMode == "signup" else ("Sign in")}</h2>
                    <p className="bb-meta">{("Enter username, password, and role.") if authMode == "signup" else ("Enter username and password.")}</p>
                    <div className="bb-input-row">
                        <input
                            value={username}
                            placeholder="Username"
                            onChange={lambda (e: any) { username = e.target.value; }}
                        />
                        <input
                            type="password"
                            value={password}
                            placeholder="Password"
                            onChange={lambda (e: any) { password = e.target.value; }}
                        />
                    </div>
                    <div className="bb-userbar">
                        {( <span>
                            <label>Role</label>
                            <select
                                value={roleChoice}
                                onChange={lambda (e: any) { roleChoice = e.target.value; }}
                            >
                                <option value="employee">Employee</option>
                                <option value="manager">Manager</option>
                            </select>
                        </span> ) if authMode == "signup" else (None)}
                        <button type="button" onClick={handleSignInClick}>
                            {("Create account") if authMode == "signup" else ("Sign in")}
                        </button>
                        <button type="button" onClick={lambda (e: any) {
                            authMode = ("signin") if authMode == "signup" else ("signup");
                            apiAuthError = "";
                        }}>
                            {("Have an account? Sign in") if authMode == "signup" else ("Need an account? Create")}
                        </button>
                    </div>
                </section> ) if not isAuthed else (None)}
            {(None) if not isAuthed else (
            <header className="bb-header">
                <div className="bb-header-brand">
                    <h1>BeanBot</h1>
                    {( <p className="bb-header-tagline">Tasks · chat · manager hub</p> ) if role == "manager" else (None)}
                </div>
                <div className="bb-userbar">
                    {( <nav className="bb-manager-nav" aria-label="Manager areas">
                        <button
                            type="button"
                            className={( "active" ) if mainTab == "work" else ( "" )}
                            onClick={handleWorkTab}
                        >
                            Workspace
                        </button>
                        <button
                            type="button"
                            className={( "active" ) if mainTab == "admin" else ( "" )}
                            onClick={handleAdminTab}
                        >
                            Manager hub
                        </button>
                    </nav> ) if role == "manager" else (None)}
                    <label className="bb-user-pill">{username} ({role})</label>
                    <button type="button" onClick={handleSignOutClick}>Sign out</button>
                </div>
            </header>
            )}
            {( <section className="bb-admin">
                    <h2>Manager hub</h2>
                    <p className="bb-admin-lede">
                        Refresh a compliance snapshot across the lab, or queue short nudges when tasks are overdue or incomplete.
                    </p>
                    {( <p className="bb-admin-status" role="status">{adminMessage}</p> ) if adminMessage != "" else (None)}
                    <div className="bb-admin-actions">
                        {adminButton({"onClick": handleRefreshClick, "label": "Refresh summary", "disabled": adminBusy})}
                        {adminButton({"onClick": handleAgentFetchClick, "label": "Agent fetch", "disabled": adminBusy})}
                    </div>
                    {( <p className="bb-meta" title={str(snapshot["generated_at"])}>{("Last refreshed: " + relativeRefreshedAt(str(snapshot["generated_at"])))}</p> ) if (snapshot and snapshot["generated_at"]) else ( <p className="bb-meta">No snapshot yet — run Refresh summary.</p> )}
                    <ul className="bb-summaries">
                        {[
                            <li key={str(s.employee_id)}>
                                <strong>{s.employee_name}</strong>
                                <pre>{s.narrative}</pre>
                            </li>
                            for s in summaries
                        ]}
                    </ul>
                </section> ) if (isAuthed and role == "manager" and mainTab == "admin") else (None)}
            {( <div className="bb-main">
                <section className="bb-chat">
                    <div className="bb-chat-head">
                        <h2>Chat</h2>
                    </div>
                    {( <div className="bb-employee-task-form bb-emp-wizard" aria-labelledby="bb-emp-form-title">
                        <h3 id="bb-emp-form-title" className="bb-emp-form-title">New task</h3>
                        <p className="bb-emp-form-lede">
                            Three quick steps so every required field is captured before you add the task.
                        </p>
                        <ol className="bb-emp-stepper" aria-label="Form progress">
                            <li className={("bb-emp-stepper-item bb-emp-stepper-item--active") if empStep == 1 else ("bb-emp-stepper-item bb-emp-stepper-item--done") if empStep > 1 else ("bb-emp-stepper-item")}>
                                <span className="bb-emp-stepper-num">1</span>
                                <span className="bb-emp-stepper-label">Basics</span>
                            </li>
                            <li className={("bb-emp-stepper-item bb-emp-stepper-item--active") if empStep == 2 else ("bb-emp-stepper-item bb-emp-stepper-item--done") if empStep > 2 else ("bb-emp-stepper-item")}>
                                <span className="bb-emp-stepper-num">2</span>
                                <span className="bb-emp-stepper-label">Schedule</span>
                            </li>
                            <li className={("bb-emp-stepper-item bb-emp-stepper-item--active") if empStep == 3 else ("bb-emp-stepper-item")}>
                                <span className="bb-emp-stepper-num">3</span>
                                <span className="bb-emp-stepper-label">Lab record</span>
                            </li>
                        </ol>
                        {( <div className="bb-emp-form-grid">
                            <label className="bb-emp-field bb-emp-field--full">
                                <span className="bb-emp-label">Title</span>
                                <input
                                    type="text"
                                    value={empTaskTitle}
                                    placeholder="Short name for the work"
                                    aria-label="Task title"
                                    required={True}
                                    onChange={lambda (e: any) { empTaskTitle = e.target.value; }}
                                />
                            </label>
                            <label className="bb-emp-field bb-emp-field--full">
                                <span className="bb-emp-label">Description</span>
                                <textarea
                                    value={empTaskDesc}
                                    rows={3}
                                    placeholder="What you will do and any context teammates need"
                                    aria-label="Task description"
                                    required={True}
                                    onChange={lambda (e: any) { empTaskDesc = e.target.value; }}
                                />
                            </label>
                        </div> ) if empStep == 1 else (None)}
                        {( <div className="bb-emp-form-grid">
                            <label className="bb-emp-field">
                                <span className="bb-emp-label">Start date</span>
                                <input
                                    type="text"
                                    value={empTaskStart}
                                    placeholder="YYYY-MM-DD"
                                    aria-label="Start date"
                                    required={True}
                                    onChange={lambda (e: any) { empTaskStart = e.target.value; }}
                                />
                            </label>
                            <label className="bb-emp-field">
                                <span className="bb-emp-label">Target end date</span>
                                <input
                                    type="text"
                                    value={empTaskExpectedEnd}
                                    placeholder="YYYY-MM-DD"
                                    aria-label="Expected end date"
                                    required={True}
                                    onChange={lambda (e: any) { empTaskExpectedEnd = e.target.value; }}
                                />
                            </label>
                            <label className="bb-emp-field bb-emp-field--full">
                                <span className="bb-emp-label">Time estimate</span>
                                <input
                                    type="text"
                                    value={empTimeEst}
                                    placeholder="e.g. 2d, 8h, or one line"
                                    aria-label="Time estimate"
                                    required={True}
                                    onChange={lambda (e: any) { empTimeEst = e.target.value; }}
                                />
                            </label>
                        </div> ) if empStep == 2 else (None)}
                        {( <div className="bb-emp-form-grid">
                            <label className="bb-emp-field bb-emp-field--full">
                                <span className="bb-emp-label">Deliverable (one line)</span>
                                <input
                                    type="text"
                                    value={empDeliverable}
                                    placeholder="What you will hand off or produce"
                                    aria-label="Deliverable summary"
                                    required={True}
                                    onChange={lambda (e: any) { empDeliverable = e.target.value; }}
                                />
                            </label>
                            <label className="bb-emp-field bb-emp-field--full">
                                <span className="bb-emp-label">Notebook / doc location</span>
                                <input
                                    type="text"
                                    value={empNotebook}
                                    placeholder="Path, URL, or notebook id"
                                    aria-label="Notebook location"
                                    required={True}
                                    onChange={lambda (e: any) { empNotebook = e.target.value; }}
                                />
                            </label>
                        </div> ) if empStep == 3 else (None)}
                        {( <p className="bb-emp-form-error" role="alert">{empFormError}</p> ) if empFormError != "" else (None)}
                        <div className="bb-emp-wizard-actions">
                            {( <button type="button" className="bb-btn-secondary" onClick={employeeWizardBack}>
                                Back
                            </button> ) if empStep > 1 else ( <span className="bb-emp-wizard-spacer" aria-hidden="true" /> )}
                            <div className="bb-emp-wizard-actions-right">
                                {( <button
                                    type="button"
                                    className="bb-emp-add-task"
                                    onClick={employeeWizardNext}
                                    disabled={( True ) if (empTaskTitle.strip() == "" or empTaskDesc.strip() == "") else ( False )}
                                >
                                    Next
                                </button> ) if empStep == 1 else (None)}
                                {( <button
                                    type="button"
                                    className="bb-emp-add-task"
                                    onClick={employeeWizardNext}
                                    disabled={( True ) if (empTaskStart.strip() == "" or empTaskExpectedEnd.strip() == "" or empTimeEst.strip() == "") else ( False )}
                                >
                                    Next
                                </button> ) if empStep == 2 else (None)}
                                {( <button
                                    type="button"
                                    className="bb-emp-add-task"
                                    onClick={submitEmployeeWizard}
                                    disabled={( True ) if (loadingChat or (not employeeTaskFormComplete())) else ( False )}
                                >
                                    Add task
                                </button> ) if empStep == 3 else (None)}
                            </div>
                        </div>
                    </div> ) if role != "manager" else (None)}
                    <div className="bb-messages" ref={messagesContainerRef}>
                        {[
                            <div key={str(m.id)} className={msgClass(m.type)}>
                                {( <span className="bb-msg-role">From your manager</span> ) if m.type == "manager_nudge" else ( <span className="bb-msg-role">{msgRoleLabel(m.role)}</span> )}
                                {( confirmDraftPanel({"d": m.draft, "summaryText": (m.summary if m.summary else m.text)}) ) if (m.type == "action_confirm" and m.draft) else (None)}
                                {( <div className="bb-nudge-chat">
                                    <pre className="bb-nudge-chat-body">{m.text}</pre>
                                    <p className="bb-nudge-chat-hint">
                                        Reply below with updates, blockers, or revised dates. Use chat for ongoing status.
                                    </p>
                                    <div className="bb-nudge-chat-actions">
                                        {( <button
                                            type="button"
                                            className="bb-nudge-dismiss"
                                            disabled={( True ) if loadingChat else ( False )}
                                            onClick={lambda (e: any) {
                                                (ackFetchRequest(str(m["fetch_id"])) as any).catch(lambda (err: any) {});
                                            }}
                                        >
                                            Acknowledge
                                        </button> ) if (m.fetch_id and str(m.fetch_id) != "") else (None)}
                                        <button
                                            type="button"
                                            className="bb-nudge-template"
                                            onClick={lambda (e: any) {
                                                inputText = "Here is my update on the tasks you flagged: ";
                                            }}
                                        >
                                            Prefill reply
                                        </button>
                                    </div>
                                </div> ) if m.type == "manager_nudge" else (
                                    <p className="bb-msg-body">{m.text}</p>
                                )}
                                {( <div className="bb-confirm-bar">
                                    <button type="button" className="bb-confirm" onClick={handleConfirmClick}>
                                        Confirm and save
                                    </button>
                                    <span className="bb-confirm-hint">Or type changes in the box below instead.</span>
                                </div> ) if m.type == "action_confirm" else (None)}
                            </div>
                            for m in messages
                        ]}
                        <div className="bb-messages-end" ref={messagesEndRef} aria-hidden="true" />
                    </div>
                    {( <p className="bb-loading">Thinking…</p> ) if loadingChat else (None)}
                    {( <p className="bb-chat-hint">Use chat for updates, comments, or status questions. Type <strong>@</strong> to mention someone.</p> ) if role != "manager" else ( <p className="bb-chat-hint">Type <strong>@</strong> to mention someone from the team directory.</p> )}
                    <div className="bb-composer-wrap">
                        {( <ul className="bb-mention-picker" role="listbox" aria-label="Mention teammate">
                            {[
                                <li
                                    key={str(mu["id"])}
                                    role="option"
                                    aria-selected={( True ) if str(mu["id"]) == mentionPickUserId else ( False )}
                                    className={( "bb-mention-item-active" ) if str(mu["id"]) == mentionPickUserId else ( "bb-mention-item" )}
                                    onMouseEnter={lambda (e: any) { mentionPickUserId = str(mu["id"]); }}
                                    onClick={lambda (e: any) { insertMentionPick(str(mu["username"])); }}
                                >
                                    <span className="bb-mention-name">{mu["name"]}</span>
                                    <span className="bb-mention-user">@{mu["username"]}</span>
                                </li>
                                for mu in mentionFiltered
                            ]}
                        </ul> ) if (showMentionPicker and len(mentionFiltered) > 0) else (None)}
                        <div className="bb-input-row bb-input-row--chat">
                        <textarea
                            value={inputText}
                            onChange={onChatInputChange}
                            onKeyDown={onChatKeyDown}
                            rows={3}
                            placeholder={("Ask about a task, add a comment, or request an update…") if role != "manager" else ("Message the lab assistant…")}
                            aria-label="Chat message"
                        />
                        <button type="button" onClick={handleSendClick}>
                            Send
                        </button>
                        </div>
                    </div>
                </section>
                <section className="bb-tasks">
                    <h2>Tasks</h2>
                    <div className="bb-tabs">
                        {[
                            <button
                                key={t}
                                type="button"
                                className={( "active" ) if taskTab == t else ( "" )}
                                onClick={lambda (e: any) { taskTab = t; }}
                            >
                                {t}
                            </button>
                            for t in ["planned", "in-progress", "completed", "overdue"]
                        ]}
                    </div>
                    {( <p className="bb-task-loading" role="status">Loading tasks…</p> ) if tasksLoading else (None)}
                    {( <p className="bb-task-empty">{taskTabEmptyMessage(taskTab)}</p> ) if (not tasksLoading and len(tasks) == 0) else (None)}
                    <ul className="bb-task-list">
                        {[
                            <li className="bb-task-card" key={str(tk.id)}>
                                <div className="bb-task-card-top">
                                    <h3 className="bb-task-title">{tk.title}</h3>
                                    <span className="bb-task-status">{tk.status}</span>
                                </div>
                                {( <p className="bb-task-assignee">{str(tk.assignee_name)} · @{str(tk.assignee_username)}</p> ) if (role == "manager" and tk.assignee_name) else (None)}
                                {( <p className="bb-task-project">{str(tk.project_name)}</p> ) if (role == "manager" and tk.project_name) else (None)}
                                <p className="bb-task-schedule">{taskScheduleLine(taskTab, tk)}</p>
                                {( <span className="bb-task-est">Est. {str(tk.time_estimate)}</span> ) if tk.time_estimate else (None)}
                                {( <div className="bb-task-chips">
                                    {[
                                        <span key={str(c)} className={"bb-task-chip bb-task-chip--" + str(c).replace("_", "-")}>{complianceChipLabel(str(c))}</span>
                                        for c in tk.compliance_flags
                                    ]}
                                </div> ) if tk.compliance_flags else (None)}
                                <p className="bb-task-id-muted" title="Task id">{str(tk.id)}</p>
                            </li>
                            for tk in tasks
                        ]}
                    </ul>
                </section>
            </div> ) if (isAuthed and (role != "manager" or mainTab == "work")) else (None)}
        </div>;
    }
