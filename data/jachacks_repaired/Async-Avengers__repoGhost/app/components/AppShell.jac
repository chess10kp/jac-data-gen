import from app.orchestration.workflow { run_workflow, query_run_artifacts }
import from app.services.llm_runtime { supported_llm_models, default_llm_model }
import from app.components.SetupShell { SetupShell }
import from app.components.WidgetShell { WidgetShell }

glob STORAGE_SETUP_COMPLETE: str = "repoghost.setup.complete";
glob STORAGE_API_KEY: str = "repoghost.llm.api_key";
glob STORAGE_MODEL: str = "repoghost.llm.model";
glob STORAGE_REMEMBER: str = "repoghost.llm.remember";
glob STORAGE_THEME: str = "repoghost.ui.theme";
glob STORAGE_CONTRAST: str = "repoghost.ui.contrast";

glob LOADING_LABELS: list[str] = [
         "Gibbering...",
         "Fidgeting...",
         "Scrying...",
         "Haunting...",
         "Whispering...",
         "Rummaging...",
         "Manifesting..."
     ];

def mark_used(value: any) -> None {
    if value {
        return;
    }
}

def bool_text(value: bool) -> str {
    if value {
        return "true";
    }
    return "false";
}

def app_shell_class(theme_mode: str, contrast_mode: str) -> str {
    theme_class: str = "theme-light" if theme_mode == "light" else "theme-dark";
    contrast_class: str = "contrast-high"
        if contrast_mode == "high"
        else "contrast-standard";
    return "repoghost-screen "
        + theme_class
        + " "
        + contrast_class
        + " min-h-screen overflow-hidden px-3 py-4";
}

def model_option_rows(model_options: list[str]) -> list[JsxElement] {
    rows: list[JsxElement] = [];
    for item in model_options {
        rows.append(<option key={item} value={item}>{item}</option>);
    }
    if len(rows) == 0 {
        rows.append(<option key="gpt-4o-mini" value="gpt-4o-mini">gpt-4o-mini</option>);
    }
    return rows;
}

async def fetch_workflow_bundle(
    repo_path: str,
    meeting_text: str,
    prompt: str,
    mode: str,
    user_api_key: str,
    user_model: str
) -> any {
    result: any = await run_workflow(
        repo_path, meeting_text, prompt, mode, user_api_key, user_model
    );
    return result;
}

def _pick(src: any, key: str) -> any {
    if src is None {
        return None;
    }
    try {
        return src[key];  # jac:ignore[W2001]
    } except Exception {
        return None;
    }
}

def _pick_str(src: any, key: str) -> str {
    val: any = _pick(src, key);
    if val is None {
        return "";
    }
    return str(val);
}

def _pick_list(src: any, key: str) -> list[any] {
    val: any = _pick(src, key);
    if val is None {
        return [];
    }
    try {
        is_arr: bool = bool(Array.isArray(val));  # jac:ignore[W2001]
        if is_arr {
            return val;
        }
    } except Exception {
        return [];
    }
    return [];
}

def _str_list(src: any, key: str) -> list[str] {
    items: list[any] = _pick_list(src, key);
    result: list[str] = [];
    for item in items {
        if item is not None {
            result.append(str(item));
        }
    }
    return result;
}

