"""Jac-authored browser shell runtime for the Electron renderer."""

"""R: Boot the browser shell behavior against the rendered Jac DOM.
M: Queries shell nodes, wires browser controls, and drives webview tabs through the Electron bridge.
E: Missing bridge methods degrade gracefully and leave a static shell instead of crashing.
"""
def:pub bootstrapBrowserShell() -> any {
    shellRoot = document.querySelector(".app-shell");
    if not shellRoot {
        return lambda {};
    }
    if shellRoot.getAttribute("data-jac-booted") == "true" {  # jac:ignore[E1030]
        return lambda {};
    }
    shellRoot.setAttribute("data-jac-booted", "true");  # jac:ignore[E1030]

    DEFAULT_URL = "https://www.google.com";
    SEARCH_URL = "https://www.google.com/search?q=";

    state = {
        "viewport": document.getElementById("viewport"),
        "helpersPage": document.getElementById("helpersPage"),
        "shellContent": document.getElementById("shellContent"),
        "tabList": document.getElementById("tabList"),
        "newTabBtn": document.getElementById("newTabBtn"),
        "navForm": document.getElementById("navForm"),
        "addressInput": document.getElementById("addressInput"),
        "homeBtn": document.getElementById("homeBtn"),
        "backBtn": document.getElementById("backBtn"),
        "forwardBtn": document.getElementById("forwardBtn"),
        "reloadBtn": document.getElementById("reloadBtn"),
        "showBrowserViewBtn": document.getElementById("showBrowserViewBtn"),
        "showHelpersViewBtn": document.getElementById("showHelpersViewBtn"),
        "siteBadge": document.getElementById("siteBadge"),
        "progressBar": document.getElementById("progressBar"),
        "minBtn": document.getElementById("minBtn"),
        "maxBtn": document.getElementById("maxBtn"),
        "closeBtn": document.getElementById("closeBtn"),
        "goBtn": document.getElementById("goBtn"),
        "toggleLayersBtn": document.getElementById("toggleLayersBtn"),
        "tasksPanelOpenHelpersBtn": document.getElementById("tasksPanelOpenHelpersBtn"),
        "tasksCreateTabBtn": document.getElementById("tasksCreateTabBtn"),
        "tasksRunTabBtn": document.getElementById("tasksRunTabBtn"),
        "tasksCreatePanel": document.getElementById("tasksCreatePanel"),
        "tasksRunPanel": document.getElementById("tasksRunPanel"),
        "taskCreateRecordingState": document.getElementById("taskCreateRecordingState"),
        "taskCreateSessionMeta": document.getElementById("taskCreateSessionMeta"),
        "taskPanelRecordBtn": document.getElementById("taskPanelRecordBtn"),
        "taskCreateContextPanel": document.getElementById("taskCreateContextPanel"),
        "taskCreateContextInput": document.getElementById("taskCreateContextInput"),
        "taskPanelGenerateBtn": document.getElementById("taskPanelGenerateBtn"),
        "taskRunSelectedName": document.getElementById("taskRunSelectedName"),
        "taskRunSelectedMeta": document.getElementById("taskRunSelectedMeta"),
        "taskRunSelectedGoal": document.getElementById("taskRunSelectedGoal"),
        "taskRunOverrideInput": document.getElementById("taskRunOverrideInput"),
        "taskPanelRunBtn": document.getElementById("taskPanelRunBtn"),
        "taskPanelRunClearBtn": document.getElementById("taskPanelRunClearBtn"),
        "startTraceBtn": document.getElementById("startTraceBtn"),
        "stopTraceBtn": document.getElementById("stopTraceBtn"),
        "compileTraceBtn": document.getElementById("compileTraceBtn"),
        "planWorkflowBtn": document.getElementById("planWorkflowBtn"),
        "sessionIdLabel": document.getElementById("sessionIdLabel"),
        "workflowIdLabel": document.getElementById("workflowIdLabel"),
        "llmRuntimeLabel": document.getElementById("llmRuntimeLabel"),
        "workflowExplanationPanel": document.getElementById("workflowExplanationPanel"),
        "workflowExplanationInput": document.getElementById("workflowExplanationInput"),
        "layerLog": document.getElementById("layerLog"),
        "layerPanel": document.getElementById("layerPanel"),
        "clawTranscript": document.getElementById("clawTranscript"),
        "clawDraftInput": document.getElementById("clawDraftInput"),
        "clawPlanBtn": document.getElementById("clawPlanBtn"),
        "clawSaveDraftBtn": document.getElementById("clawSaveDraftBtn"),
        "clawStatus": document.getElementById("clawStatus"),
        "createHelperBtn": document.getElementById("createHelperBtn"),
        "helperList": document.getElementById("helperList"),
        "helperBuilderPanel": document.getElementById("helperBuilderPanel"),
        "helperNameInput": document.getElementById("helperNameInput"),
        "helperGoalInput": document.getElementById("helperGoalInput"),
        "helperFrequencySelect": document.getElementById("helperFrequencySelect"),
        "helperCreateBtn": document.getElementById("helperCreateBtn"),
        "helperCancelBtn": document.getElementById("helperCancelBtn"),
        "helpersPageCreateBtn": document.getElementById("helpersPageCreateBtn"),
        "helpersPageList": document.getElementById("helpersPageList"),
        "helpersPageDetail": document.getElementById("helpersPageDetail"),
        "helpersPageResults": document.getElementById("helpersPageResults"),
        "progressInterval": None,
        "progressGuardTimeout": None,
        "activeSessionId": "",
        "activeWorkflowId": "",
        "traceLifecycleState": "idle",
        "workflowExplanationDraft": "",
        "clawDraft": "",
        "clawTranscriptMessages": [],
        "clawIsPlanning": False,
        "clawStatusText": "",
        "clawLastPlanResult": None,
        "clawLastSavedMessage": "",
        "activeShellView": "browser",
        "tasksPanelOpen": True,
        "activeTaskPanelTab": "create",
        "taskRecordingActive": False,
        "recordedTaskSessionId": "",
        "recordedTaskEventCount": 0,
        "taskCreateContextText": "",
        "taskCreateIsGenerating": False,
        "helperBuilderOpen": False,
        "helperDraftName": "",
        "helperDraftGoal": "",
        "helperDraftFrequency": "once",
        "selectedHelperId": "",
        "selectedTaskRunHelperId": "",
        "taskRunOverrideText": "",
        "helperEditMode": False,
        "helperEditGoalDraft": "",
        "helpers": [],
        "helperResults": [],
        "helperSeed": 0,
        "helperResultSeed": 0,
        "webviewPreloadUrl": "",
        "homeUrlCache": "",
        "homeUrlPromise": None,
        "tabSeed": 0,
        "chromeSyncFrame": None,
        "renderedActiveTabId": "",
        "tabs": [],
        "activeTabId": ""
    };

    if not state["viewport"] or not state["tabList"] or not state["navForm"] {
        return lambda {};
    }

    def browserAPI() -> any {
        return window["browserAPI"];
    }

    def objectValue(record: any, key: any, fallback: any = None) -> any {
        if not record or typeof(record) != "object" {
            return fallback;
        }
        value = record[key];
        if typeof(value) == "undefined" or value == None {
            return fallback;
        }
        return value;
    }

    def copyObservationSections(source: any, target: any) -> None {
        optionalKeys = [
            "viewport",
            "dom_snapshot",
            "session_state",
            "semantic",
            "network",
            "screenshot"
        ];
        for key in optionalKeys {
            if source and typeof(source) == "object" and key in source {
                target[key] = source[key];
            }
        }
    }

    async def captureObservationScreenshot(webview: any, trigger: any) -> any {
        if not webview or not webview.capturePage {
            return {};
        }

        try {
            image = await webview.capturePage();
            if not image {
                return {};
            }

            resized = image;
            size = image.getSize() if image.getSize else {"width": 0, "height": 0};
            width = Number(size.width or 0);  # jac:ignore[E1099]
            if width > 420 and image.resize {
                resized = image.resize({"width": 420});
            }

            finalSize = resized.getSize() if resized.getSize else {"width": 0, "height": 0};
            return {
                "mime": "image/png",
                "trigger": str(trigger or ""),
                "width": Number(finalSize.width or 0),  # jac:ignore[E1099]
                "height": Number(finalSize.height or 0),  # jac:ignore[E1099]
                "data_url": str(resized.toDataURL() or "")
            };
        } except Exception as err {
            return {
                "trigger": str(trigger or ""),
                "capture_error": str(err.message or err)  # jac:ignore[E1030]
            };
        }
    }

    async def forwardObservationPayload(tab: any, rawPayload: any) -> None {
        if not rawPayload or typeof(rawPayload) != "object" {
            return;
        }

        webview = tab["webview"];
        meta = rawPayload["meta"] or {};
        if not objectValue(meta, "source", "") {
            meta["source"] = "page";
        }
        meta["tab_id"] = tab["id"];

        forwardPayload = {
            "type": rawPayload["type"] or "unknown",
            "url": rawPayload["url"] or webview.getURL() or tab["url"] or "",
            "target": rawPayload["target"] or {},
            "value": rawPayload["value"] if "value" in rawPayload else "",
            "meta": meta
        };
        copyObservationSections(rawPayload, forwardPayload);

        if bool(objectValue(rawPayload, "capture_screenshot", False)) {
            screenshot = await captureObservationScreenshot(webview, rawPayload["type"] or "unknown");
            if screenshot and typeof(screenshot) == "object" and Object.keys(screenshot).length > 0 {  # jac:ignore[E1030]
                forwardPayload["screenshot"] = screenshot;
            }
        }

        recordObservationEvent(forwardPayload);
    }

    def setProgress(value: any) -> None {
        clamped = value;
        if clamped < 0 {
            clamped = 0;
        }
        if clamped > 100 {
            clamped = 100;
        }
        if state["progressBar"] {
            state["progressBar"].style.width = str(clamped) + "%";  # jac:ignore[E1099]
        }
    }

    def finishProgress() -> None {
        if state["progressInterval"] {
            clearInterval(state["progressInterval"]);  # jac:ignore[E1053]
            state["progressInterval"] = None;
        }
        if state["progressGuardTimeout"] {
            clearTimeout(state["progressGuardTimeout"]);  # jac:ignore[E1053]
            state["progressGuardTimeout"] = None;
        }
        setProgress(100);
        setTimeout(lambda { setProgress(0); }, 220);
    }

    def startProgress() -> None {
        if state["progressInterval"] {
            return;
        }

        setProgress(8);
        state["progressInterval"] = setInterval(lambda {  # jac:ignore[E1001]
            current = 0;
            if state["progressBar"] and state["progressBar"].style.width {  # jac:ignore[E1099]
                current = Number.parseFloat(state["progressBar"].style.width);  # jac:ignore[E1001,E1053,E1099]
            }
            if current < 85 {
                setProgress(current + 6);
            }
        }, 120);

        if state["progressGuardTimeout"] {
            clearTimeout(state["progressGuardTimeout"]);  # jac:ignore[E1053]
        }
        state["progressGuardTimeout"] = setTimeout(lambda { finishProgress(); }, 15000);
    }

    def appendLayerLog(message: any) -> None {
        if not state["layerLog"] {
            return;
        }
        stamp = Reflect.construct(Date, []).toLocaleTimeString();
        nextText = "[" + stamp + "] " + str(message) + "\n" + str(state["layerLog"].textContent or "");  # jac:ignore[E1055,E1099]
        state["layerLog"].textContent = nextText.slice(0, 7000);  # jac:ignore[E1099]
    }

    """R: Surface helper refresh progress and failures in renderer-visible places without requiring a full UI sync.
    M: Writes to the layer log first, optionally mirrors to the Claw transcript, and updates the status text node directly when present.
    E: Missing status or transcript DOM is ignored so refresh diagnostics still show up in whichever panel is available.
    """;
    def reportHelpersRefresh(message: any, role: any = "system", includeTranscript: bool = False) -> None {
        final_message = trimmedText(message);
        if not final_message {
            return;
        }

        appendLayerLog(final_message);
        if includeTranscript {
            appendClawTranscript(role, final_message);
        }

        state["clawStatusText"] = final_message;
        if state["clawStatus"] {
            state["clawStatus"].textContent = final_message;  # jac:ignore[E1099]
        }
    }

    def trimmedText(rawValue: any) -> str {
        return str(rawValue or "").trim();  # jac:ignore[E1002,E1030]
    }

    def commaList(values: any) -> str {
        if not values or len(values) == 0 {
            return "none";
        }

        joined = "";
        for value in values {
            if joined {
                joined = joined + ", ";
            }
            joined = joined + str(value);
        }
        return joined or "none";
    }

    def hasClawDraft() -> bool {
        return trimmedText(state["clawDraft"]) != "";
    }

    def defaultClawStatus() -> str {
        if not hasClawDraft() and not state["activeSessionId"] {
            return "Add a task. Plan now also needs an active live trace.";
        }
        if not hasClawDraft() {
            return "Add a task to use Plan now or Save draft.";
        }
        if not state["activeSessionId"] {
            return "Draft ready. Start Trace to use Plan now.";
        }
        return "Draft ready. Plan now uses the active live trace.";
    }

    def normalizedHelperFrequency(rawValue: any) -> str {
        frequency = trimmedText(rawValue).toLowerCase();  # jac:ignore[E1030]
        if frequency == "browser_open" or frequency == "daily" or frequency == "weekly" {
            return frequency;  # jac:ignore[E1002]
        }
        return "once";
    }

    def helperFrequencyLabel(rawValue: any) -> str {
        frequency = normalizedHelperFrequency(rawValue);
        if frequency == "browser_open" {
            return "On browser open";
        }
        if frequency == "daily" {
            return "Daily";
        }
        if frequency == "weekly" {
            return "Weekly";
        }
        return "Just once";
    }

    def helperFormReady() -> bool {
        return trimmedText(state["helperDraftName"]) != "" and trimmedText(state["helperDraftGoal"]) != "";
    }

    def normalizedTaskPanelTab(rawValue: any) -> str {
        return "run" if str(rawValue or "") == "run" else "create";
    }

    def localTimestamp() -> str {
        return Reflect.construct(Date, []).toLocaleString();  # jac:ignore[E1042]
    }

    def helperGoalPreview(goalText: any, maxLength: any = 88) -> str {
        preview = trimmedText(goalText).replace("\n", " ").replace("\r", " ");
        limit = Number(maxLength or 88);
        if len(preview) <= limit {
            return preview or "No goal yet.";
        }
        return preview.slice(0, limit - 3) + "...";  # jac:ignore[E1030,E1055]
    }

    def nextHelperId() -> str {
        state["helperSeed"] = state["helperSeed"] + 1;
        return "helper_" + str(Date.now()) + "_" + str(state["helperSeed"]);
    }

    def nextHelperResultId() -> str {
        state["helperResultSeed"] = state["helperResultSeed"] + 1;
        return "helper_result_" + str(Date.now()) + "_" + str(state["helperResultSeed"]);
    }

    """R: Infer a lightweight helper type from the user's goal without surfacing backend jargon.
    M: Matches a few product-approved keywords in priority order and falls back to a general helper when none apply.
    E: Empty or mixed-intent goals still produce a stable type so local helper creation never blocks on inference.
    """;
    def inferHelperType(goalText: any) -> str {
        lowered = trimmedText(goalText).toLowerCase();  # jac:ignore[E1030]
        if not lowered {
            return "general";
        }
        if lowered.includes("summarize") or lowered.includes("summary") or lowered.includes("brief") or lowered.includes("digest") {  # jac:ignore[E1032]
            return "summary";
        }
        if lowered.includes("watch") or lowered.includes("monitor") or lowered.includes("track") {  # jac:ignore[E1032]
            return "monitor";
        }
        if lowered.includes("research") or lowered.includes("find") or lowered.includes("look up") or lowered.includes("lookup") {  # jac:ignore[E1032]
            return "research";
        }
        return "general";
    }

    """R: Hide the first-pass helper spec behind the simple builder inputs.
    M: Converts the user's name, goal, and cadence into a renderer-local read-only object with trigger and intent metadata.
    E: Unknown frequencies are normalized to `once`, and the spec remains local-only so it never claims real execution.
    """;
    def buildHelperSpec(nameText: any, goalText: any, rawFrequency: any) -> any {
        frequency = normalizedHelperFrequency(rawFrequency);
        helper_type = inferHelperType(goalText);
        return {
            "type": helper_type,
            "intent": {
                "name": trimmedText(nameText),
                "goal": trimmedText(goalText)
            },
            "trigger": {
                "frequency": frequency,
                "label": helperFrequencyLabel(frequency)
            },
            "permissions": {
                "read_only": True
            },
            "runtime": {
                "mode": "renderer_local_demo"
            }
        };
    }

    def resetHelperDraft() -> None {
        state["helperDraftName"] = "";
        state["helperDraftGoal"] = "";
        state["helperDraftFrequency"] = "once";
    }

    def backendHelperCardLabel(helper: any) -> str {
        return "backend" if trimmedText(objectValue(helper, "source", "")) == "backend" else "local demo";
    }

    """R: Normalize one backend helper run into the compact renderer result shape already used by the Helpers UI.
    M: Maps stable backend fields into the existing timestamp/status/summary card fields and pulls a few short notes from runtime metadata.
    E: Empty or malformed runs return `None` so callers can skip partial backend payloads safely.
    """;
    def helperResultFromBackendRun(runRecord: any) -> any {
        if not runRecord or typeof(runRecord) != "object" {
            return None;
        }

        run_id = trimmedText(objectValue(runRecord, "run_id", ""));
        helper_id = trimmedText(objectValue(runRecord, "helper_id", ""));
        if not run_id or not helper_id {
            return None;
        }

        runtime_state = objectValue(runRecord, "runtime_state", {}) or {};
        structured_output = objectValue(runRecord, "structured_output", {}) or {};
        state_source = trimmedText(objectValue(runtime_state, "state_source", ""));
        if not state_source {
            state_source = trimmedText(objectValue(structured_output, "state_source", ""));
        }

        notes = [];
        trigger_type = trimmedText(objectValue(runRecord, "trigger_type", ""));
        if trigger_type {
            notes.push("Trigger: " + trigger_type);  # jac:ignore[E1030]
        }
        if state_source {
            notes.push("State source: " + state_source);  # jac:ignore[E1030]
        }

        browser_session_id = trimmedText(objectValue(runRecord, "browser_session_id", ""));
        if browser_session_id {
            notes.push("Browser session: " + browser_session_id);  # jac:ignore[E1030]
        }

        raw_errors = objectValue(runRecord, "errors", []) or [];
        error_items = [];
        if Array.isArray(raw_errors) {
            error_items = raw_errors;
        } elif trimmedText(raw_errors) {
            error_items = [raw_errors];
        }

        for error_text in error_items.slice(0, 2) {  # jac:ignore[E1030]
            notes.push("Error: " + str(error_text or ""));  # jac:ignore[E1030]
        }

        mode_label = trimmedText(objectValue(structured_output, "runtime_mode", ""));
        if not mode_label {
            mode_label = "backend";
        }

        return {
            "id": run_id,
            "helperId": helper_id,
            "timestamp": trimmedText(objectValue(runRecord, "finished_at", "")) or trimmedText(objectValue(runRecord, "started_at", "")),
            "mode": mode_label,
            "status": trimmedText(objectValue(runRecord, "status", "")) or "unknown",
            "summary": trimmedText(objectValue(runRecord, "summary", "")) or "No summary returned.",
            "notes": notes,
            "source": "backend"
        };
    }

    """R: Normalize one backend helper bundle into the renderer helper shape used across list, detail, and run panels.
    M: Reads the bundled helper/spec/latest-run payload and preserves the current UI field names so the render path stays local and small.
    E: Missing helper ids or required nested objects return `None` so refresh can skip incomplete backend records.
    """;
    def helperFromBackendBundle(bundle: any) -> any {
        if not bundle or typeof(bundle) != "object" {
            return None;
        }

        helper_record = objectValue(bundle, "helper", {}) or {};
        agent_spec = objectValue(bundle, "agent_spec", {}) or {};
        helper_id = trimmedText(objectValue(helper_record, "helper_id", ""));
        if not helper_id {
            return None;
        }

        latest_run = helperResultFromBackendRun(objectValue(bundle, "latest_run", {}) or {});
        return {
            "id": helper_id,
            "name": trimmedText(objectValue(helper_record, "name", "")) or "Untitled helper",
            "goal": trimmedText(objectValue(helper_record, "goal", "")),
            "frequency": normalizedHelperFrequency(objectValue(helper_record, "frequency", "once")),
            "frequencyLabel": helperFrequencyLabel(objectValue(helper_record, "frequency", "once")),
            "kind": trimmedText(objectValue(agent_spec, "kind", "")) or "general",
            "runtimeVersion": trimmedText(objectValue(helper_record, "runtime_version", objectValue(agent_spec, "runtime_version", "v1"))) or "v1",
            "status": trimmedText(objectValue(helper_record, "status", "")) or "active",
            "readOnly": objectValue(agent_spec, "read_only", True) != False,
            "createdAt": trimmedText(objectValue(helper_record, "created_at", "")),
            "updatedAt": trimmedText(objectValue(helper_record, "updated_at", "")),
            "spec": agent_spec,
            "latestRun": latest_run or {},
            "source": "backend"
        };
    }

    async def refreshHelpersFromBackend(preferredHelperId: any = "") -> bool {
        api = browserAPI();
        if not api or not api.helpersList {
            reportHelpersRefresh("helpers refresh: api.helpersList unavailable", "error", True);
            return False;
        }

        try {
            result = await api.helpersList({});
            if not result or objectValue(result, "ok", True) == False {
                reportHelpersRefresh(
                    "helpers refresh failed at api.helpersList: " + str(objectValue(result, "error", "unknown error")),
                    "error",
                    True
                );
                return False;
            }

            refreshed_helpers = [];
            backend_helpers = objectValue(result, "helpers", []) or [];
            if not Array.isArray(backend_helpers) {
                reportHelpersRefresh(
                    "helpers refresh failed at api.helpersList: api.helpersList returned non-array helpers payload",
                    "error",
                    True
                );
                return False;
            }

            reportHelpersRefresh("helpers refresh: fetched " + str(len(backend_helpers)) + " bundles");
            bundle_index = 0;
            for bundle in backend_helpers {
                bundle_index = bundle_index + 1;
                bundle_helper = objectValue(bundle, "helper", {}) or {};
                bundle_helper_id = trimmedText(objectValue(bundle_helper, "helper_id", ""));
                helper_label = bundle_helper_id or ("bundle #" + str(bundle_index));

                try {
                    mapped_helper = helperFromBackendBundle(bundle);
                    if mapped_helper {
                        refreshed_helpers.push(mapped_helper);  # jac:ignore[E1030]
                        reportHelpersRefresh("helpers refresh: mapped helper " + str(objectValue(mapped_helper, "id", helper_label)));
                    } else {
                        reportHelpersRefresh("helpers refresh: skipped empty helper bundle " + helper_label);
                    }
                } except Exception as err {
                    reportHelpersRefresh(
                        "helpers refresh failed at helperFromBackendBundle for " + helper_label + ": " + str(err.message or err),  # jac:ignore[E1030]
                        "error",
                        True
                    );
                }
            }
            state["helpers"] = refreshed_helpers;

            preferred_helper_id = trimmedText(preferredHelperId) or trimmedText(state["selectedHelperId"]);
            preferred_run_helper_id = trimmedText(state["selectedTaskRunHelperId"]);
            if preferred_helper_id and findHelperById(preferred_helper_id) {
                state["selectedHelperId"] = preferred_helper_id;
            }
            if preferred_run_helper_id and findHelperById(preferred_run_helper_id) {
                state["selectedTaskRunHelperId"] = preferred_run_helper_id;
            }

            try {
                ensureSelectedHelper();
                reportHelpersRefresh("helpers refresh: ensureSelectedHelper ok");
            } except Exception as err {
                reportHelpersRefresh(
                    "helpers refresh failed at ensureSelectedHelper: " + str(err.message or err),  # jac:ignore[E1030]
                    "error",
                    True
                );
                return False;
            }

            ensureSelectedTaskRunHelper();
            selected = selectedHelper();
            state["helperEditGoalDraft"] = trimmedText(objectValue(selected, "goal", "")) if selected else "";

            try {
                syncClawUi();
                reportHelpersRefresh("helpers refresh: syncClawUi ok");
            } except Exception as err {
                reportHelpersRefresh(
                    "helpers refresh failed at syncClawUi: " + str(err.message or err),  # jac:ignore[E1030]
                    "error",
                    True
                );
                return False;
            }
            return True;
        } except Exception as err {
            reportHelpersRefresh("helpers refresh threw: " + str(err.message or err), "error", True);  # jac:ignore[E1030]
            return False;
        }
    }

    async def refreshHelperRunsFromBackend(helperId: any) -> bool {
        wanted = trimmedText(helperId);
        if not wanted {
            return False;
        }

        api = browserAPI();
        if not api or not api.helperRunsList {
            return False;
        }

        try {
            result = await api.helperRunsList({"helper_id": wanted, "limit": 12});
            if not result or objectValue(result, "ok", True) == False {
                return False;
            }

            preserved_results = [];
            for helper_result in state["helperResults"] {
                if trimmedText(objectValue(helper_result, "helperId", "")) != wanted {
                    preserved_results.push(helper_result);  # jac:ignore[E1030]
                }
            }

            mapped_runs = [];
            for run_record in (objectValue(result, "runs", []) or []) {
                mapped_run = helperResultFromBackendRun(run_record);
                if mapped_run {
                    mapped_runs.push(mapped_run);  # jac:ignore[E1030]
                }
            }

            for mapped_run in mapped_runs {
                preserved_results.push(mapped_run);  # jac:ignore[E1030]
            }
            state["helperResults"] = preserved_results;

            selected_helper = findHelperById(wanted);
            if selected_helper {
                selected_helper["latestRun"] = mapped_runs[0] if len(mapped_runs) > 0 else {};
            }

            syncClawUi();
            return True;
        } except Exception {
            return False;
        }
    }

    """R: Keep the TASKS launcher in sync with the lower shell layout.
    M: Mirrors the open state into the toolbar toggle, hides the launcher when closed, and collapses the lower grid to a single content column.
    E: Missing DOM nodes are ignored so the browser and Helpers views still work even if the launcher is absent.
    """;
    def syncTasksPanelUi() -> None {
        panel_open = state["tasksPanelOpen"] != False;
        if state["shellContent"] {
            if panel_open {
                state["shellContent"].classList.remove("tasks-closed");  # jac:ignore[E1099]
            } else {
                state["shellContent"].classList.add("tasks-closed");  # jac:ignore[E1099]
            }
        }
        if state["layerPanel"] {
            state["layerPanel"].style.display = "flex" if panel_open else "none";  # jac:ignore[E1099]
        }
        if state["toggleLayersBtn"] {
            state["toggleLayersBtn"].textContent = "TASKS";  # jac:ignore[E1099]
            state["toggleLayersBtn"].setAttribute("aria-pressed", "true" if panel_open else "false");  # jac:ignore[E1099]
            state["toggleLayersBtn"].setAttribute("aria-expanded", "true" if panel_open else "false");  # jac:ignore[E1099]
            state["toggleLayersBtn"].title = "Close Tasks Panel" if panel_open else "Open Tasks Panel";  # jac:ignore[E1001,E1099]
        }
    }

    """R: Keep the TASKS panel focused on either quick creation or quick execution.
    M: Mirrors the active panel tab into the compact tab buttons and toggles the matching panel body in place.
    E: Unknown tab names fall back to `create`, and missing nodes simply skip visual updates.
    """;
    def syncTaskPanelTabsUi() -> None {
        active_tab = normalizedTaskPanelTab(state["activeTaskPanelTab"]);
        state["activeTaskPanelTab"] = active_tab;

        if state["tasksCreateTabBtn"] {
            if active_tab == "create" {
                state["tasksCreateTabBtn"].classList.add("active");  # jac:ignore[E1099]
            } else {
                state["tasksCreateTabBtn"].classList.remove("active");  # jac:ignore[E1099]
            }
            state["tasksCreateTabBtn"].setAttribute("aria-selected", "true" if active_tab == "create" else "false");  # jac:ignore[E1099]
            state["tasksCreateTabBtn"].title = "Record a task flow, add context, and generate a saved task.";  # jac:ignore[E1001,E1099]
        }
        if state["tasksRunTabBtn"] {
            if active_tab == "run" {
                state["tasksRunTabBtn"].classList.add("active");  # jac:ignore[E1099]
            } else {
                state["tasksRunTabBtn"].classList.remove("active");  # jac:ignore[E1099]
            }
            state["tasksRunTabBtn"].setAttribute("aria-selected", "true" if active_tab == "run" else "false");  # jac:ignore[E1099]
            state["tasksRunTabBtn"].title = "Run a saved task with optional one-run guidance.";  # jac:ignore[E1001,E1099]
        }
        if state["tasksCreatePanel"] {
            state["tasksCreatePanel"].style.display = "flex" if active_tab == "create" else "none";  # jac:ignore[E1099]
        }
        if state["tasksRunPanel"] {
            state["tasksRunPanel"].style.display = "flex" if active_tab == "run" else "none";  # jac:ignore[E1099]
        }
    }

    """R: Keep the browser shell focused on either the live webview or the Helpers workspace.
    M: Switches the active page flag, mirrors it into the existing chrome buttons, and toggles the two root content panes.
    E: Unknown view names fall back to `browser`, and missing page nodes simply skip the visibility updates.
    """;
    def syncShellViewUi() -> None {
        active_view = "helpers" if state["activeShellView"] == "helpers" else "browser";
        if state["showBrowserViewBtn"] {
            state["showBrowserViewBtn"].setAttribute("aria-pressed", "true" if active_view == "browser" else "false");  # jac:ignore[E1099]
        }
        if state["showHelpersViewBtn"] {
            state["showHelpersViewBtn"].setAttribute("aria-pressed", "true" if active_view == "helpers" else "false");  # jac:ignore[E1099]
        }
        if state["viewport"] {
            state["viewport"].style.display = "block" if active_view == "browser" else "none";  # jac:ignore[E1099]
        }
        if state["helpersPage"] {
            state["helpersPage"].style.display = "flex" if active_view == "helpers" else "none";  # jac:ignore[E1099]
        }
        renderActiveTabState(state["activeTabId"]);
    }

    def setShellView(nextView: any) -> None {
        state["activeShellView"] = "helpers" if str(nextView or "") == "helpers" else "browser";
        syncClawUi();
    }

    """R: Keep the larger helper-builder panel aligned with local renderer state.
    M: Mirrors the draft fields into the DOM, toggles the expanded card, and updates builder action labels and disabled states.
    E: Missing builder nodes are ignored so the browser shell still works when helper UI is absent.
    """;
    def syncHelperBuilderUi() -> None {
        if state["helpersPageCreateBtn"] {
            state["helpersPageCreateBtn"].textContent = "Close Builder" if state["helperBuilderOpen"] else "Create Helper";  # jac:ignore[E1099]
            state["helpersPageCreateBtn"].setAttribute("aria-expanded", str(state["helperBuilderOpen"]));  # jac:ignore[E1099]
            state["helpersPageCreateBtn"].title = "Hide the helper builder." if state["helperBuilderOpen"] else "Open the helper builder in the Helpers page.";  # jac:ignore[E1001,E1099]
        }
        if state["helperBuilderPanel"] {
            state["helperBuilderPanel"].style.display = "flex" if state["helperBuilderOpen"] else "none";  # jac:ignore[E1099]
        }
        if state["helperNameInput"] and state["helperNameInput"].value != state["helperDraftName"] {  # jac:ignore[E1099]
            state["helperNameInput"].value = state["helperDraftName"];  # jac:ignore[E1099]
        }
        if state["helperGoalInput"] and state["helperGoalInput"].value != state["helperDraftGoal"] {  # jac:ignore[E1099]
            state["helperGoalInput"].value = state["helperDraftGoal"];  # jac:ignore[E1099]
        }
        if state["helperFrequencySelect"] and state["helperFrequencySelect"].value != state["helperDraftFrequency"] {  # jac:ignore[E1099]
            state["helperFrequencySelect"].value = state["helperDraftFrequency"];  # jac:ignore[E1099]
        }
    if state["helperCreateBtn"] {
            state["helperCreateBtn"].disabled = not helperFormReady();  # jac:ignore[E1099]
            state["helperCreateBtn"].title = "Add a name and helper goal first." if not helperFormReady() else "Create this helper.";  # jac:ignore[E1001,E1099]
        }
        if state["helperCancelBtn"] {
            state["helperCancelBtn"].textContent = "Close" if state["helperBuilderOpen"] else "Cancel";  # jac:ignore[E1099]
        }
    }

    def taskCreateHasRecordedSession() -> bool {
        return trimmedText(state["recordedTaskSessionId"]) != "";
    }

    """R: Keep the TASKS create composer aligned with recording and post-recording generation state.
    M: Mirrors recording status into the Start/Stop control, shows the post-stop context box, and surfaces the latest captured session reference.
    E: Missing DOM nodes are ignored so the broader shell can still run even if the compact create UI is absent.
    """;
    def syncTaskCreateUi() -> None {
        session_id = trimmedText(state["recordedTaskSessionId"]);
        event_count = Number(state["recordedTaskEventCount"] or 0);  # jac:ignore[E1053]

        if state["taskCreateRecordingState"] {
            if state["taskRecordingActive"] {
                state["taskCreateRecordingState"].setAttribute("data-recording", "true");  # jac:ignore[E1099]
            } else {
                state["taskCreateRecordingState"].setAttribute("data-recording", "false");  # jac:ignore[E1099]
            }
        }
        if state["taskCreateSessionMeta"] {
            if state["taskRecordingActive"] and state["activeSessionId"] {
                state["taskCreateSessionMeta"].textContent = "Recording live: " + state["activeSessionId"];  # jac:ignore[E1055,E1099]
            } elif session_id {
                state["taskCreateSessionMeta"].textContent = (  # jac:ignore[E1099]
                    "Recorded session " + session_id +
                    " with " + str(event_count) + " events."
                );
            } else {
                state["taskCreateSessionMeta"].textContent = "No recording captured yet.";  # jac:ignore[E1099]
            }
        }
        if state["taskPanelRecordBtn"] {
            state["taskPanelRecordBtn"].disabled = state["taskCreateIsGenerating"] == True;  # jac:ignore[E1099]
            if state["taskCreateIsGenerating"] {
                state["taskPanelRecordBtn"].textContent = "Generating...";  # jac:ignore[E1099]
                state["taskPanelRecordBtn"].title = "Task generation is in progress.";  # jac:ignore[E1001,E1099]
            } elif state["taskRecordingActive"] {
                state["taskPanelRecordBtn"].textContent = "Stop";  # jac:ignore[E1099]
                state["taskPanelRecordBtn"].title = "Stop recording this task trace.";  # jac:ignore[E1001,E1099]
            } else {
                state["taskPanelRecordBtn"].textContent = "Start";  # jac:ignore[E1099]
                state["taskPanelRecordBtn"].title = "Start recording a task trace.";  # jac:ignore[E1001,E1099]
            }
        }
        if state["taskCreateContextPanel"] {
            state["taskCreateContextPanel"].style.display = "flex" if taskCreateHasRecordedSession() and not state["taskRecordingActive"] else "none";  # jac:ignore[E1099]
        }
        if state["taskCreateContextInput"] and state["taskCreateContextInput"].value != state["taskCreateContextText"] {  # jac:ignore[E1099]
            state["taskCreateContextInput"].value = state["taskCreateContextText"];  # jac:ignore[E1099]
        }
        if state["taskPanelGenerateBtn"] {
            state["taskPanelGenerateBtn"].disabled = not taskCreateHasRecordedSession() or state["taskRecordingActive"] == True or state["taskCreateIsGenerating"] == True;  # jac:ignore[E1099]
            state["taskPanelGenerateBtn"].textContent = "Generating..." if state["taskCreateIsGenerating"] else "Generate Task";  # jac:ignore[E1099]
            state["taskPanelGenerateBtn"].title = (  # jac:ignore[E1001,E1099]
                "Stop recording before generating a task." if state["taskRecordingActive"] else (
                    "Record a task first." if not taskCreateHasRecordedSession() else "Generate a saved task from the recorded trace and extra context."
                )
            );
        }
    }

    def setTaskPanelTab(nextTab: any) -> None {
        state["activeTaskPanelTab"] = normalizedTaskPanelTab(nextTab);
        syncClawUi();
    }

    """R: Keep run-mode task selection stable inside the compact TASKS panel.
    M: Reuses the current run selection when possible and otherwise falls back to the first saved helper in local state.
    E: Empty helper sets clear the run selection so the panel never targets a stale task id.
    """;
    def ensureSelectedTaskRunHelper() -> None {
        if findHelperById(state["selectedTaskRunHelperId"]) {
            return;
        }
        if len(state["helpers"]) > 0 {  # jac:ignore[E1053]
            state["selectedTaskRunHelperId"] = str(objectValue(state["helpers"][0], "id", ""));
            return;
        }
        state["selectedTaskRunHelperId"] = "";
    }

    def selectedTaskRunHelper() -> any {
        ensureSelectedTaskRunHelper();
        return findHelperById(state["selectedTaskRunHelperId"]);
    }

    def selectTaskRunHelper(helperId: any, focusRunTab: any = True) -> None {
        helper = findHelperById(helperId);
        if not helper {
            return;
        }
        state["selectedTaskRunHelperId"] = str(objectValue(helper, "id", ""));
        if focusRunTab != False {
            state["activeTaskPanelTab"] = "run";
        }
        syncClawUi();
    }

    """R: Render the compact TASKS run list from renderer-local helper state.
    M: Rebuilds small saved-task cards and lets the user select which helper should be used for the next local demo run.
    E: Empty helper lists fall back to a truthful prompt, and missing DOM nodes simply skip rendering work.
    """;
    def renderHelperList() -> None {
        if not state["helperList"] {
            return;
        }

        ensureSelectedTaskRunHelper();
        selected_id = str(state["selectedTaskRunHelperId"] or "");
        state["helperList"].textContent = "";  # jac:ignore[E1099]
        if len(state["helpers"]) == 0 {  # jac:ignore[E1053]
            state["helperList"].textContent = "No saved tasks yet. Use Create to make one quickly, or open Helpers for deeper management.";  # jac:ignore[E1099]
            return;
        }

        for helper in state["helpers"] {
            helper_id = str(objectValue(helper, "id", ""));
            card = document.createElement("button");
            card.type = "button";  # jac:ignore[E1030]
            card.className = "task-run-list-item";  # jac:ignore[E1030]
            card.style.display = "flex";  # jac:ignore[E1030]
            card.style.flexDirection = "column";  # jac:ignore[E1030]
            card.style.alignItems = "stretch";  # jac:ignore[E1030]
            card.style.gap = "6px";  # jac:ignore[E1030]
            card.style.width = "100%";  # jac:ignore[E1030]
            card.style.padding = "10px 12px";  # jac:ignore[E1030]
            card.style.borderRadius = "14px";  # jac:ignore[E1030]
            card.style.border = "1px solid rgba(88, 116, 173, 0.14)";  # jac:ignore[E1030]
            card.style.background = "linear-gradient(180deg, rgba(234, 241, 255, 0.98) 0%, rgba(255, 255, 255, 0.98) 100%)" if helper_id == selected_id else "#ffffff";  # jac:ignore[E1030]
            card.style.boxSizing = "border-box";  # jac:ignore[E1030]
            card.style.cursor = "pointer";  # jac:ignore[E1030]
            card.style.textAlign = "left";  # jac:ignore[E1030]
            card.title = "Select this saved task for the next run.";  # jac:ignore[E1030]
            card.addEventListener("click", lambda {  # jac:ignore[E1030]
                selectTaskRunHelper(helper_id);
            });

            title = document.createElement("div");
            title.style.color = "#183154";  # jac:ignore[E1030]
            title.style.fontSize = "12px";  # jac:ignore[E1030]
            title.style.fontWeight = "800";  # jac:ignore[E1030]
            title.textContent = str(objectValue(helper, "name", "Untitled helper"));  # jac:ignore[E1030]

            meta = document.createElement("div");
            meta.style.color = "#526885";  # jac:ignore[E1030]
            meta.style.fontSize = "11px";  # jac:ignore[E1030]
            meta.style.lineHeight = "1.5";  # jac:ignore[E1030]
            meta.textContent = (  # jac:ignore[E1030]
                helperFrequencyLabel(objectValue(helper, "frequency", "once")) +
                " | " +
                str(objectValue(helper, "kind", "general")) +
                " | local demo"
            );

            goal = document.createElement("div");
            goal.style.color = "#324b70";  # jac:ignore[E1030]
            goal.style.fontSize = "11px";  # jac:ignore[E1030]
            goal.style.lineHeight = "1.55";  # jac:ignore[E1030]
            goal.textContent = helperGoalPreview(objectValue(helper, "goal", ""));  # jac:ignore[E1030]

            stamp = document.createElement("div");
            stamp.style.color = "#6b7f9f";  # jac:ignore[E1030]
            stamp.style.fontSize = "10px";  # jac:ignore[E1030]
            stamp.textContent = "Selected for run" if helper_id == selected_id else ("Created " + trimmedText(objectValue(helper, "createdAt", "")));  # jac:ignore[E1030]

            card.appendChild(title);  # jac:ignore[E1030]
            card.appendChild(meta);  # jac:ignore[E1030]
            card.appendChild(goal);  # jac:ignore[E1030]
            card.appendChild(stamp);  # jac:ignore[E1030]
            state["helperList"].appendChild(card);  # jac:ignore[E1099]
        }
    }

    """R: Keep the TASKS run composer aligned with the selected helper and one-run guidance draft.
    M: Mirrors the selected helper summary, syncs the override textarea, and disables run actions when nothing is selected.
    E: Missing DOM nodes are ignored, and empty helper state falls back to honest instructional copy.
    """;
    def syncTaskRunComposerUi() -> None {
        helper = selectedTaskRunHelper();
        helper_name = trimmedText(objectValue(helper, "name", "")) if helper else "";
        helper_goal = trimmedText(objectValue(helper, "goal", "")) if helper else "";

        if state["taskRunSelectedName"] {
            state["taskRunSelectedName"].textContent = helper_name or "No task selected";  # jac:ignore[E1099]
        }
        if state["taskRunSelectedMeta"] {
            state["taskRunSelectedMeta"].textContent = (  # jac:ignore[E1099]
                helperFrequencyLabel(objectValue(helper, "frequency", "once")) +
                " | " +
                str(objectValue(helper, "kind", "general")) +
                " | saved helper"
            ) if helper else "Choose a saved task from the list above, or create one in this panel.";
        }
        if state["taskRunSelectedGoal"] {
            state["taskRunSelectedGoal"].textContent = helper_goal or "Saved instructions will appear here before you run.";  # jac:ignore[E1099]
        }
        if state["taskRunOverrideInput"] and state["taskRunOverrideInput"].value != state["taskRunOverrideText"] {  # jac:ignore[E1099]
            state["taskRunOverrideInput"].value = state["taskRunOverrideText"];  # jac:ignore[E1099]
        }
        if state["taskPanelRunBtn"] {
            state["taskPanelRunBtn"].disabled = not helper;  # jac:ignore[E1099]
            state["taskPanelRunBtn"].title = "Select a saved task first." if not helper else "Run this saved task with optional one-run guidance.";  # jac:ignore[E1001,E1099]
        }
        if state["taskPanelRunClearBtn"] {
            state["taskPanelRunClearBtn"].disabled = trimmedText(state["taskRunOverrideText"]) == "";  # jac:ignore[E1099]
            state["taskPanelRunClearBtn"].title = "Clear the one-run guidance." if trimmedText(state["taskRunOverrideText"]) else "No one-run guidance to clear.";  # jac:ignore[E1001,E1099]
        }
    }

    def openHelperBuilder() -> None {
        state["activeShellView"] = "helpers";
        state["activeTaskPanelTab"] = "create";
        state["helperBuilderOpen"] = True;
        syncClawUi();
        if state["helperBuilderPanel"] {
            state["helperBuilderPanel"].scrollIntoView({"behavior": "smooth", "block": "nearest"});  # jac:ignore[E1099]
        }
        if state["helperNameInput"] {
            setTimeout(lambda { state["helperNameInput"].focus(); }, 10);  # jac:ignore[E1099]
        }
    }

    def closeHelperBuilder(clearDraft: any = True) -> None {
        state["helperBuilderOpen"] = False;
        if clearDraft {
            resetHelperDraft();
        }
        syncClawUi();
    }

    def currentBrowserStateHint() -> any {
        webview = getActiveWebview();
        active_tab = getActiveTab();
        current_url = "";
        current_title = "";

        if webview {
            current_url = trimmedText(webview.getURL() or "");
            current_title = trimmedText(webview.getTitle() or "");
        }
        if not current_url and active_tab {
            current_url = trimmedText(objectValue(active_tab, "url", ""));
        }
        if not current_title and active_tab {
            current_title = trimmedText(objectValue(active_tab, "title", ""));
        }
        if not current_url and state["addressInput"] {
            current_url = trimmedText(state["addressInput"].value or "");  # jac:ignore[E1099]
        }

        return {
            "current_url": current_url,
            "title": current_title
        };
    }

    def findHelperById(helperId: any) -> any {
        wanted = str(helperId or "");
        if not wanted {
            return None;
        }
        for helper in state["helpers"] {
            if helper["id"] == wanted {
                return helper;
            }
        }
        return None;
    }

    def helperResultsFor(helperId: any) -> any {
        wanted = str(helperId or "");
        matches = [];
        if not wanted {
            return matches;
        }
        for result in state["helperResults"] {
            if str(objectValue(result, "helperId", "")) == wanted {
                matches.push(result);  # jac:ignore[E1030]
            }
        }
        return matches;
    }

    def ensureSelectedHelper() -> None {
        if findHelperById(state["selectedHelperId"]) {
            return;
        }
        if len(state["helpers"]) > 0 {  # jac:ignore[E1053]
            state["selectedHelperId"] = str(objectValue(state["helpers"][0], "id", ""));
            state["helperEditGoalDraft"] = trimmedText(objectValue(state["helpers"][0], "goal", ""));
            return;
        }
        state["selectedHelperId"] = "";
        state["helperEditMode"] = False;
        state["helperEditGoalDraft"] = "";
    }

    def selectHelper(helperId: any, editMode: any = False) -> None {
        helper = findHelperById(helperId);
        if not helper {
            return;
        }
        state["selectedHelperId"] = str(objectValue(helper, "id", ""));
        state["helperEditMode"] = editMode == True;
        state["helperEditGoalDraft"] = trimmedText(objectValue(helper, "goal", ""));
        syncClawUi();
    }

    def selectedHelper() -> any {
        ensureSelectedHelper();
        return findHelperById(state["selectedHelperId"]);
    }

    """R: Capture a demo-safe helper run result without depending on backend execution.
    M: Prepends a renderer-local result object with timestamp, mode, status, summary, and optional notes to the shared helper history.
    E: Unknown helper ids are ignored, and the local history is trimmed so repeated demo runs stay bounded.
    """;
    def recordHelperResult(helperId: any, modeName: any, statusText: any, summaryText: any, notes: any = []) -> None {
        helper = findHelperById(helperId);
        if not helper {
            return;
        }

        result = {
            "id": nextHelperResultId(),
            "helperId": str(objectValue(helper, "id", "")),
            "timestamp": localTimestamp(),
            "mode": trimmedText(modeName) or "renderer_local_demo",
            "status": trimmedText(statusText) or "recorded",
            "summary": trimmedText(summaryText) or "Local helper result recorded.",
            "notes": notes or []
        };
        state["helperResults"].unshift(result);  # jac:ignore[E1099]
        if len(state["helperResults"]) > 48 {  # jac:ignore[E1053]
            state["helperResults"] = state["helperResults"].slice(0, 48);  # jac:ignore[E1099]
        }
    }

    def beginHelperEdit() -> None {
        helper = selectedHelper();
        if not helper {
            return;
        }
        state["helperEditMode"] = True;
        state["helperEditGoalDraft"] = trimmedText(objectValue(helper, "goal", ""));
        syncClawUi();
        setTimeout(lambda {
            detailInput = document.getElementById("helperDetailGoalInput");
            if detailInput {
                detailInput.focus();  # jac:ignore[E1030]
            }
        }, 10);
    }

    def cancelHelperEdit() -> None {
        helper = selectedHelper();
        state["helperEditMode"] = False;
        state["helperEditGoalDraft"] = trimmedText(objectValue(helper, "goal", "")) if helper else "";
        syncClawUi();
    }

    """R: Apply local-only helper instruction edits from the dedicated Helpers page.
    M: Validates the draft, updates the helper goal and inferred local spec in memory, and leaves persistence or scheduling untouched.
    E: Empty drafts keep edit mode open and surface a truthful prompt instead of saving a blank helper brief.
    """;
    def saveHelperEdit() -> None {
        helper = selectedHelper();
        if not helper {
            return;
        }

        updated_goal = trimmedText(state["helperEditGoalDraft"]);
        if not updated_goal {
            setClawStatus("Add helper instructions before saving local edits.");
            return;
        }

        helper["goal"] = updated_goal;
        helper["kind"] = inferHelperType(updated_goal);
        helper["spec"] = buildHelperSpec(helper["name"], updated_goal, helper["frequency"]);
        state["helperEditMode"] = False;
        appendClawTranscript(
            "system",
            "Updated helper instructions locally for " + str(objectValue(helper, "name", "Helper")) + ".\n" +
            "This changes the renderer-only demo copy and does not persist or schedule anything yet."
        );
        setClawStatus("Saved local helper edits for " + str(objectValue(helper, "name", "Helper")) + ".");
    }

    """R: Render the dedicated Helpers page from the same local helper state used by the side panel.
    M: Rebuilds the helper list, selected-helper detail, and recent results areas whenever local helper state changes.
    E: Empty helper sets and missing containers fall back to truthful placeholders instead of blocking the shell.
    """;
    def renderHelpersWorkspace() -> None {
        if not state["helpersPageList"] or not state["helpersPageDetail"] or not state["helpersPageResults"] {
            return;
        }

        ensureSelectedHelper();
        selected_id = str(state["selectedHelperId"] or "");
        selected = findHelperById(selected_id);

        state["helpersPageList"].textContent = "";  # jac:ignore[E1099]
        if len(state["helpers"]) == 0 {  # jac:ignore[E1053]
            empty_list = document.createElement("div");
            empty_list.style.padding = "14px";  # jac:ignore[E1030]
            empty_list.style.borderRadius = "16px";  # jac:ignore[E1030]
            empty_list.style.border = "1px dashed rgba(88, 116, 173, 0.22)";  # jac:ignore[E1030]
            empty_list.style.background = "rgba(244, 247, 255, 0.76)";  # jac:ignore[E1030]
            empty_list.style.color = "#526885";  # jac:ignore[E1030]
            empty_list.style.fontSize = "13px";  # jac:ignore[E1030]
            empty_list.style.lineHeight = "1.6";  # jac:ignore[E1030]
            empty_list.textContent = "No helpers yet. Use quick Create in TASKS or Create Helper here when you want the deeper workspace view.";  # jac:ignore[E1030]
            state["helpersPageList"].appendChild(empty_list);  # jac:ignore[E1099]
        } else {
            for helper in state["helpers"] {
                helper_id = str(objectValue(helper, "id", ""));
                card = document.createElement("button");
                card.type = "button";  # jac:ignore[E1030]
                card.style.display = "flex";  # jac:ignore[E1030]
                card.style.flexDirection = "column";  # jac:ignore[E1030]
                card.style.alignItems = "stretch";  # jac:ignore[E1030]
                card.style.gap = "10px";  # jac:ignore[E1030]
                card.style.width = "100%";  # jac:ignore[E1030]
                card.style.padding = "14px";  # jac:ignore[E1030]
                card.style.borderRadius = "18px";  # jac:ignore[E1030]
                card.style.border = "1px solid rgba(88, 116, 173, 0.14)";  # jac:ignore[E1030]
                card.style.background = "#ffffff" if helper_id != selected_id else "linear-gradient(180deg, rgba(234, 241, 255, 0.98) 0%, rgba(255, 255, 255, 0.98) 100%)";  # jac:ignore[E1030]
                card.style.boxSizing = "border-box";  # jac:ignore[E1030]
                card.style.cursor = "pointer";  # jac:ignore[E1030]
                card.style.textAlign = "left";  # jac:ignore[E1030]
                card.addEventListener("click", lambda {  # jac:ignore[E1030]
                    selectHelper(helper_id);
                });

                top_row = document.createElement("div");
                top_row.style.display = "flex";  # jac:ignore[E1030]
                top_row.style.justifyContent = "space-between";  # jac:ignore[E1030]
                top_row.style.alignItems = "flex-start";  # jac:ignore[E1030]
                top_row.style.gap = "10px";  # jac:ignore[E1030]

                title_wrap = document.createElement("div");
                title_wrap.style.display = "flex";  # jac:ignore[E1030]
                title_wrap.style.flexDirection = "column";  # jac:ignore[E1030]
                title_wrap.style.gap = "4px";  # jac:ignore[E1030]

                title = document.createElement("div");
                title.style.color = "#183154";  # jac:ignore[E1030]
                title.style.fontSize = "14px";  # jac:ignore[E1030]
                title.style.fontWeight = "800";  # jac:ignore[E1030]
                title.textContent = str(objectValue(helper, "name", "Untitled helper"));  # jac:ignore[E1030]

                preview = document.createElement("div");
                preview.style.color = "#526885";  # jac:ignore[E1030]
                preview.style.fontSize = "12px";  # jac:ignore[E1030]
                preview.style.lineHeight = "1.55";  # jac:ignore[E1030]
                preview.textContent = helperGoalPreview(objectValue(helper, "goal", ""), 112);  # jac:ignore[E1030]

                title_wrap.appendChild(title);  # jac:ignore[E1030]
                title_wrap.appendChild(preview);  # jac:ignore[E1030]

                run_btn = document.createElement("button");
                run_btn.className = "layer-btn";  # jac:ignore[E1030]
                run_btn.type = "button";  # jac:ignore[E1030]
                run_btn.textContent = "Run Task";  # jac:ignore[E1030]
                run_btn.style.flex = "0 0 auto";  # jac:ignore[E1030]
                run_btn.style.padding = "0 12px";  # jac:ignore[E1030]
                run_btn.style.minWidth = "92px";  # jac:ignore[E1030]
                run_btn.addEventListener("click", lambda (event: any) {  # jac:ignore[E1030]
                    event.stopPropagation();
                    async def handle {
                        await handleHelperRunNow(helper_id);
                    }
                    handle();
                });

                top_row.appendChild(title_wrap);  # jac:ignore[E1030]
                top_row.appendChild(run_btn);  # jac:ignore[E1030]

                meta = document.createElement("div");
                meta.style.display = "flex";  # jac:ignore[E1030]
                meta.style.flexWrap = "wrap";  # jac:ignore[E1030]
                meta.style.gap = "8px";  # jac:ignore[E1030]
                meta.style.color = "#38557f";  # jac:ignore[E1030]
                meta.style.fontSize = "11px";  # jac:ignore[E1030]
                meta.style.fontWeight = "700";  # jac:ignore[E1030]
                meta.textContent = (  # jac:ignore[E1030]
                    "Frequency: " + helperFrequencyLabel(objectValue(helper, "frequency", "once")) +
                    " | Type: " + str(objectValue(helper, "kind", "general")) +
                    " | " + backendHelperCardLabel(helper)
                );

                card.appendChild(top_row);  # jac:ignore[E1030]
                card.appendChild(meta);  # jac:ignore[E1030]
                state["helpersPageList"].appendChild(card);  # jac:ignore[E1099]
            }
        }

        state["helpersPageDetail"].textContent = "";  # jac:ignore[E1099]
        if not selected {
            empty_detail = document.createElement("div");
            empty_detail.style.color = "#526885";  # jac:ignore[E1030]
            empty_detail.style.fontSize = "13px";  # jac:ignore[E1030]
            empty_detail.style.lineHeight = "1.6";  # jac:ignore[E1030]
            empty_detail.textContent = "Select a helper to inspect its local instructions, edit them, or run it now.";  # jac:ignore[E1030]
            state["helpersPageDetail"].appendChild(empty_detail);  # jac:ignore[E1099]
        } else {
            heading_row = document.createElement("div");
            heading_row.style.display = "flex";  # jac:ignore[E1030]
            heading_row.style.justifyContent = "space-between";  # jac:ignore[E1030]
            heading_row.style.alignItems = "flex-start";  # jac:ignore[E1030]
            heading_row.style.gap = "12px";  # jac:ignore[E1030]

            title_wrap = document.createElement("div");
            title_wrap.style.display = "flex";  # jac:ignore[E1030]
            title_wrap.style.flexDirection = "column";  # jac:ignore[E1030]
            title_wrap.style.gap = "4px";  # jac:ignore[E1030]

            title = document.createElement("div");
            title.style.color = "#183154";  # jac:ignore[E1030]
            title.style.fontSize = "24px";  # jac:ignore[E1030]
            title.style.fontWeight = "800";  # jac:ignore[E1030]
            title.style.letterSpacing = "-0.03em";  # jac:ignore[E1030]
            title.textContent = str(objectValue(selected, "name", "Untitled helper"));  # jac:ignore[E1030]

            subtitle = document.createElement("div");
            subtitle.style.color = "#526885";  # jac:ignore[E1030]
            subtitle.style.fontSize = "13px";  # jac:ignore[E1030]
            subtitle.style.lineHeight = "1.55";  # jac:ignore[E1030]
            subtitle.textContent = "Persisted helper backed by the Jac runtime.";  # jac:ignore[E1030]

            title_wrap.appendChild(title);  # jac:ignore[E1030]
            title_wrap.appendChild(subtitle);  # jac:ignore[E1030]

            actions = document.createElement("div");
            actions.style.display = "flex";  # jac:ignore[E1030]
            actions.style.flexWrap = "wrap";  # jac:ignore[E1030]
            actions.style.justifyContent = "flex-end";  # jac:ignore[E1030]
            actions.style.gap = "8px";  # jac:ignore[E1030]

            run_btn = document.createElement("button");
            run_btn.className = "layer-btn";  # jac:ignore[E1030]
            run_btn.type = "button";  # jac:ignore[E1030]
            run_btn.textContent = "Run Task";  # jac:ignore[E1030]
            run_btn.addEventListener("click", lambda {  # jac:ignore[E1030]
                async def handle {
                    await handleHelperRunNow(objectValue(selected, "id", ""));
                }
                handle();
            });
            actions.appendChild(run_btn);  # jac:ignore[E1030]

            if state["helperEditMode"] {
                save_btn = document.createElement("button");
                save_btn.className = "layer-btn";  # jac:ignore[E1030]
                save_btn.type = "button";  # jac:ignore[E1030]
                save_btn.textContent = "Save";  # jac:ignore[E1030]
                save_btn.addEventListener("click", lambda {  # jac:ignore[E1030]
                    saveHelperEdit();
                });

                cancel_btn = document.createElement("button");
                cancel_btn.className = "layer-btn";  # jac:ignore[E1030]
                cancel_btn.type = "button";  # jac:ignore[E1030]
                cancel_btn.textContent = "Cancel";  # jac:ignore[E1030]
                cancel_btn.addEventListener("click", lambda {  # jac:ignore[E1030]
                    cancelHelperEdit();
                });

                actions.appendChild(save_btn);  # jac:ignore[E1030]
                actions.appendChild(cancel_btn);  # jac:ignore[E1030]
            } else {
                edit_btn = document.createElement("button");
                edit_btn.className = "layer-btn";  # jac:ignore[E1030]
                edit_btn.type = "button";  # jac:ignore[E1030]
                edit_btn.textContent = "Edit";  # jac:ignore[E1030]
                edit_btn.addEventListener("click", lambda {  # jac:ignore[E1030]
                    beginHelperEdit();
                });
                actions.appendChild(edit_btn);  # jac:ignore[E1030]
            }

            heading_row.appendChild(title_wrap);  # jac:ignore[E1030]
            heading_row.appendChild(actions);  # jac:ignore[E1030]
            state["helpersPageDetail"].appendChild(heading_row);  # jac:ignore[E1099]

            meta = document.createElement("div");
            meta.style.display = "flex";  # jac:ignore[E1030]
            meta.style.flexWrap = "wrap";  # jac:ignore[E1030]
            meta.style.gap = "8px";  # jac:ignore[E1030]
            meta.style.marginTop = "2px";  # jac:ignore[E1030]
            meta.style.color = "#38557f";  # jac:ignore[E1030]
            meta.style.fontSize = "11px";  # jac:ignore[E1030]
            meta.style.fontWeight = "700";  # jac:ignore[E1030]
            meta.textContent = (  # jac:ignore[E1030]
                "Frequency: " + helperFrequencyLabel(objectValue(selected, "frequency", "once")) +
                " | Type: " + str(objectValue(selected, "kind", "general")) +
                " | Created: " + str(objectValue(selected, "createdAt", "local session"))
            );
            state["helpersPageDetail"].appendChild(meta);  # jac:ignore[E1099]

            latest_result = None;
            selected_results = helperResultsFor(objectValue(selected, "id", ""));
            if len(selected_results) > 0 {
                latest_result = selected_results[0];
            } else {
                latest_result = objectValue(selected, "latestRun", {}) or {};
            }
            if latest_result and trimmedText(objectValue(latest_result, "status", "")) {
                latest_card = document.createElement("div");
                latest_card.style.display = "flex";  # jac:ignore[E1030]
                latest_card.style.flexDirection = "column";  # jac:ignore[E1030]
                latest_card.style.gap = "6px";  # jac:ignore[E1030]
                latest_card.style.marginTop = "4px";  # jac:ignore[E1030]
                latest_card.style.padding = "14px 16px";  # jac:ignore[E1030]
                latest_card.style.borderRadius = "18px";  # jac:ignore[E1030]
                latest_card.style.border = "1px solid rgba(53, 92, 163, 0.16)";  # jac:ignore[E1030]
                latest_card.style.background = "rgba(235, 242, 255, 0.76)";  # jac:ignore[E1030]

                latest_title = document.createElement("div");
                latest_title.style.color = "#355ca3";  # jac:ignore[E1030]
                latest_title.style.fontSize = "11px";  # jac:ignore[E1030]
                latest_title.style.fontWeight = "800";  # jac:ignore[E1030]
                latest_title.style.letterSpacing = "0.08em";  # jac:ignore[E1030]
                latest_title.style.textTransform = "uppercase";  # jac:ignore[E1030]
                latest_title.textContent = "Latest run | " + str(objectValue(latest_result, "status", "unknown"));  # jac:ignore[E1030]

                latest_summary = document.createElement("div");
                latest_summary.style.color = "#183154";  # jac:ignore[E1030]
                latest_summary.style.fontSize = "13px";  # jac:ignore[E1030]
                latest_summary.style.fontWeight = "700";  # jac:ignore[E1030]
                latest_summary.style.lineHeight = "1.6";  # jac:ignore[E1030]
                latest_summary.textContent = trimmedText(objectValue(latest_result, "summary", "")) or "No summary returned.";  # jac:ignore[E1030]

                latest_card.appendChild(latest_title);  # jac:ignore[E1030]
                latest_card.appendChild(latest_summary);  # jac:ignore[E1030]
                state["helpersPageDetail"].appendChild(latest_card);  # jac:ignore[E1099]
            }

            label = document.createElement("div");
            label.style.color = "#6b7b95";  # jac:ignore[E1030]
            label.style.fontSize = "11px";  # jac:ignore[E1030]
            label.style.fontWeight = "800";  # jac:ignore[E1030]
            label.style.letterSpacing = "0.08em";  # jac:ignore[E1030]
            label.style.textTransform = "uppercase";  # jac:ignore[E1030]
            label.textContent = "Instructions";  # jac:ignore[E1030]
            state["helpersPageDetail"].appendChild(label);  # jac:ignore[E1099]

            if state["helperEditMode"] {
                textarea = document.createElement("textarea");
                textarea.id = "helperDetailGoalInput";  # jac:ignore[E1030]
                textarea.rows = 8;  # jac:ignore[E1030]
                textarea.spellcheck = False;  # jac:ignore[E1030]
                textarea.value = state["helperEditGoalDraft"];  # jac:ignore[E1030]
                textarea.style.width = "100%";  # jac:ignore[E1030]
                textarea.style.minHeight = "180px";  # jac:ignore[E1030]
                textarea.style.padding = "14px 16px";  # jac:ignore[E1030]
                textarea.style.borderRadius = "18px";  # jac:ignore[E1030]
                textarea.style.border = "1px solid rgba(88, 116, 173, 0.16)";  # jac:ignore[E1030]
                textarea.style.background = "#ffffff";  # jac:ignore[E1030]
                textarea.style.boxSizing = "border-box";  # jac:ignore[E1030]
                textarea.style.color = "#1f345a";  # jac:ignore[E1030]
                textarea.style.fontSize = "14px";  # jac:ignore[E1030]
                textarea.style.fontWeight = "600";  # jac:ignore[E1030]
                textarea.style.lineHeight = "1.65";  # jac:ignore[E1030]
                textarea.style.resize = "vertical";  # jac:ignore[E1030]
                textarea.addEventListener("input", lambda (event: any) {  # jac:ignore[E1030]
                    target = event.currentTarget or event.target;
                    state["helperEditGoalDraft"] = str(target.value or "");
                });
                state["helpersPageDetail"].appendChild(textarea);  # jac:ignore[E1099]
            } else {
                goal = document.createElement("div");
                goal.style.padding = "16px 18px";  # jac:ignore[E1030]
                goal.style.borderRadius = "18px";  # jac:ignore[E1030]
                goal.style.border = "1px solid rgba(88, 116, 173, 0.12)";  # jac:ignore[E1030]
                goal.style.background = "rgba(244, 247, 255, 0.84)";  # jac:ignore[E1030]
                goal.style.color = "#1f345a";  # jac:ignore[E1030]
                goal.style.fontSize = "14px";  # jac:ignore[E1030]
                goal.style.fontWeight = "600";  # jac:ignore[E1030]
                goal.style.lineHeight = "1.7";  # jac:ignore[E1030]
                goal.textContent = trimmedText(objectValue(selected, "goal", "")) or "No instructions yet.";  # jac:ignore[E1030]
                state["helpersPageDetail"].appendChild(goal);  # jac:ignore[E1099]
            }
        }

        state["helpersPageResults"].textContent = "";  # jac:ignore[E1099]
        if not selected {
            empty_results = document.createElement("div");
            empty_results.style.color = "#526885";  # jac:ignore[E1030]
            empty_results.style.fontSize = "13px";  # jac:ignore[E1030]
            empty_results.style.lineHeight = "1.6";  # jac:ignore[E1030]
            empty_results.textContent = "Select a helper to see its recent local run results.";  # jac:ignore[E1030]
            state["helpersPageResults"].appendChild(empty_results);  # jac:ignore[E1099]
            return;
        }

        results = helperResultsFor(objectValue(selected, "id", ""));
        if len(results) == 0 {
            empty_results = document.createElement("div");
            empty_results.style.padding = "14px";  # jac:ignore[E1030]
            empty_results.style.borderRadius = "16px";  # jac:ignore[E1030]
            empty_results.style.border = "1px dashed rgba(88, 116, 173, 0.22)";  # jac:ignore[E1030]
            empty_results.style.background = "rgba(244, 247, 255, 0.76)";  # jac:ignore[E1030]
            empty_results.style.color = "#526885";  # jac:ignore[E1030]
            empty_results.style.fontSize = "13px";  # jac:ignore[E1030]
            empty_results.style.lineHeight = "1.6";  # jac:ignore[E1030]
            empty_results.textContent = "No runs yet. Run this helper from TASKS or use Run Task here to refresh the latest status.";  # jac:ignore[E1030]
            state["helpersPageResults"].appendChild(empty_results);  # jac:ignore[E1099]
            return;
        }

        for result in results.slice(0, 6) {
            card = document.createElement("div");
            card.style.display = "flex";  # jac:ignore[E1030]
            card.style.flexDirection = "column";  # jac:ignore[E1030]
            card.style.gap = "10px";  # jac:ignore[E1030]
            card.style.padding = "14px";  # jac:ignore[E1030]
            card.style.borderRadius = "18px";  # jac:ignore[E1030]
            card.style.border = "1px solid rgba(88, 116, 173, 0.12)";  # jac:ignore[E1030]
            card.style.background = "#ffffff";  # jac:ignore[E1030]

            top_row = document.createElement("div");
            top_row.style.display = "flex";  # jac:ignore[E1030]
            top_row.style.justifyContent = "space-between";  # jac:ignore[E1030]
            top_row.style.alignItems = "center";  # jac:ignore[E1030]
            top_row.style.gap = "10px";  # jac:ignore[E1030]

            timestamp = document.createElement("div");
            timestamp.style.color = "#183154";  # jac:ignore[E1030]
            timestamp.style.fontSize = "12px";  # jac:ignore[E1030]
            timestamp.style.fontWeight = "800";  # jac:ignore[E1030]
            timestamp.textContent = str(objectValue(result, "timestamp", ""));  # jac:ignore[E1030]

            status = document.createElement("div");
            status.style.color = "#355ca3";  # jac:ignore[E1030]
            status.style.fontSize = "11px";  # jac:ignore[E1030]
            status.style.fontWeight = "800";  # jac:ignore[E1030]
            status.style.letterSpacing = "0.03em";  # jac:ignore[E1030]
            status.style.textTransform = "uppercase";  # jac:ignore[E1030]
            status.textContent = str(objectValue(result, "status", "recorded"));  # jac:ignore[E1030]

            top_row.appendChild(timestamp);  # jac:ignore[E1030]
            top_row.appendChild(status);  # jac:ignore[E1030]

            mode = document.createElement("div");
            mode.style.color = "#526885";  # jac:ignore[E1030]
            mode.style.fontSize = "12px";  # jac:ignore[E1030]
            mode.style.fontWeight = "700";  # jac:ignore[E1030]
            mode.textContent = "Mode: " + str(objectValue(result, "mode", "renderer_local_demo"));  # jac:ignore[E1030]

            summary = document.createElement("div");
            summary.style.color = "#1f345a";  # jac:ignore[E1030]
            summary.style.fontSize = "13px";  # jac:ignore[E1030]
            summary.style.lineHeight = "1.6";  # jac:ignore[E1030]
            summary.textContent = str(objectValue(result, "summary", ""));  # jac:ignore[E1030]

            card.appendChild(top_row);  # jac:ignore[E1030]
            card.appendChild(mode);  # jac:ignore[E1030]
            card.appendChild(summary);  # jac:ignore[E1030]

            note_items = objectValue(result, "notes", []) or [];
            if len(note_items) > 0 {
                notes_list = document.createElement("ul");
                notes_list.style.margin = "0";  # jac:ignore[E1030]
                notes_list.style.paddingLeft = "18px";  # jac:ignore[E1030]
                notes_list.style.color = "#526885";  # jac:ignore[E1030]
                notes_list.style.fontSize = "12px";  # jac:ignore[E1030]
                notes_list.style.lineHeight = "1.6";  # jac:ignore[E1030]
                for note in note_items {
                    note_item = document.createElement("li");
                    note_item.textContent = str(note or "");  # jac:ignore[E1030]
                    notes_list.appendChild(note_item);  # jac:ignore[E1030]
                }
                card.appendChild(notes_list);  # jac:ignore[E1030]
            }

            state["helpersPageResults"].appendChild(card);  # jac:ignore[E1099]
        }
    }

    """R: Keep the Claw transcript area readable from renderer-local state.
    M: Formats user/system entries into compact text blocks and keeps the newest message visible.
    E: Missing transcript DOM or empty message lists fall back to a truthful default description.
    """;
    def renderClawTranscript() -> None {
        if not state["clawTranscript"] {
            return;
        }

        rendered = "";
        for ent in state["clawTranscriptMessages"] {
            role = str(objectValue(ent, "role", "system"));
            prefix = "Claw";
            if role == "user" {
                prefix = "You";
            } elif role == "error" {
                prefix = "Claw error";
            }

            entry_text = trimmedText(objectValue(ent, "text", ""));
            if not entry_text {
                continue;
            }

            stamp = trimmedText(objectValue(ent, "stamp", ""));
            if rendered {
                rendered = rendered + "\n\n";
            }

            header = prefix;
            if stamp {
                header = header + " | " + stamp;
            }
            rendered = rendered + header + "\n" + entry_text;
        }

        if not rendered {
            rendered = (
                "Claw is ready.\n" +
                "\n" +
                "Type the task below.\n" +
                "Plan now uses the active live trace.\n" +
                "Save draft keeps the text in this browser shell only."
            );
        }

        state["clawTranscript"].textContent = rendered;  # jac:ignore[E1099]
        state["clawTranscript"].scrollTop = state["clawTranscript"].scrollHeight;  # jac:ignore[E1099]
    }

    """R: Sync the Claw controls with renderer-local draft and loading state.
    M: Updates status text, button labels, disabled states, and draft textarea contents.
    E: Missing DOM nodes are ignored so the shell can still boot without the Claw block.
    """;
    def syncClawUi() -> None {
        syncTasksPanelUi();
        syncTaskPanelTabsUi();
        syncShellViewUi();
        syncTaskCreateUi();
        if state["clawDraftInput"] and state["clawDraftInput"].value != state["clawDraft"] {  # jac:ignore[E1099]
            state["clawDraftInput"].value = state["clawDraft"];  # jac:ignore[E1099]
        }
        if state["clawPlanBtn"] {
            state["clawPlanBtn"].disabled = state["clawIsPlanning"] or not hasClawDraft();  # jac:ignore[E1099]
            state["clawPlanBtn"].textContent = "Planning..." if state["clawIsPlanning"] else "Plan now";  # jac:ignore[E1099]
            state["clawPlanBtn"].title = "Planning from the active live trace." if state["clawIsPlanning"] else (  # jac:ignore[E1001,E1099]
                "Enter a task first." if not hasClawDraft() else (
                    "Start Trace, then use Plan now." if not state["activeSessionId"] else "Compile and plan from the active live trace."
                )
            );
        }
        if state["clawSaveDraftBtn"] {
            state["clawSaveDraftBtn"].disabled = state["clawIsPlanning"] or not hasClawDraft();  # jac:ignore[E1099]
            state["clawSaveDraftBtn"].title = "Planning is in progress." if state["clawIsPlanning"] else (  # jac:ignore[E1001,E1099]
                "Enter a task first." if not hasClawDraft() else "Save this draft in the current browser shell session."
            );
        }
        if state["clawStatus"] {
            state["clawStatus"].textContent = str(trimmedText(state["clawStatusText"]) or defaultClawStatus());  # jac:ignore[E1099]
        }
        syncHelperBuilderUi();
        renderHelperList();
        syncTaskRunComposerUi();
        renderHelpersWorkspace();
        renderClawTranscript();
    }

    def setClawStatus(message: any) -> None {
        state["clawStatusText"] = trimmedText(message);
        syncClawUi();
    }

    """R: Append a bounded Claw transcript history inside renderer memory.
    M: Records role-tagged entries with a local timestamp and trims the transcript to recent messages.
    E: Blank messages are skipped so the panel never fills with empty transcript items.
    """;
    def appendClawTranscript(role: any, message: any) -> None {
        text = trimmedText(message);
        if not text {
            return;
        }

        state["clawTranscriptMessages"].push({  # jac:ignore[E1099]
            "role": str(role or "system"),
            "text": text,
            "stamp": Reflect.construct(Date, []).toLocaleTimeString()
        });

        if len(state["clawTranscriptMessages"]) > 32 {  # jac:ignore[E1053]
            state["clawTranscriptMessages"] = state["clawTranscriptMessages"].slice(len(state["clawTranscriptMessages"]) - 32);  # jac:ignore[E1053,E1099]
        }
        renderClawTranscript();
    }

    def clawPlanInputs(draftText: str) -> any {
        if not draftText {
            return {};
        }
        return {"query": draftText};
    }

    """R: Turn a successful planner payload into an honest, readable transcript ent.
    M: Pulls the current workflow id, step count, and unresolved inputs into a short plain-language summary.
    E: Missing fields degrade to stable placeholders instead of leaving the transcript blank.
    """;
    def formatClawPlanSummary(result: any) -> str {
        unresolved = objectValue(result, "unresolved_inputs", []) or [];
        workflow_id = trimmedText(objectValue(result, "workflow_id", "")) or "unknown";
        step_count = str(objectValue(result, "step_count", 0));
        return (
            "Plan ready from the active live trace.\n" +
            "Workflow: " + workflow_id + "\n" +
            "Steps: " + step_count + "\n" +
            "Needs input: " + commaList(unresolved)
        );
    }

    def syncLayerStateLabels() -> None {
        if state["sessionIdLabel"] {
            state["sessionIdLabel"].textContent = state["activeSessionId"] or "none";  # jac:ignore[E1099]
        }
        if state["workflowIdLabel"] {
            state["workflowIdLabel"].textContent = state["activeWorkflowId"] or "none";  # jac:ignore[E1099]
        }
    }

    def traceIsRecording() -> bool {
        return state["traceLifecycleState"] == "recording";
    }

    def traceReadyForCompile() -> bool {
        return state["traceLifecycleState"] == "stopped" and trimmedText(state["activeSessionId"]) != "";
    }

    """R: Keep the manual layer flow aligned with the current trace lifecycle.
    M: Enables the correct buttons for start/stop/compile/plan and reveals the optional explanation step only after recording stops.
    E: Missing DOM nodes are ignored so the shell still boots if the layer panel is partially unavailable.
    """;
    def syncLayerFlowUi() -> None {
        is_recording = traceIsRecording();
        ready_to_compile = traceReadyForCompile();
        has_workflow = trimmedText(state["activeWorkflowId"]) != "";

        if state["startTraceBtn"] {
            state["startTraceBtn"].disabled = is_recording;  # jac:ignore[E1099]
            state["startTraceBtn"].textContent = "Recording..." if is_recording else "Start Trace";  # jac:ignore[E1099]
        }
        if state["stopTraceBtn"] {
            state["stopTraceBtn"].disabled = not is_recording;  # jac:ignore[E1099]
        }
        if state["compileTraceBtn"] {
            state["compileTraceBtn"].disabled = not ready_to_compile;  # jac:ignore[E1099]
            state["compileTraceBtn"].textContent = "Compile Trace";  # jac:ignore[E1099]
            state["compileTraceBtn"].title = (  # jac:ignore[E1001,E1099]
                "Stop the trace first. Then you can compile with the optional explanation."
                if not ready_to_compile else
                "Compile the stopped trace" + (" with the explanation draft." if trimmedText(state["workflowExplanationDraft"]) else ".")
            );
        }
        if state["planWorkflowBtn"] {
            state["planWorkflowBtn"].disabled = not has_workflow;  # jac:ignore[E1099]
        }
        if state["workflowExplanationPanel"] {
            state["workflowExplanationPanel"].style.display = "flex" if ready_to_compile else "none";  # jac:ignore[E1099]
        }
        if state["workflowExplanationInput"] {
            if state["workflowExplanationInput"].value != state["workflowExplanationDraft"] {  # jac:ignore[E1099]
                state["workflowExplanationInput"].value = state["workflowExplanationDraft"];  # jac:ignore[E1099]
            }
            state["workflowExplanationInput"].disabled = not ready_to_compile;  # jac:ignore[E1099]
        }
    }

    async def syncLlmRuntimeStatus() -> None {
        api = browserAPI();
        if not state["llmRuntimeLabel"] {
            return;
        }
        if not api or not api.getLlmStatus {
            state["llmRuntimeLabel"].textContent = "bridge-offline";  # jac:ignore[E1099]
            appendLayerLog("LLM runtime status unavailable: browser bridge missing.");
            return;
        }

        try {
            runtime = await api.getLlmStatus();
            active = bool(objectValue(runtime, "active", False));
            provider = str(objectValue(runtime, "provider", "kimi") or "kimi");
            transport = str(objectValue(runtime, "transport", "") or "");
            model = str(objectValue(runtime, "model", "") or "");
            reason = str(objectValue(runtime, "reason", "") or "");
            lowered_reason = reason.toLowerCase();  # jac:ignore[E1030]

            if active {
                state["llmRuntimeLabel"].textContent = provider + " on";  # jac:ignore[E1099]
                appendLayerLog(
                    "LLM runtime active" +
                    (" via " + transport if transport else "") +
                    (" (" + model + ")" if model else "")
                );
            } else {
                if lowered_reason.includes("ollama pull") or (lowered_reason.includes("model `") and lowered_reason.includes("is not installed")) {  # jac:ignore[E1032]
                    state["llmRuntimeLabel"].textContent = "needs-model";  # jac:ignore[E1099]
                } elif lowered_reason.includes("local ollama is not installed") or (lowered_reason.includes("ollama") and lowered_reason.includes("not installed")) {  # jac:ignore[E1032]
                    state["llmRuntimeLabel"].textContent = "needs-install";  # jac:ignore[E1099]
                } elif lowered_reason.includes("kimi login") or lowered_reason.includes("not logged in") or lowered_reason.includes("llm not set") {  # jac:ignore[E1032]
                    state["llmRuntimeLabel"].textContent = "needs-login";  # jac:ignore[E1099]
                } elif lowered_reason.includes("llm_api_key") or lowered_reason.includes("placeholder") or lowered_reason.includes("missing") {  # jac:ignore[E1032]
                    state["llmRuntimeLabel"].textContent = "needs-key";  # jac:ignore[E1099]
                } elif lowered_reason.includes("disabled") {  # jac:ignore[E1032]
                    state["llmRuntimeLabel"].textContent = "disabled";  # jac:ignore[E1099]
                } else {
                    state["llmRuntimeLabel"].textContent = "inactive";  # jac:ignore[E1099]
                }
                appendLayerLog("LLM runtime unavailable" + (": " + reason if reason else "."));
            }
        } except Exception as err {
            state["llmRuntimeLabel"].textContent = "error";  # jac:ignore[E1099]
            appendLayerLog("LLM runtime status check failed: " + str(err.message or err));  # jac:ignore[E1030]
        }
    }

    def setSiteBadgeState(label: any, stateKey: any = "secure") -> None {
        if not state["siteBadge"] {
            return;
        }
        state["siteBadge"].textContent = str(label or "").trim() or "Secure";  # jac:ignore[E1030,E1099]
        state["siteBadge"].dataset.state = str(stateKey or "secure");  # jac:ignore[E1099]
    }

    def nextTabId() -> str {
        state["tabSeed"] = state["tabSeed"] + 1;
        return "tab_" + str(Date.now()) + "_" + str(state["tabSeed"]);
    }

    def getTabById(tabId: any) -> any {
        for tab in state["tabs"] {
            if tab["id"] == tabId {
                return tab;
            }
        }
        return None;
    }

    def getActiveTab() -> any {
        return getTabById(state["activeTabId"]);
    }

    def getActiveWebview() -> any {
        tab = getActiveTab();
        if tab {
            return tab["webview"];
        }
        return None;
    }

    def normalizeClientSide(rawValue: any) -> str {
        cleaned = str(rawValue or "").trim();  # jac:ignore[E1030]
        if not cleaned {
            return DEFAULT_URL;
        }

        lowered = cleaned.toLowerCase();  # jac:ignore[E1032]
        if lowered.startsWith("http://") or lowered.startsWith("https://") {  # jac:ignore[E1032]
            return cleaned;  # jac:ignore[E1002]
        }

        looksLikeDomain = cleaned.includes(".") and not cleaned.includes(" ");  # jac:ignore[E1032]
        if looksLikeDomain {
            return "https://" + cleaned;  # jac:ignore[E1055]
        }

        return SEARCH_URL + encodeURIComponent(cleaned);
    }

    async def safeNormalizeUrl(rawValue: any) -> str {
        api = browserAPI();
        if api and api.normalizeUrl {
            try {
                viaJac = await api.normalizeUrl(rawValue);
                if viaJac {
                    return viaJac;
                }
            } except Exception {
            }
        }
        return normalizeClientSide(rawValue);
    }

    async def safeGetHomeUrl() -> str {
        if state["homeUrlCache"] {
            return state["homeUrlCache"];  # jac:ignore[E1002]
        }
        if state["homeUrlPromise"] {
            return await state["homeUrlPromise"];  # jac:ignore[E1002]
        }

        async def resolveHomeUrl() -> str {
            resolvedHome = DEFAULT_URL;
            api = browserAPI();
            if api and api.getHomeUrl {
                try {
                    home = await api.getHomeUrl();
                    if home {
                        resolvedHome = home;
                    }
                } except Exception {
                }
            }
            state["homeUrlCache"] = resolvedHome;
            return resolvedHome;
        }

        state["homeUrlPromise"] = resolveHomeUrl();
        try {
            return await state["homeUrlPromise"];  # jac:ignore[E1002]
        } finally {
            state["homeUrlPromise"] = None;
        }
    }

    async def safeGetWebviewPreloadUrl() -> str {
        api = browserAPI();
        if api and api.getWebviewPreloadUrl {
            try {
                value = await api.getWebviewPreloadUrl();
                return str(value or "");
            } except Exception {
            }
        }
        return "";
    }

    async def recordObservationEvent(eventPayload: any) -> None {
        if not state["activeSessionId"] {
            return;
        }

        api = browserAPI();
        if not api or not api.layersEvent {
            return;
        }

        payload = {
            "type": str(eventPayload["type"] or "unknown"),
            "url": str(eventPayload["url"] or ""),
            "target": eventPayload["target"] or {},
            "value": str(eventPayload["value"] or "") if "value" in eventPayload else "",
            "meta": eventPayload["meta"] or {}
        };
        copyObservationSections(eventPayload, payload);
        if not objectValue(payload["meta"], "tab_id", "") {
            payload["meta"]["tab_id"] = state["activeTabId"] or "";
        }

        try {
            result = await api.layersEvent({
                "session_id": state["activeSessionId"],
                "event": payload
            });
            if result and objectValue(result, "ok", True) == False {
                appendLayerLog("Observation append failed: " + str(objectValue(result, "error", "unknown error")));
            }
        } except Exception as err {
            appendLayerLog("Observation append threw: " + str(err.message or err));  # jac:ignore[E1030]
        }
    }

    """R: Compile the current live trace into the active workflow slot.
    M: Validates the active session, calls the existing compile IPC path, updates workflow labels, and logs outcomes.
    E: Missing sessions, bridge methods, or thrown errors return `{ ok: false, error }` instead of crashing handlers.
    """;
    async def compileActiveTrace(explanationOverride: any = None, allowLiveTrace: any = False) -> any {
        if not state["activeSessionId"] {
            message = "Compile skipped: no session id.";
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }
        if not allowLiveTrace and not traceReadyForCompile() {
            message = "Compile skipped: stop the trace first, then add optional explanation.";
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }

        api = browserAPI();
        if not api or not api.layersCompile {
            message = "Compile failed: browser bridge unavailable.";
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }

        explanation_text = trimmedText(explanationOverride);
        if not explanation_text {
            explanation_text = trimmedText(state["workflowExplanationDraft"]);
        }

        compile_payload = {"session_id": state["activeSessionId"]};
        if explanation_text {
            compile_payload["user_explanation"] = explanation_text;
        }

        try {
            result = await api.layersCompile(compile_payload);
            if not result or objectValue(result, "ok", True) == False {
                message = "Compile failed: " + str(objectValue(result, "error", "unknown error"));
                appendLayerLog(message);
                return result or {"ok": False, "error": message};
            }

            state["activeWorkflowId"] = objectValue(result, "workflow_id", "") or "";
            syncLayerStateLabels();
            appendLayerLog(
                "Compiled workflow " + state["activeWorkflowId"] +  # jac:ignore[E1055]
                " (" + str(objectValue(result, "step_count", 0)) + " steps)" +
                (" using the explanation draft." if explanation_text else "")
            );
            compile_warnings = objectValue(result, "warnings", []) or [];
            if compile_warnings and typeof(compile_warnings.length) != "undefined" {  # jac:ignore[E1099]
                for warning in compile_warnings {
                    appendLayerLog("Compile warning: " + str(warning or ""));
                }
            }
            syncLayerFlowUi();
            return result;
        } except Exception as err {
            message = "Compile threw: " + str(err.message or err);  # jac:ignore[E1030]
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }
    }

    """R: Plan the currently compiled workflow through the existing live layer bridge.
    M: Calls the existing planner IPC route with optional runtime inputs and returns the raw planner payload.
    E: Missing workflow ids, bridge failures, or planner exceptions become structured `{ ok: false, error }` results.
    """;
    async def planActiveWorkflow(runInputs: any = {}) -> any {
        if not state["activeWorkflowId"] {
            message = "Plan skipped: no workflow id.";
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }

        payload_inputs = {};
        if runInputs and typeof(runInputs) == "object" {
            payload_inputs = runInputs;
        }

        api = browserAPI();
        if not api or not api.layersPlan {
            message = "Plan failed: browser bridge unavailable.";
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }

        try {
            result = await api.layersPlan({"workflow_id": state["activeWorkflowId"], "inputs": payload_inputs});
            if not result or objectValue(result, "ok", True) == False {
                message = "Plan failed: " + str(objectValue(result, "error", "unknown error"));
                appendLayerLog(message);
                return result or {"ok": False, "error": message};
            }

            unresolved = objectValue(result, "unresolved_inputs", []) or [];
            planned_id = str(objectValue(result, "workflow_id", ""));
            planned_steps = str(objectValue(result, "step_count", 0));
            unresolved_count = str(len(unresolved));
            planned_msg = "Planned " + planned_id + ": " + planned_steps + " steps, unresolved: " + unresolved_count;
            appendLayerLog(planned_msg);
            return result;
        } except Exception as err {
            message = "Plan threw: " + str(err.message or err);  # jac:ignore[E1030]
            appendLayerLog(message);
            return {"ok": False, "error": message};
        }
    }

    """R: Drive the Claw primary action without inventing backend behavior.
    M: Records the user draft locally, compiles the active live trace, and plans the compiled workflow with the draft as `query` when applicable.
    E: Empty drafts are ignored and missing live trace state is surfaced as an honest panel error.
    """;
    async def handleClawPlanNow() -> None {
        draft_text = trimmedText(state["clawDraft"]);
        if state["clawIsPlanning"] {
            return;
        }
        if not draft_text {
            appendClawTranscript("system", "Add a task before using Plan now.");
            setClawStatus("Add a task before using Plan now.");
            return;
        }

        appendClawTranscript("user", draft_text);
        state["clawLastSavedMessage"] = "";
        state["clawIsPlanning"] = True;
        state["clawLastPlanResult"] = None;
        setClawStatus("Planning from the active live trace...");

        try {
            if not state["activeSessionId"] {
                appendClawTranscript("error", "No active live trace yet. Start Trace, interact with the page, and then use Plan now again. Your draft is still here.");
                setClawStatus("No active trace. Start Trace, interact, then use Plan now.");
                return;
            }

            compile_result = await compileActiveTrace(draft_text, True);
            if not compile_result or objectValue(compile_result, "ok", True) == False {
                appendClawTranscript("error", "Plan could not continue because compile failed: " + str(objectValue(compile_result, "error", "unknown error")));
                setClawStatus("Plan blocked because compile failed.");
                return;
            }

            plan_result = await planActiveWorkflow(clawPlanInputs(draft_text));
            if not plan_result or objectValue(plan_result, "ok", True) == False {
                appendClawTranscript("error", "Plan failed: " + str(objectValue(plan_result, "error", "unknown error")));
                setClawStatus("Plan failed. Check the transcript for details.");
                return;
            }

            state["clawLastPlanResult"] = {
                "workflow_id": trimmedText(objectValue(plan_result, "workflow_id", "")),
                "step_count": objectValue(plan_result, "step_count", 0),
                "unresolved_inputs": objectValue(plan_result, "unresolved_inputs", []) or []
            };
            appendClawTranscript("system", formatClawPlanSummary(plan_result));
            setClawStatus("Plan ready from the live trace: " + (state["clawLastPlanResult"]["workflow_id"] or "workflow available"));  # jac:ignore[E1055]
        } finally {
            state["clawIsPlanning"] = False;
            syncClawUi();
        }
    }

    """R: Confirm a draft save without claiming persistence that does not exist yet.
    M: Keeps the draft in renderer memory, records a local confirmation, and surfaces it in the transcript/status.
    E: Empty drafts are ignored so the save affordance does not generate fake confirmations.
    """;
    def handleClawSaveDraft() -> None {
        draft_text = trimmedText(state["clawDraft"]);
        if state["clawIsPlanning"] {
            return;
        }
        if not draft_text {
            appendClawTranscript("system", "Add a task before using Save draft.");
            setClawStatus("Add a task before using Save draft.");
            return;
        }

        state["clawLastSavedMessage"] = "Draft saved in this browser shell at " + Reflect.construct(Date, []).toLocaleTimeString();  # jac:ignore[E1055]
        appendClawTranscript("system", "Draft saved in this browser shell only for the current renderer session.");
        setClawStatus(state["clawLastSavedMessage"]);
    }

    """R: Store one saved helper in renderer-local state for both quick-create and recorded-task flows.
    M: Normalizes helper metadata, updates selection/run state, and posts a compact local-only confirmation to the transcript.
    E: Empty specs degrade to stable defaults so local demo creation never claims persistence or backend execution.
    """;
    def saveHelperRecord(
        helper_name: any,
        helper_goal: any,
        helper_frequency: any,
        helper_spec: any,
        transcript_message: any,
        status_message: any
    ) -> None {
        final_name = trimmedText(helper_name) or "Recorded Browser Task";
        final_goal = trimmedText(helper_goal) or "Follow the locally recorded browser workflow.";
        final_frequency = normalizedHelperFrequency(helper_frequency);
        helper = {
            "id": nextHelperId(),
            "name": final_name,
            "goal": final_goal,
            "frequency": final_frequency,
            "frequencyLabel": helperFrequencyLabel(final_frequency),
            "kind": objectValue(helper_spec, "type", "general"),
            "readOnly": True,
            "createdAt": localTimestamp(),
            "spec": helper_spec
        };
        state["helpers"].push(helper);  # jac:ignore[E1099]
        state["selectedHelperId"] = helper["id"];
        state["selectedTaskRunHelperId"] = helper["id"];
        state["activeTaskPanelTab"] = "run";
        state["taskRunOverrideText"] = "";
        state["helperEditMode"] = False;
        state["helperEditGoalDraft"] = final_goal;

        appendClawTranscript("system", trimmedText(transcript_message) or ("Helper created: " + final_name));
        setClawStatus(trimmedText(status_message) or ("Helper ready: " + final_name + " (" + helper["frequencyLabel"] + ")"));  # jac:ignore[E1055]
    }

    def taskTraceEventCount(traceData: any) -> int {
        events = objectValue(traceData, "events", []) or [];
        try {
            return len(events);
        } except Exception {
            return 0;
        }
    }

    def recordedTaskSourceUrl(traceData: any) -> str {
        return trimmedText(objectValue(traceData, "source_url", ""));
    }

    def recordedTaskHost(traceData: any) -> str {
        source_url = recordedTaskSourceUrl(traceData);
        if not source_url {
            return "";
        }
        try {
            parsed = Reflect.construct(URL, [source_url]);
            return trimmedText(parsed.hostname or "");
        } except Exception {
            return "";
        }
    }

    """R: Generate a compact saved-task title from the recorded session and any extra user context.
    M: Prefers the user's added context, then falls back to trace metadata, and trims the result for list readability.
    E: Empty context and sparse traces fall back to a stable generic task title.
    """;
    def buildRecordedTaskName(traceData: any, contextText: any) -> str {
        source_text = trimmedText(contextText);
        if not source_text {
            source_text = trimmedText(objectValue(traceData, "title", ""));
        }
        if not source_text {
            source_text = trimmedText(objectValue(objectValue(traceData, "latest_semantic", {}), "title", ""));
        }
        if not source_text {
            host = recordedTaskHost(traceData);
            if host {
                source_text = "Task for " + host;
            }
        }
        if not source_text {
            source_text = "Recorded Browser Task";
        }

        clean_text = source_text.replace("\n", " ").replace("\r", " ").replace(":", " ").replace(".", " ");
        words = [];
        for raw_word in clean_text.split(" ") {
            word = trimmedText(raw_word);
            if not word {
                continue;
            }
            words.push(word);  # jac:ignore[E1030]
            if len(words) >= 5 {
                break;
            }
        }

        final_name = " ".join(words) if len(words) > 0 else "Recorded Browser Task";
        return final_name if len(final_name) <= 56 else final_name.slice(0, 53) + "...";  # jac:ignore[E1055,E1099]
    }

    """R: Assemble local saved-task instructions from the captured trace and the user's post-recording context.
    M: Blends the typed context with trace/session metadata and compiled workflow counts into a skimmable task brief.
    E: Sparse traces still produce a usable goal so Generate Task never depends on hidden fields being present.
    """;
    def buildRecordedTaskGoal(traceData: any, contextText: any, compileResult: any) -> str {
        details = [];
        extra_context = trimmedText(contextText);
        if extra_context {
            details.push(extra_context);  # jac:ignore[E1030]
        }

        source_url = recordedTaskSourceUrl(traceData);
        if source_url {
            details.push("Use the recorded browser flow that started at " + source_url + ".");  # jac:ignore[E1030]
        }

        event_count = taskTraceEventCount(traceData);
        if event_count > 0 {
            details.push("The captured trace includes " + str(event_count) + " browser events.");  # jac:ignore[E1030]
        }

        compiled_steps = Number(objectValue(compileResult, "step_count", 0));
        compiled_inputs = Number(objectValue(compileResult, "input_count", 0));
        if compiled_steps > 0 {
            details.push(  # jac:ignore[E1030]
                "The local workflow compiler inferred " + str(compiled_steps) +
                " steps" + (" and " + str(compiled_inputs) + " inputs." if compiled_inputs > 0 else ".")
            );
        }

        details.push("Keep this as a renderer-local demo helper generated from the recorded task trace.");  # jac:ignore[E1030]
        return "\n".join(details);
    }

    """R: Fetch the stored trace payload for a stopped task recording.
    M: Calls the existing local get-trace bridge and returns the raw renderer-friendly result for downstream generation.
    E: Missing session ids, bridge gaps, and thrown errors become explicit `{ ok: false, error }` payloads.
    """;
    async def fetchRecordedTaskTrace(sessionId: any) -> any {
        final_session_id = trimmedText(sessionId);
        if not final_session_id {
            return {"ok": False, "error": "session_id is required"};
        }

        api = browserAPI();
        if not api or not api.layersGetTrace {
            return {"ok": False, "error": "browser bridge unavailable"};
        }

        try {
            result = await api.layersGetTrace({"session_id": final_session_id});
            if not result or objectValue(result, "ok", True) == False {
                return result or {"ok": False, "error": "trace not found"};
            }
            return result;
        } except Exception as err {
            return {"ok": False, "error": str(err.message or err)};  # jac:ignore[E1030]
        }
    }

    """R: Toggle TASKS create-mode recording without reviving the old planner surface.
    M: Starts or stops the existing live trace bridge, updates renderer-local create state, and focuses the next relevant control.
    E: Bridge failures and missing active sessions surface honest status text instead of pretending recording succeeded.
    """;
    async def handleTaskPanelRecordToggle() -> None {
        if state["taskCreateIsGenerating"] {
            return;
        }

        api = browserAPI();
        if not api or not api.layersStart or not api.layersStop {
            setClawStatus("Task recording is unavailable because the browser bridge is offline.");
            return;
        }

        if not state["taskRecordingActive"] {
            webview = getActiveWebview();
            url = DEFAULT_URL;
            if webview and webview.getURL() {
                url = webview.getURL();
            } elif state["addressInput"] and state["addressInput"].value {  # jac:ignore[E1099]
                url = state["addressInput"].value;  # jac:ignore[E1001,E1099]
            }

            try {
                result = await api.layersStart({"title": "Recorded Task", "url": url});
                if not result or objectValue(result, "ok", True) == False {
                    setClawStatus("Start recording failed: " + str(objectValue(result, "error", "unknown error")));
                    return;
                }
                state["activeSessionId"] = objectValue(result, "session_id", "") or "";
                state["activeWorkflowId"] = "";
                state["traceLifecycleState"] = "recording";
                state["workflowExplanationDraft"] = "";
                state["taskRecordingActive"] = True;
                state["recordedTaskSessionId"] = "";
                state["recordedTaskEventCount"] = 0;
                state["taskCreateContextText"] = "";
                syncLayerStateLabels();
                syncLayerFlowUi();
                setClawStatus("Recording task flow now. Browse normally, then click Stop.");
                syncClawUi();
                return;
            } except Exception as err {
                setClawStatus("Start recording threw: " + str(err.message or err));  # jac:ignore[E1030]
                return;
            }
        }

        active_session_id = trimmedText(state["activeSessionId"]);
        if not active_session_id {
            state["taskRecordingActive"] = False;
            setClawStatus("Stop recording skipped because there is no active session.");
            syncClawUi();
            return;
        }

        try {
            result = await api.layersStop({"session_id": active_session_id});
            if not result or objectValue(result, "ok", True) == False {
                setClawStatus("Stop recording failed: " + str(objectValue(result, "error", "unknown error")));
                return;
            }
            state["taskRecordingActive"] = False;
            state["recordedTaskSessionId"] = active_session_id;
            state["recordedTaskEventCount"] = Number(objectValue(result, "event_count", 0));
            state["activeWorkflowId"] = "";
            state["traceLifecycleState"] = "stopped";
            syncLayerStateLabels();
            syncLayerFlowUi();
            setClawStatus("Recording stopped. Add context, then generate the saved task.");
            syncClawUi();
            setTimeout(lambda {
                if state["taskCreateContextInput"] {
                    state["taskCreateContextInput"].focus();  # jac:ignore[E1099]
                }
            }, 10);
        } except Exception as err {
            setClawStatus("Stop recording threw: " + str(err.message or err));  # jac:ignore[E1030]
        }
    }

    """R: Turn a stopped recorded task into a renderer-local saved helper using the existing local compile path.
    M: Reads the stored trace, compiles it through the hidden runtime/compiler flow, then saves a helper built from the trace plus extra context.
    E: Missing recordings, compile failures, and bridge issues stop with truthful status messages instead of creating partial tasks.
    """;
    async def handleTaskPanelGenerate() -> None {
        recorded_session_id = trimmedText(state["recordedTaskSessionId"]);
        if state["taskRecordingActive"] {
            setClawStatus("Stop recording before generating the task.");
            return;
        }
        if not recorded_session_id {
            setClawStatus("Record a task first, then add context and generate it.");
            return;
        }
        if state["taskCreateIsGenerating"] {
            return;
        }

        state["taskCreateIsGenerating"] = True;
        syncClawUi();
        setClawStatus("Generating a saved task from the recorded trace...");

        try {
            trace_result = await fetchRecordedTaskTrace(recorded_session_id);
            if not trace_result or objectValue(trace_result, "ok", True) == False {
                setClawStatus("Generate task failed: " + str(objectValue(trace_result, "error", "trace unavailable")));
                return;
            }

            trace_data = objectValue(trace_result, "trace", {}) or {};
            state["activeSessionId"] = recorded_session_id;
            state["activeWorkflowId"] = "";
            syncLayerStateLabels();

            compile_result = await compileActiveTrace(state["taskCreateContextText"]);
            if not compile_result or objectValue(compile_result, "ok", True) == False {
                setClawStatus("Generate task failed because compile failed: " + str(objectValue(compile_result, "error", "unknown error")));
                return;
            }

            helper_name = buildRecordedTaskName(trace_data, state["taskCreateContextText"]);
            helper_goal = buildRecordedTaskGoal(trace_data, state["taskCreateContextText"], compile_result);
            helper_spec = buildHelperSpec(helper_name, helper_goal, "once");
            helper_spec["source"] = {
                "kind": "recorded_trace",
                "sessionId": recorded_session_id,
                "workflowId": trimmedText(objectValue(compile_result, "workflow_id", "")),
                "eventCount": taskTraceEventCount(trace_data)
            };

            saveHelperRecord(
                helper_name,
                helper_goal,
                "once",
                helper_spec,
                "Helper created from recorded task " + recorded_session_id + ".\n" +
                "Workflow: " + trimmedText(objectValue(compile_result, "workflow_id", "")) + "\n" +
                "Stored locally in this renderer session as a demo helper.",
                "Helper ready: " + helper_name + " (from recorded trace)"
            );

            state["taskCreateContextText"] = "";
            state["recordedTaskSessionId"] = "";
            state["recordedTaskEventCount"] = 0;
            closeHelperBuilder(False);
        } finally {
            state["taskCreateIsGenerating"] = False;
            syncClawUi();
        }
    }

    """R: Create one helper through the existing backend contract, then refresh and focus the new record in the renderer workspace.
    M: Validates the builder draft, calls the helper create IPC, closes the builder on success, and reloads helper state from the backend.
    E: Missing fields, bridge gaps, and backend errors keep the current draft intact and surface an honest status instead of partial UI state.
    """;
    async def handleHelperCreate() -> None {
        helper_name = trimmedText(state["helperDraftName"]);
        helper_goal = trimmedText(state["helperDraftGoal"]);
        helper_frequency = normalizedHelperFrequency(state["helperDraftFrequency"]);
        if not helper_name or not helper_goal {
            appendClawTranscript("system", "Add both a helper name and a helper goal before creating a helper.");
            setClawStatus("Add a helper name and goal to create a helper.");
            syncClawUi();
            return;
        }

        api = browserAPI();
        if not api or not api.helpersCreate {
            appendClawTranscript("error", "Create helper failed because the browser bridge is offline.");
            setClawStatus("Create helper failed because the browser bridge is offline.");
            return;
        }

        helper_spec = buildHelperSpec(helper_name, helper_goal, helper_frequency);
        setClawStatus("Creating helper " + helper_name + "...");
        try {
            create_result = await api.helpersCreate({
                "name": helper_name,
                "goal": helper_goal,
                "frequency": helper_frequency
            });
            if not create_result or objectValue(create_result, "ok", True) == False {
                error_text = str(objectValue(create_result, "error", "unknown error"));
                appendClawTranscript("error", "Create helper failed: " + error_text);
                setClawStatus("Create helper failed: " + error_text);
                return;
            }

            created_helper_id = trimmedText(objectValue(create_result, "helper_id", ""));
            if not created_helper_id {
                created_bundle = objectValue(create_result, "helper_bundle", {}) or {};
                created_helper_id = trimmedText(objectValue(objectValue(created_bundle, "helper", {}) or {}, "helper_id", ""));
            }

            closeHelperBuilder(True);
            refreshed = await refreshHelpersFromBackend(created_helper_id);
            if created_helper_id and findHelperById(created_helper_id) {
                selectHelper(created_helper_id);
            } else {
                ensureSelectedHelper();
                syncClawUi();
            }

            appendClawTranscript(
                "system",
                "Helper created: " + helper_name + "\n" +
                "Type: " + str(objectValue(helper_spec, "type", "general")) + "\n" +
                "How often: " + helperFrequencyLabel(helper_frequency)
            );
            if refreshed {
                setClawStatus("Helper ready: " + helper_name + " (" + helperFrequencyLabel(helper_frequency) + ")");
            } else {
                setClawStatus("Helper created, but helper refresh failed.");
            }
        } except Exception as err {
            appendClawTranscript("error", "Create helper threw: " + str(err.message or err));  # jac:ignore[E1030]
            setClawStatus("Create helper threw: " + str(err.message or err));  # jac:ignore[E1030]
        }
    }

    def clearTaskRunOverride() -> None {
        state["taskRunOverrideText"] = "";
        syncClawUi();
    }

    """R: Launch the TASKS run flow and refresh the selected helper history after the backend acknowledges the run.
    M: Reads the run-tab selection and one-run guidance, forwards them to the shared helper-run path, and then clears the temporary override.
    E: Missing selections surface an honest status message instead of attempting a stale helper run.
    """;
    async def handleTaskPanelRun() -> None {
        helper = selectedTaskRunHelper();
        if not helper {
            setClawStatus("Select a saved task before running it.");
            return;
        }

        await handleHelperRunNow(objectValue(helper, "id", ""), state["taskRunOverrideText"], "tasks_panel");
        state["taskRunOverrideText"] = "";
        syncClawUi();
    }

    """R: Run one helper through the backend contract.
    M: Sends backend helpers through `helpers:run-once` and refreshes helper and run state after completion.
    E: Unknown ids, bridge gaps, and backend errors fail clearly without mutating the saved helper definition.
    """;
    async def handleHelperRunNow(helperId: any, runOverride: any = "", runSource: any = "helpers") -> None {
        helper = findHelperById(helperId);
        if not helper {
            return;
        }

        helper_name = trimmedText(objectValue(helper, "name", "Helper"));
        override_text = trimmedText(runOverride);
        state["selectedHelperId"] = str(objectValue(helper, "id", ""));
        state["selectedTaskRunHelperId"] = str(objectValue(helper, "id", ""));

        if trimmedText(objectValue(helper, "source", "")) != "backend" {
            appendClawTranscript(
                "error",
                "Run blocked for " + helper_name + ".\n" +
                "This helper is not linked to the backend."
            );
            setClawStatus(
                "Run blocked for " + helper_name + ". This helper is not linked to the backend."
            );
            return;
        }

        api = browserAPI();
        if not api or not api.helpersRunOnce {
            appendClawTranscript("error", "Run helper failed because the browser bridge is offline.");
            setClawStatus("Run helper failed because the browser bridge is offline.");
            return;
        }

        setClawStatus("Running helper " + helper_name + "...");
        try {
            run_result = await api.helpersRunOnce({
                "helper_id": objectValue(helper, "id", ""),
                "browser_session_id": trimmedText(state["activeSessionId"]),
                "run_goal_override": override_text,
                "browser_state_hint": currentBrowserStateHint()
            });
            if not run_result or objectValue(run_result, "ok", True) == False {
                error_text = str(objectValue(run_result, "error", "unknown error"));
                appendClawTranscript("error", "Run helper failed: " + error_text);
                setClawStatus("Run helper failed: " + error_text);
                return;
            }

            await refreshHelpersFromBackend(objectValue(helper, "id", ""));
            await refreshHelperRunsFromBackend(objectValue(helper, "id", ""));
            if findHelperById(objectValue(helper, "id", "")) {
                selectHelper(objectValue(helper, "id", ""));
            }

            run_record = objectValue(run_result, "run", {}) or {};
            run_status = trimmedText(objectValue(run_record, "status", "")) or "unknown";
            run_summary = trimmedText(objectValue(run_record, "summary", "")) or "No summary returned.";
            appendClawTranscript(
                "system",
                "Helper run finished for " + helper_name + ".\n" +
                "Status: " + run_status + "\n" +
                "Summary: " + run_summary
            );
            setClawStatus(
                "Latest run: " + run_status +
                (" | " + helperGoalPreview(run_summary, 140) if run_summary else "")
            );
        } except Exception as err {
            appendClawTranscript("error", "Run helper threw: " + str(err.message or err));  # jac:ignore[E1030]
            setClawStatus("Run helper threw: " + str(err.message or err));  # jac:ignore[E1030]
        }
    }

    def setTabTitle(tab: any, titleText: any) -> None {
        finalTitle = str(titleText or "").trim() or "New Tab";  # jac:ignore[E1030]
        tab["title"] = finalTitle;
        tab["titleNode"].textContent = finalTitle;
        tab["tabNode"].title = finalTitle;
    }

    def scheduleChromeStateSync() -> None {
        if state["chromeSyncFrame"] {
            return;
        }
        state["chromeSyncFrame"] = requestAnimationFrame(lambda {
            state["chromeSyncFrame"] = None;
            syncChromeState();
        });
    }

    def ensureTabVisible(tabNode: any) -> None {
        if not tabNode or not state["tabList"] {
            return;
        }

        tabLeft = tabNode.offsetLeft;
        tabRight = tabLeft + tabNode.offsetWidth;
        visibleLeft = state["tabList"].scrollLeft;  # jac:ignore[E1099]
        visibleRight = visibleLeft + state["tabList"].clientWidth;  # jac:ignore[E1055,E1099]

        if tabLeft < visibleLeft {
            state["tabList"].scrollLeft = Math.max(0, tabLeft - 16);  # jac:ignore[E1099]
            return;
        }

        if tabRight > visibleRight {
            state["tabList"].scrollLeft = Math.max(0, tabRight - state["tabList"].clientWidth + 16);  # jac:ignore[E1099]
        }
    }

    def syncChromeState() -> None {
        webview = getActiveWebview();
        if not webview {
            if state["addressInput"] {
                state["addressInput"].value = "";  # jac:ignore[E1099]
            }
            if state["backBtn"] {
                state["backBtn"].disabled = True;  # jac:ignore[E1099]
            }
            if state["forwardBtn"] {
                state["forwardBtn"].disabled = True;  # jac:ignore[E1099]
            }
            if state["reloadBtn"] {
                state["reloadBtn"].disabled = True;  # jac:ignore[E1099]
            }
            setSiteBadgeState("Secure", "secure");
            return;
        }

        currentUrl = webview.getURL();
        if currentUrl and state["addressInput"] {
            state["addressInput"].value = currentUrl;  # jac:ignore[E1099]
        }
        if currentUrl {
            if currentUrl.startsWith("https://") {
                setSiteBadgeState("Secure", "secure");
            } else {
                setSiteBadgeState("Open", "open");
            }
        }

        activeTab = getActiveTab();
        if activeTab {
            title = webview.getTitle() or activeTab["title"] or "New Tab";
            setTabTitle(activeTab, title);
            activeTab["url"] = currentUrl or activeTab["url"];
        }

        if state["backBtn"] {
            state["backBtn"].disabled = not webview.canGoBack();  # jac:ignore[E1099]
        }
        if state["forwardBtn"] {
            state["forwardBtn"].disabled = not webview.canGoForward();  # jac:ignore[E1099]
        }
        if state["reloadBtn"] {
            state["reloadBtn"].disabled = False;  # jac:ignore[E1099]
        }
    }

    def renderActiveTabState(activeId: any) -> None {
        active_view = "helpers" if state["activeShellView"] == "helpers" else "browser";
        rendered_browser = active_view == "browser";
        rendered_key = activeId if rendered_browser else "__helpers_hidden__";
        if state["renderedActiveTabId"] == rendered_key {
            return;
        }

        previousTab = None;
        previous_rendered_id = state["renderedActiveTabId"];
        if previous_rendered_id and previous_rendered_id != "__helpers_hidden__" {
            previousTab = getTabById(previous_rendered_id);
        }

        if previousTab {
            previousTab["tabNode"].classList.remove("active");
        }

        for tab in state["tabs"] {
            tab["webview"].classList.remove("active");
        }

        nextTab = None;
        if activeId {
            nextTab = getTabById(activeId);
        }
        if nextTab {
            nextTab["tabNode"].classList.add("active");
            if rendered_browser {
                nextTab["webview"].classList.add("active");
            }
        }

        state["renderedActiveTabId"] = rendered_key;
    }

    def activateTab(tabId: any, emitObservation: any = True) -> None {
        nextTab = getTabById(tabId);
        if not nextTab {
            return;
        }

        changed = state["activeTabId"] != tabId;
        state["activeTabId"] = tabId;
        renderActiveTabState(state["activeTabId"]);
        ensureTabVisible(nextTab["tabNode"]);
        scheduleChromeStateSync();

        if changed and emitObservation {
            recordObservationEvent({
                "type": "tab_switched",
                "url": nextTab["webview"].getURL() or nextTab["url"] or "",
                "target": {"role": "tab", "text": nextTab["title"] or "New Tab", "label": "tab_switch"},
                "meta": {"source": "chrome_tab", "tab_id": nextTab["id"]}
            });
        }
    }

    def closeTab(tabId: any, emitObservation: any = True) -> None {
        index = -1;
        position = 0;
        for tab in state["tabs"] {
            if tab["id"] == tabId {
                index = position;
                break;
            }
            position = position + 1;
        }
        if index < 0 {
            return;
        }

        tab = state["tabs"][index];
        wasActive = tab["id"] == state["activeTabId"];
        finalUrl = tab["webview"].getURL() or tab["url"] or "";

        tab["webview"].remove();
        tab["tabNode"].remove();
        state["tabs"].splice(index, 1);  # jac:ignore[E1099]

        if emitObservation {
            recordObservationEvent({
                "type": "tab_closed",
                "url": finalUrl,
                "target": {"role": "tab", "text": tab["title"] or "New Tab", "label": "tab_close"},
                "meta": {"source": "chrome_tab", "tab_id": tab["id"]}
            });
        }

        if len(state["tabs"]) == 0 {  # jac:ignore[E1053]
            addTab(DEFAULT_URL, {"activate": True, "emitObservation": False});
            return;
        }

        if wasActive {
            fallbackIndex = index - 1;
            if fallbackIndex < 0 {
                fallbackIndex = 0;
            }
            activateTab(state["tabs"][fallbackIndex]["id"], False);
        }
    }

    def attachWebviewEvents(tab: any) -> None {
        webview = tab["webview"];

        webview.addEventListener("did-start-loading", lambda {
            tab["tabNode"].classList.add("loading");
            if state["activeTabId"] == tab["id"] {
                startProgress();
            }
        });

        webview.addEventListener("did-stop-loading", lambda {
            tab["tabNode"].classList.remove("loading");
            if state["activeTabId"] == tab["id"] {
                finishProgress();
                scheduleChromeStateSync();
            }
        });

        webview.addEventListener("did-fail-load", lambda (event: any, code: any, description: any) {
            if code == -3 {
                return;
            }
            tab["tabNode"].classList.remove("loading");
            if state["activeTabId"] == tab["id"] {
                finishProgress();
                setSiteBadgeState("Error", "error");
                if description and state["addressInput"] {
                    state["addressInput"].value = "Failed: " + str(description);  # jac:ignore[E1099]
                }
            }
        });

        webview.addEventListener("did-navigate", lambda {
            tab["url"] = webview.getURL() or tab["url"];
            if state["activeTabId"] == tab["id"] {
                scheduleChromeStateSync();
            }
            recordObservationEvent({
                "type": "navigate",
                "url": webview.getURL() or "",
                "target": {"role": "document", "label": "page_navigation", "text": tab["title"] or ""},
                "meta": {"source": "webview", "tab_id": tab["id"]}
            });
        });

        webview.addEventListener("did-navigate-in-page", lambda {
            tab["url"] = webview.getURL() or tab["url"];
            if state["activeTabId"] == tab["id"] {
                scheduleChromeStateSync();
            }
        });

        webview.addEventListener("page-title-updated", lambda {
            setTabTitle(tab, webview.getTitle() or "New Tab");
            if state["activeTabId"] == tab["id"] {
                scheduleChromeStateSync();
            }
        });

        webview.addEventListener("dom-ready", lambda {
            if state["activeTabId"] == tab["id"] {
                scheduleChromeStateSync();
            }
        });

        webview.addEventListener("ipc-message", lambda (event: any) {
            if event.channel != "observation:event" {
                return;
            }
            payload = {};
            if event.args and len(event.args) > 0 {
                payload = event.args[0] or {};
            }
            if not payload or typeof(payload) != "object" {
                return;
            }
            forwardObservationPayload(tab, payload);
        });
    }

    def addTab(initialUrl: any, options: any = {}) -> any {
        activateNew = objectValue(options, "activate", True);
        emitObservation = objectValue(options, "emitObservation", True);
        url = str(initialUrl or "").trim() or DEFAULT_URL;  # jac:ignore[E1030]

        tab = {
            "id": nextTabId(),
            "title": "New Tab",
            "url": url,
            "tabNode": document.createElement("div"),
            "titleNode": document.createElement("span"),
            "closeNode": document.createElement("button"),
            "webview": document.createElement("webview")
        };

        tab["tabNode"].className = "tab";  # jac:ignore[E1099]
        tab["tabNode"].dataset.tabId = tab["id"];  # jac:ignore[E1099]

        dotNode = document.createElement("span");
        dotNode.className = "tab-dot";  # jac:ignore[E1030]

        tab["titleNode"].className = "tab-title";  # jac:ignore[E1099]
        tab["titleNode"].textContent = "New Tab";  # jac:ignore[E1099]
        tab["tabNode"].title = "New Tab";  # jac:ignore[E1001,E1099]

        tab["closeNode"].className = "tab-close";  # jac:ignore[E1099]
        tab["closeNode"].type = "button";  # jac:ignore[E1099]
        tab["closeNode"].title = "Close Tab";  # jac:ignore[E1001,E1099]
        tab["closeNode"].textContent = "X";  # jac:ignore[E1099]

        tab["tabNode"].appendChild(dotNode);  # jac:ignore[E1099]
        tab["tabNode"].appendChild(tab["titleNode"]);  # jac:ignore[E1099]
        tab["tabNode"].appendChild(tab["closeNode"]);  # jac:ignore[E1099]

        tab["webview"].className = "browser-view";  # jac:ignore[E1099]
        tab["webview"].dataset.tabId = tab["id"];  # jac:ignore[E1099]
        tab["webview"].setAttribute("allowpopups", "");  # jac:ignore[E1099]
        tab["webview"].setAttribute("src", url);  # jac:ignore[E1099]
        if state["webviewPreloadUrl"] {
            tab["webview"].setAttribute("preload", state["webviewPreloadUrl"]);  # jac:ignore[E1099]
        }

        tab["tabNode"].addEventListener("click", lambda {  # jac:ignore[E1099]
            activateTab(tab["id"], True);
        });

        tab["closeNode"].addEventListener("click", lambda (event: any) {  # jac:ignore[E1099]
            event.stopPropagation();
            closeTab(tab["id"], True);
        });

        attachWebviewEvents(tab);

        state["tabs"].push(tab);  # jac:ignore[E1099]
        state["tabList"].appendChild(tab["tabNode"]);  # jac:ignore[E1099]
        state["viewport"].appendChild(tab["webview"]);  # jac:ignore[E1099]

        if activateNew {
            activateTab(tab["id"], False);
        }

        if emitObservation {
            recordObservationEvent({
                "type": "tab_created",
                "url": url,
                "target": {"role": "tab", "text": "New Tab", "label": "new_tab"},
                "meta": {"source": "chrome_tab", "tab_id": tab["id"]}
            });
        }

        return tab;
    }

    def loadInActiveTab(url: any) -> None {
        webview = getActiveWebview();
        tab = getActiveTab();
        if not webview or not tab or not url {
            return;
        }
        tab["url"] = url;
        webview.setAttribute("src", url);
    }

    async def navigateFromInput(rawValue: any) -> None {
        webview = getActiveWebview();
        if not webview {
            return;
        }

        try {
            startProgress();
            fallback = webview.getURL() or DEFAULT_URL;
            normalized = await safeNormalizeUrl(rawValue);
            recordObservationEvent({
                "type": "input",
                "url": fallback,
                "target": {"label": "address_bar", "name": "address", "role": "textbox", "type": "text"},
                "value": str(rawValue or ""),
                "meta": {"source": "omnibox", "tab_id": state["activeTabId"]}
            });
            loadInActiveTab(normalized or fallback);
        } except Exception {
            finishProgress();
            appendLayerLog("Navigation failed for active tab.");
        }
    }

    state["navForm"].addEventListener("submit", lambda (event: any) {  # jac:ignore[E1099]
        event.preventDefault();
        navigateFromInput(state["addressInput"].value);  # jac:ignore[E1099]
    });

    state["goBtn"].addEventListener("click", lambda (event: any) {  # jac:ignore[E1099]
        event.preventDefault();
        navigateFromInput(state["addressInput"].value);  # jac:ignore[E1099]
    });

    state["homeBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        async def handle {
            webview = getActiveWebview();
            if not webview {
                return;
            }
            homeUrl = await safeGetHomeUrl();
            recordObservationEvent({
                "type": "click",
                "url": webview.getURL() or "",
                "target": {"text": "Home", "label": "home_button", "role": "button"},
                "meta": {"source": "chrome_button", "tab_id": state["activeTabId"], "request_url": homeUrl}
            });
            startProgress();
            loadInActiveTab(homeUrl);
        }
        handle();
    });

    state["backBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        webview = getActiveWebview();
        if not webview or not webview.canGoBack() {
            return;
        }
        recordObservationEvent({
            "type": "click",
            "url": webview.getURL() or "",
            "target": {"text": "Back", "label": "back_button", "role": "button"},
            "meta": {"source": "chrome_button", "tab_id": state["activeTabId"]}
        });
        startProgress();
        webview.goBack();
    });

    state["forwardBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        webview = getActiveWebview();
        if not webview or not webview.canGoForward() {
            return;
        }
        recordObservationEvent({
            "type": "click",
            "url": webview.getURL() or "",
            "target": {"text": "Forward", "label": "forward_button", "role": "button"},
            "meta": {"source": "chrome_button", "tab_id": state["activeTabId"]}
        });
        startProgress();
        webview.goForward();
    });

    state["reloadBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        webview = getActiveWebview();
        if not webview {
            return;
        }
        recordObservationEvent({
            "type": "click",
            "url": webview.getURL() or "",
            "target": {"text": "Reload", "label": "reload_button", "role": "button"},
            "meta": {"source": "chrome_button", "tab_id": state["activeTabId"]}
        });
        startProgress();
        webview.reload();
    });

    state["newTabBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        async def openTab {
            homeUrl = await safeGetHomeUrl();
            addTab(homeUrl, {"activate": True, "emitObservation": True});
        }
        openTab();
    });

    state["minBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        async def handle {
            api = browserAPI();
            if api and api.minimizeWindow {
                await api.minimizeWindow();
            }
        }
        handle();
    });

    state["maxBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        async def handle {
            api = browserAPI();
            if api and api.toggleMaximizeWindow {
                await api.toggleMaximizeWindow();
            }
        }
        handle();
    });

    state["closeBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
        async def handle {
            api = browserAPI();
            if api and api.closeWindow {
                await api.closeWindow();
            }
        }
        handle();
    });

    if state["showBrowserViewBtn"] {
        state["showBrowserViewBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            setShellView("browser");
        });
    }

    if state["showHelpersViewBtn"] {
        state["showHelpersViewBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            setShellView("helpers");
        });
    }

    if state["toggleLayersBtn"] {
        state["toggleLayersBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            state["tasksPanelOpen"] = not state["tasksPanelOpen"];
            syncTasksPanelUi();
        });
    }

    bookmarkButtons = document.querySelectorAll(".bookmark-item[data-nav-url]");
    for bookmarkButton in bookmarkButtons {  # jac:ignore[E1022]
        bookmarkButton.addEventListener("click", lambda (event: any) {  # jac:ignore[E1032]
            button = event.currentTarget;
            url = button.dataset.navUrl or "";
            webview = getActiveWebview();
            if not url or not webview {
                return;
            }
            recordObservationEvent({
                "type": "click",
                "url": webview.getURL() or "",
                "target": {"text": str(button.textContent or "").trim() or "Shortcut", "label": "bookmark_shortcut", "role": "link"},  # jac:ignore[E1030]
                "meta": {"source": "bookmark_bar", "tab_id": state["activeTabId"], "request_url": url}
            });
            startProgress();
            loadInActiveTab(url);
        });
    }

    if state["startTraceBtn"] {
        state["startTraceBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                webview = getActiveWebview();
                url = DEFAULT_URL;
                if webview and webview.getURL() {
                    url = webview.getURL();
                } elif state["addressInput"] and state["addressInput"].value {  # jac:ignore[E1099]
                    url = state["addressInput"].value;  # jac:ignore[E1001,E1099]
                }

                api = browserAPI();
                if not api or not api.layersStart {
                    appendLayerLog("Start trace failed: browser bridge unavailable.");
                    return;
                }
                try {
                    result = await api.layersStart({"title": "Manual Trace", "url": url});
                    if not result or objectValue(result, "ok", True) == False {
                        appendLayerLog("Start trace failed: " + str(objectValue(result, "error", "unknown error")));
                        return;
                    }
                    state["activeSessionId"] = objectValue(result, "session_id", "") or "";
                    state["activeWorkflowId"] = "";
                    state["traceLifecycleState"] = "recording";
                    state["workflowExplanationDraft"] = "";
                    syncLayerStateLabels();
                    syncLayerFlowUi();
                    appendLayerLog("Started trace " + state["activeSessionId"]);  # jac:ignore[E1055]
                    setClawStatus("");
                } except Exception as err {
                    appendLayerLog("Start trace threw: " + str(err.message or err));  # jac:ignore[E1030]
                }
            }
            handle();
        });
    }

    if state["stopTraceBtn"] {
        state["stopTraceBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                if not state["activeSessionId"] {
                    appendLayerLog("Stop trace skipped: no active session.");
                    return;
                }
                api = browserAPI();
                if not api or not api.layersStop {
                    appendLayerLog("Stop trace failed: browser bridge unavailable.");
                    return;
                }
                try {
                    result = await api.layersStop({"session_id": state["activeSessionId"]});
                    if not result or objectValue(result, "ok", True) == False {
                        appendLayerLog("Stop trace failed: " + str(objectValue(result, "error", "unknown error")));
                        return;
                    }
                    appendLayerLog("Stopped trace " + state["activeSessionId"] + " (" + str(objectValue(result, "event_count", 0)) + " events)");  # jac:ignore[E1055]
                    state["activeWorkflowId"] = "";
                    state["traceLifecycleState"] = "stopped";
                    syncLayerStateLabels();
                    syncLayerFlowUi();
                    setClawStatus("Trace stopped. Add optional explanation, then compile.");
                    if state["workflowExplanationInput"] {
                        setTimeout(lambda { state["workflowExplanationInput"].focus(); }, 10);  # jac:ignore[E1099]
                    }
                } except Exception as err {
                    appendLayerLog("Stop trace threw: " + str(err.message or err));  # jac:ignore[E1030]
                }
            }
            handle();
        });
    }

    if state["compileTraceBtn"] {
        state["compileTraceBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await compileActiveTrace();
            }
            handle();
        });
    }

    if state["planWorkflowBtn"] {
        state["planWorkflowBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await planActiveWorkflow();
            }
            handle();
        });
    }

    if state["clawDraftInput"] {
        state["clawDraftInput"].addEventListener("input", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["clawDraft"] = str(target.value or "");
            if not state["clawIsPlanning"] {
                state["clawStatusText"] = "";
                syncClawUi();
            }
        });
    }

    if state["workflowExplanationInput"] {
        state["workflowExplanationInput"].addEventListener("input", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["workflowExplanationDraft"] = str(target.value or "");
            syncLayerFlowUi();
        });
    }

    if state["clawPlanBtn"] {
        state["clawPlanBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await handleClawPlanNow();
            }
            handle();
        });
    }

    if state["clawSaveDraftBtn"] {
        state["clawSaveDraftBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            handleClawSaveDraft();
        });
    }

    if state["createHelperBtn"] {
        state["createHelperBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            if state["helperBuilderOpen"] {
                closeHelperBuilder(True);
                return;
            }
            openHelperBuilder();
        });
    }

    if state["tasksPanelOpenHelpersBtn"] {
        state["tasksPanelOpenHelpersBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            if findHelperById(state["selectedTaskRunHelperId"]) {
                selectHelper(state["selectedTaskRunHelperId"]);
            }
            setShellView("helpers");
        });
    }

    if state["tasksCreateTabBtn"] {
        state["tasksCreateTabBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            setTaskPanelTab("create");
        });
    }

    if state["tasksRunTabBtn"] {
        state["tasksRunTabBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            setTaskPanelTab("run");
        });
    }

    if state["helperNameInput"] {
        state["helperNameInput"].addEventListener("input", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["helperDraftName"] = str(target.value or "");
            syncClawUi();
        });
    }

    if state["helperGoalInput"] {
        state["helperGoalInput"].addEventListener("input", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["helperDraftGoal"] = str(target.value or "");
            syncClawUi();
        });
    }

    if state["helperFrequencySelect"] {
        state["helperFrequencySelect"].addEventListener("change", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["helperDraftFrequency"] = normalizedHelperFrequency(target.value or "once");
            syncClawUi();
        });
    }

    if state["helperCreateBtn"] {
        state["helperCreateBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await handleHelperCreate();
            }
            handle();
        });
    }

    if state["taskPanelRecordBtn"] {
        state["taskPanelRecordBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await handleTaskPanelRecordToggle();
            }
            handle();
        });
    }

    if state["taskCreateContextInput"] {
        state["taskCreateContextInput"].addEventListener("input", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["taskCreateContextText"] = str(target.value or "");
            syncClawUi();
        });
    }

    if state["taskPanelGenerateBtn"] {
        state["taskPanelGenerateBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await handleTaskPanelGenerate();
            }
            handle();
        });
    }

    if state["helperCancelBtn"] {
        state["helperCancelBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            closeHelperBuilder(True);
        });
    }

    if state["helpersPageCreateBtn"] {
        state["helpersPageCreateBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            if state["helperBuilderOpen"] {
                closeHelperBuilder(True);
                return;
            }
            openHelperBuilder();
        });
    }

    if state["taskRunOverrideInput"] {
        state["taskRunOverrideInput"].addEventListener("input", lambda (event: any) {  # jac:ignore[E1099]
            target = event.currentTarget or event.target;
            state["taskRunOverrideText"] = str(target.value or "");
            syncClawUi();
        });
    }

    if state["taskPanelRunBtn"] {
        state["taskPanelRunBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            async def handle {
                await handleTaskPanelRun();
            }
            handle();
        });
    }

    if state["taskPanelRunClearBtn"] {
        state["taskPanelRunClearBtn"].addEventListener("click", lambda {  # jac:ignore[E1099]
            clearTaskRunOverride();
        });
    }

    async def initialize() -> None {
        syncLayerStateLabels();
        syncLayerFlowUi();
        appendClawTranscript("system", "Claw is ready. Type the task below. Plan now uses the active live trace. Save draft keeps the text in this browser shell only.");
        syncClawUi();
        await refreshHelpersFromBackend();
        await syncLlmRuntimeStatus();
        state["webviewPreloadUrl"] = await safeGetWebviewPreloadUrl();
        if not state["webviewPreloadUrl"] {
            appendLayerLog("Warning: webview preload not resolved; in-page telemetry disabled.");
        }
        homeUrl = await safeGetHomeUrl();
        addTab(homeUrl, {"activate": True, "emitObservation": False});
        scheduleChromeStateSync();
    }

    initialize();
    return lambda {};
}