def build_artifact_payload(bundle: any) -> dict {
    # Build a minimal, cycle-free dict with only the fields the server
    # reads in artifact_context_text / deterministic_artifact_answer.
    # Stringifying the full bundle can blow the JS call stack on some
    # runtimes, so we hand-trim the tree here.
    if bundle is None {
        return {};
    }

    run_state: any = _pick(bundle, "run_state");
    repo_summary: any = _pick(bundle, "repo_summary");
    meeting_summary: any = _pick(bundle, "meeting_summary");
    handoff: any = _pick(bundle, "handoff");
    standup: any = _pick(bundle, "standup");
    review: any = _pick(bundle, "review");

    decisions_out: list[dict] = [];
    for item in _pick_list(bundle, "decisions") {
        decisions_out.append(
            {"title": _pick_str(item, "title"), "detail": _pick_str(item, "detail")}
        );
    }

    blockers_out: list[dict] = [];
    for item in _pick_list(bundle, "blockers") {
        blockers_out.append(
            {"title": _pick_str(item, "title"), "detail": _pick_str(item, "detail")}
        );
    }

    tasks_out: list[dict] = [];
    for item in _pick_list(bundle, "tasks") {
        tasks_out.append(
            {
                "title": _pick_str(item, "title"),
                "summary": _pick_str(item, "summary"),
                "likely_files": _str_list(item, "likely_files")
            }
        );
    }

    tickets_out: list[dict] = [];
    for item in _pick_list(bundle, "tickets") {
        tickets_out.append(
            {"title": _pick_str(item, "title"), "summary": _pick_str(item, "summary")}
        );
    }

    files_out: list[dict] = [];
    for item in _pick_list(bundle, "relevant_files") {
        files_out.append(
            {"path": _pick_str(item, "path"), "rationale": _pick_str(item, "rationale")}
        );
    }

    trace_out: list[dict] = [];
    for item in _pick_list(bundle, "trace") {
        trace_out.append(
            {"agent": _pick_str(item, "agent"), "detail": _pick_str(item, "detail")}
        );
    }

    return {
        "run_state": {"summary": _pick_str(run_state, "summary")},
        "repo_summary": {
            "project_name": _pick_str(repo_summary, "project_name"),
            "overview": _pick_str(repo_summary, "overview")
        },
        "meeting_summary": {"summary": _pick_str(meeting_summary, "summary")},
        "decisions": decisions_out,
        "blockers": blockers_out,
        "tasks": tasks_out,
        "tickets": tickets_out,
        "handoff": {
            "summary": _pick_str(handoff, "summary"),
            "next_actions": _str_list(handoff, "next_actions")
        },
        "standup": {
            "done": _str_list(standup, "done"),
            "next": _str_list(standup, "next")
        },
        "review": {"risk_hotspots": _str_list(review, "risk_hotspots")},
        "relevant_files": files_out,
        "trace": trace_out
    };
}

async def fetch_run_answer(
    prompt: str, bundle: any, user_api_key: str, user_model: str
) -> str {
    payload: dict = build_artifact_payload(bundle);
    bundle_str: str = "";
    try {
        bundle_str = str(JSON.stringify(payload));  # jac:ignore[W2001]
    } except Exception {
        bundle_str = "{}";
    }
    answer: str = await query_run_artifacts(
        prompt, bundle_str, user_api_key, user_model
    );
    return answer;
}

async def fetch_model_options() -> list[str] {
    options: list[str] = await supported_llm_models();
    return options;
}

async def fetch_default_model() -> str {
    model_name: str = await default_llm_model();
    return model_name;
}

def:pub AppShell() -> JsxElement {
    has repoPath: str = "";
    has meetingText: str = "";
    has contextFileName: str = "";
    has mode: str = "feature_plan";
    has processingContext: bool = False;
    has answeringQuery: bool = False;
    has error: str = "";
    has bundle: any = None;
    has runState: any = None;
    has ownershipData: list[any] = [];
    has decisionsData: list[any] = [];
    has activeWidgetTab: str = "context";
    has statusMessage: str = "";
    has hasProcessedContext: bool = False;
    has followUpPrompt: str = "";
    has followUpHistory: list[dict[str, str]] = [];
    has setupLoaded: bool = False;
    has setupComplete: bool = False;
    has rememberSettings: bool = True;
    has userApiKey: str = "";
    has selectedModel: str = "gpt-4o-mini";
    has modelOptions: list[str] = ["gpt-4o-mini"];
    has themeMode: str = "dark";
    has contrastMode: str = "standard";
    has settingsEditorOpen: bool = False;
    has confirmingNewGhost: bool = False;
    has storageHandle: any = None;
    has _labelTick: int = 0;
    has _labelTimer: any = None;

    def storage_get(key: str) -> str {
        if storageHandle is None {
            return "";
        }
        raw_value: any = storageHandle.getItem(key);
        if raw_value is None {
            return "";
        }
        return str(raw_value);
    }

    def storage_set(key: str, value: str) -> None {
        if storageHandle is None {
            return;
        }
        storageHandle.setItem(key, value);
    }

    def storage_remove(key: str) -> None {
        if storageHandle is None {
            return;
        }
        storageHandle.removeItem(key);
    }

    def stored_bool(key: str, fallback: bool = False) -> bool {
        raw_value: str = storage_get(key);
        if not raw_value {
            return fallback;
        }
        return raw_value == "true";
    }

    def persist_theme_preferences() -> None {
        storage_set(STORAGE_THEME, themeMode);
        storage_set(STORAGE_CONTRAST, contrastMode);
    }

    def persist_llm_preferences() -> None {
        storage_set(STORAGE_SETUP_COMPLETE, "true");
        storage_set(STORAGE_REMEMBER, bool_text(rememberSettings));
        if rememberSettings {
            storage_set(STORAGE_MODEL, selectedModel);
            if userApiKey {
                storage_set(STORAGE_API_KEY, userApiKey);
            } else {
                storage_remove(STORAGE_API_KEY);
            }
            return;
        }
        storage_remove(STORAGE_API_KEY);
        storage_remove(STORAGE_MODEL);
    }

    def clear_run_artifacts() -> None {
        bundle = None;
        runState = None;
        ownershipData = [];
        decisionsData = [];
        hasProcessedContext = False;
        followUpPrompt = "";
        followUpHistory = [];
        activeWidgetTab = "context";
        statusMessage = "";
        mark_used(bundle);
        mark_used(runState);
        mark_used(ownershipData);
        mark_used(decisionsData);
        mark_used(hasProcessedContext);
        mark_used(followUpPrompt);
        mark_used(followUpHistory);
        mark_used(activeWidgetTab);
        mark_used(statusMessage);
    }

    def reset_session() -> None {
        clear_run_artifacts();
        repoPath = "";
        meetingText = "";
        contextFileName = "";
        followUpPrompt = "";
        error = "";
        statusMessage = "";
        processingContext = False;
        answeringQuery = False;
        settingsEditorOpen = False;
        confirmingNewGhost = False;
        mark_used(repoPath);
        mark_used(meetingText);
        mark_used(contextFileName);
        mark_used(followUpPrompt);
        mark_used(error);
        mark_used(statusMessage);
        mark_used(processingContext);
        mark_used(answeringQuery);
        mark_used(settingsEditorOpen);
        mark_used(confirmingNewGhost);
    }

    async can with entry {
        storageHandle = localStorage;  # jac:ignore[W2001]
        mark_used(storageHandle);
        savedTheme: str = storage_get(STORAGE_THEME);
        savedContrast: str = storage_get(STORAGE_CONTRAST);
        savedApiKey: str = storage_get(STORAGE_API_KEY);
        savedModel: str = storage_get(STORAGE_MODEL);
        if savedTheme in ["dark", "light"] {
            themeMode = savedTheme;
            mark_used(themeMode);
        }
        if savedContrast in ["standard", "high"] {
            contrastMode = savedContrast;
            mark_used(contrastMode);
        }
        rememberSettings = stored_bool(STORAGE_REMEMBER, True);
        setupComplete = stored_bool(STORAGE_SETUP_COMPLETE, False);
        mark_used(rememberSettings);
        mark_used(setupComplete);
        if savedApiKey {
            userApiKey = savedApiKey;
            mark_used(userApiKey);
        }
        if savedModel {
            selectedModel = savedModel;
            mark_used(selectedModel);
        }
        try {
            fetchedModels: list[str] = await fetch_model_options();
            if len(fetchedModels) > 0 {
                modelOptions = fetchedModels;
                mark_used(modelOptions);
            }
            defaultModelName: str = await fetch_default_model();
            if defaultModelName
                and (not selectedModel or selectedModel == "gpt-4o-mini") {
                selectedModel = defaultModelName;
                mark_used(selectedModel);
            }
        } except RuntimeError { } except ValueError { } except TypeError { } except OSError { }
        if not selectedModel and len(modelOptions) > 0 {
            selectedModel = modelOptions[0];
            mark_used(selectedModel);
        }
        if selectedModel not in modelOptions and len(modelOptions) > 0 {
            selectedModel = modelOptions[0];
            mark_used(selectedModel);
        }
        setupLoaded = True;
        mark_used(setupLoaded);
    }

    can with [themeMode, contrastMode] entry {
        if not setupLoaded {
            return;
        }
        persist_theme_preferences();
    }

    can with [processingContext] entry {
        if not processingContext {
            if _labelTimer is not None {
                clearInterval(_labelTimer);  # jac:ignore[W2001]
            }
            _labelTimer = None;
            _labelTick = 0;
            mark_used(_labelTimer);
            mark_used(_labelTick);
            return;
        }
        if _labelTimer is not None {
            clearInterval(_labelTimer);  # jac:ignore[W2001]
        }
        _labelTimer = setInterval(  # jac:ignore[W2001]
            lambda () -> None {
                _labelTick = int(Date.now() / 1400);  # jac:ignore[W2001]
                mark_used(_labelTick);
            },
            1400
        );
        mark_used(_labelTimer);
    }

    async def submit_setup() -> None {
        if not selectedModel and len(modelOptions) > 0 {
            selectedModel = modelOptions[0];
            mark_used(selectedModel);
        }
        persist_llm_preferences();
        setupComplete = True;
        settingsEditorOpen = False;
        error = "";
        mark_used(setupComplete);
        mark_used(settingsEditorOpen);
        mark_used(error);
    }

    async def process_context() -> None {
        if not repoPath {
            error = "Add a repo path before processing context.";
            mark_used(error);
            return;
        }
        clear_run_artifacts();
        processingContext = True;
        error = "";
        statusMessage = "Processing context";
        settingsEditorOpen = False;
        mark_used(processingContext);
        mark_used(error);
        mark_used(statusMessage);
        mark_used(settingsEditorOpen);
        try {
            nextBundle: any = await fetch_workflow_bundle(
                repoPath, meetingText, "", mode, userApiKey, selectedModel
            );
            bundle = nextBundle;
            runState = nextBundle.run_state if nextBundle else None;
            ownershipData = nextBundle.ownership if nextBundle else [];
            decisionsData = nextBundle.decisions if nextBundle else [];
            hasProcessedContext = True;
            if nextBundle and nextBundle.run_state and nextBundle.run_state.summary {
                statusMessage = nextBundle.run_state.summary;
                mark_used(statusMessage);
            } else {
                statusMessage = "Context processed";
                mark_used(statusMessage);
            }
            mark_used(bundle);
            mark_used(runState);
            mark_used(ownershipData);
            mark_used(decisionsData);
            mark_used(hasProcessedContext);
            mark_used(statusMessage);
        } except ValueError as e {
            error = str(e);
            statusMessage = "Context processing failed";
            mark_used(error);
            mark_used(statusMessage);
        } except RuntimeError as e {
            error = str(e);
            statusMessage = "Context processing failed";
            mark_used(error);
            mark_used(statusMessage);
        } except TypeError as e {
            error = str(e);
            statusMessage = "Context processing failed";
            mark_used(error);
            mark_used(statusMessage);
        } except OSError as e {
            error = str(e);
            statusMessage = "Context processing failed";
            mark_used(error);
            mark_used(statusMessage);
        }
        processingContext = False;
        mark_used(processingContext);
    }

    async def ask_about_run() -> None {
        if not hasProcessedContext or not bundle {
            error = "Process context before asking follow-up questions.";
            mark_used(error);
            return;
        }
        if not followUpPrompt {
            error = "Add a follow-up prompt for the current run.";
            mark_used(error);
            return;
        }
        answeringQuery = True;
        error = "";
        mark_used(answeringQuery);
        mark_used(error);
        try {
            question: str = followUpPrompt;
            answer: str = await fetch_run_answer(
                question, bundle, userApiKey, selectedModel
            );
            followUpHistory = followUpHistory
                + [
                    {"role": "user", "content": question},
                    {"role": "assistant", "content": answer}
                ];
            followUpPrompt = "";
            mark_used(followUpHistory);
            mark_used(followUpPrompt);
        } except ValueError as e {
            error = str(e);
            mark_used(error);
        } except RuntimeError as e {
            error = str(e);
            mark_used(error);
        } except TypeError as e {
            error = str(e);
            mark_used(error);
        } except OSError as e {
            error = str(e);
            mark_used(error);
        } except Exception as e {
            error = str(e);
            mark_used(error);
        }
        answeringQuery = False;
        mark_used(answeringQuery);
    }

    def update_repo_path(next_path: str) -> None {
        repoPath = next_path;
        mark_used(repoPath);
        if error {
            error = "";
            mark_used(error);
        }
        confirmingNewGhost = False;
        mark_used(confirmingNewGhost);
        clear_run_artifacts();
    }

    def update_meeting_text(next_text: str) -> None {
        meetingText = next_text;
        contextFileName = "";
        mark_used(meetingText);
        mark_used(contextFileName);
        if error {
            error = "";
            mark_used(error);
        }
        confirmingNewGhost = False;
        mark_used(confirmingNewGhost);
        clear_run_artifacts();
    }

    def update_context_file_name(next_name: str) -> None {
        contextFileName = next_name;
        mark_used(contextFileName);
    }

    def update_follow_up_prompt(next_prompt: str) -> None {
        followUpPrompt = next_prompt;
        mark_used(followUpPrompt);
        if error {
            error = "";
            mark_used(error);
        }
    }

    def update_active_widget_tab(tab: str) -> None {
        activeWidgetTab = tab;
        mark_used(activeWidgetTab);
    }

    def update_user_api_key(next_key: str) -> None {
        userApiKey = next_key;
        mark_used(userApiKey);
    }

    def update_selected_model(next_model: str) -> None {
        selectedModel = next_model;
        mark_used(selectedModel);
        if setupComplete {
            persist_llm_preferences();
        }
    }

    def update_remember_settings(next_value: bool) -> None {
        rememberSettings = next_value;
        mark_used(rememberSettings);
    }

    def toggle_settings_editor() -> None {
        settingsEditorOpen = not settingsEditorOpen;
        confirmingNewGhost = False;
        mark_used(settingsEditorOpen);
        mark_used(confirmingNewGhost);
    }

    def save_api_settings() -> None {
        persist_llm_preferences();
        settingsEditorOpen = False;
        mark_used(settingsEditorOpen);
    }

    def clear_api_settings() -> None {
        userApiKey = "";
        settingsEditorOpen = False;
        storage_remove(STORAGE_API_KEY);
        if rememberSettings {
            persist_llm_preferences();
        }
        mark_used(userApiKey);
        mark_used(settingsEditorOpen);
    }

    def prompt_new_ghost() -> None {
        confirmingNewGhost = True;
        settingsEditorOpen = False;
        mark_used(confirmingNewGhost);
        mark_used(settingsEditorOpen);
    }

    def cancel_new_ghost() -> None {
        confirmingNewGhost = False;
        mark_used(confirmingNewGhost);
    }

    def confirm_new_ghost() -> None {
        reset_session();
    }

    def toggle_theme() -> None {
        if themeMode == "dark" {
            themeMode = "light";
        } else {
            themeMode = "dark";
        }
        mark_used(themeMode);
    }

    def toggle_contrast() -> None {
        if contrastMode == "high" {
            contrastMode = "standard";
        } else {
            contrastMode = "high";
        }
        mark_used(contrastMode);
    }

    shellLoading: bool = processingContext or answeringQuery;
    shellClass: str = app_shell_class(themeMode, contrastMode);
    processLabel: str = LOADING_LABELS[_labelTick % len(LOADING_LABELS)];

    if not setupLoaded {
        return
            <div className={shellClass}>
                <div
                    className="flex min-h-[calc(100vh-4rem)] items-center justify-center"
                >
                    <div
                        className="rounded-[2rem] border border-border bg-panel/90 px-6 py-5 text-[15px] text-muted shadow-[var(--shadow-glow)]"
                    >
                        Loading repoGhost...
                    </div>
                </div>
            </div>;
    }

    if not setupComplete {
        return
            <div className={shellClass}>
                <div
                    className="flex min-h-[calc(100vh-4rem)] items-center justify-center"
                >
                    <SetupShell
                        apiKey={userApiKey}
                        selectedModel={selectedModel}
                        modelOptions={modelOptions}
                        rememberSettings={rememberSettings}
                        loading={False}
                        error={error}
                        setApiKey={update_user_api_key}
                        setSelectedModel={update_selected_model}
                        setRememberSettings={update_remember_settings}
                        submitSetup={submit_setup}
                    />
                </div>
            </div>;
    }

    return
        <div className={shellClass}>
            <div
                className="mx-auto flex min-h-[calc(100vh-32px)] w-full max-w-[1240px] flex-col items-stretch gap-0"
            >
                <div className="w-full">
                    <WidgetShell
                        bundle={bundle}
                        runState={runState}
                        meetingText={meetingText}
                        contextFileName={contextFileName}
                        contextLoading={processingContext}
                        queryLoading={answeringQuery}
                        loading={shellLoading}
                        error={error}
                        activeWidgetTab={activeWidgetTab}
                        repoPath={repoPath}
                        ownership={ownershipData}
                        decisions={decisionsData}
                        statusMessage={statusMessage}
                        hasProcessedContext={hasProcessedContext}
                        followUpPrompt={followUpPrompt}
                        followUpHistory={followUpHistory}
                        setRepoPath={update_repo_path}
                        setMeetingText={update_meeting_text}
                        setContextFileName={update_context_file_name}
                        setActiveWidgetTab={update_active_widget_tab}
                        setFollowUpPrompt={update_follow_up_prompt}
                        processContext={process_context}
                        askAboutRun={ask_about_run}
                        processLabel={processLabel}
                        promptNewGhost={prompt_new_ghost}
                        confirmingNewGhost={confirmingNewGhost}
                        cancelNewGhost={cancel_new_ghost}
                        confirmNewGhost={confirm_new_ghost}
                        themeMode={themeMode}
                        contrastMode={contrastMode}
                        settingsEditorOpen={settingsEditorOpen}
                        selectedModel={selectedModel}
                        modelOptions={modelOptions}
                        userApiKey={userApiKey}
                        rememberSettings={rememberSettings}
                        toggleTheme={toggle_theme}
                        toggleContrast={toggle_contrast}
                        toggleSettingsEditor={toggle_settings_editor}
                        saveApiSettings={save_api_settings}
                        clearApiSettings={clear_api_settings}
                        updateSelectedModel={update_selected_model}
                        updateUserApiKey={update_user_api_key}
                        updateRememberSettings={update_remember_settings}
                    />
                </div>
            </div>
        </div>;
}
