
def chat_bubble_class(role: str) -> str {
    if role == "user" {
        return "ml-auto max-w-[90%] rounded-2xl border border-accent/30 bg-accent/10 px-4 py-3";
    }
    return "max-w-[90%] rounded-2xl border border-border bg-panel-soft px-4 py-3";
}

def workspace_error_panel(error: str) -> JsxElement {
    if error {
        return <div className="rounded-2xl border border-danger/40 bg-danger/10 px-4 py-3 text-sm text-foreground">{error}</div>;
    }
    return <div />;
}

def workspace_button_label(loading: bool) -> str {
    if loading {
        return "Running workflow...";
    }
    return "Run workflow";
}

def invoke_callback(fn: any, value: any) -> None {
    fn.call(None, value);
}

async def invoke_async_callback(fn: any, value: any) -> None {
    await fn.call(None, value);
}

def trace_card_key(item: any) -> str {
    return str(item.agent) + str(item.stage);
}

def trace_card_status(item: any) -> str {
    return str(item.stage) + " • " + str(item.status);
}


def:pub WorkspaceShell(
    bundle: any = None,
    activeTab: str = "context",
    chatThread: list[dict[str, str]] = [],
    repoPath: str = "",
    meetingText: str = "",
    draftPrompt: str = "",
    loading: bool = False,
    error: str = "",
    lastRunLabel: str = "Ready",
    graphNodes: list[any] = [],
    graphEdges: list[any] = [],
    graphFocusPaths: list[str] = [],
    planningResolved: list[any] = [],
    planningBlockers: list[any] = [],
    planningImpacts: list[any] = [],
    planningTestGaps: list[any] = [],
    reviewHotspots: list[str] = [],
    setRepoPath: any = None,
    setMeetingText: any = None,
    setDraftPrompt: any = None,
    submit: any = None
) -> JsxElement {
    onRepo = setRepoPath;
    onMeeting = setMeetingText;
    onDraft = setDraftPrompt;
    onSubmit = submit;

    trace: list[any] = [];
    tasks: list[any] = [];
    tickets: list[any] = [];
    blockers: list[any] = [];
    files: list[any] = [];
    decisions: list[any] = [];
    repoOverview = "Waiting for workflow bundle.";
    meetingSummary = "No meeting summary yet.";
    actionHeadline = "No action plan yet.";
    handoffSummary = "No handoff summary yet.";
    reviewSummary = "No review summary yet.";

    if bundle {
        trace = bundle.trace or [];
        tasks = bundle.tasks or [];
        tickets = bundle.tickets or [];
        blockers = bundle.blockers or [];
        files = bundle.relevant_files or [];
        decisions = bundle.decisions or [];
        repoOverview = bundle.repo_summary.overview or repoOverview;
        meetingSummary = bundle.meeting_summary.summary or meetingSummary;
        actionHeadline = bundle.action_plan.headline or actionHeadline;
        handoffSummary = bundle.handoff.summary or handoffSummary;
        reviewSummary = bundle.review.summary or reviewSummary;
    }

    async def sendPrompt() -> None {
        if onSubmit {
            await invoke_async_callback(onSubmit, draftPrompt);
        }
    }

    chatCards: list[JsxElement] = [];
    safeThread: list[dict[str, str]] = chatThread or [];
    for item in safeThread {
        chatCards.append(
            <div key={item["role"] + "-" + str(len(chatCards))} className={chat_bubble_class(item["role"])}>
                <div className="text-[10px] uppercase tracking-[0.18em] text-muted">{item["role"]}</div>
                <div className="mt-2 text-sm leading-6 text-foreground">{item["content"]}</div>
            </div>
        );
    }
    if len(chatCards) == 0 {
        chatCards.append(<div key="no-chat" className="rounded-2xl border border-border bg-panel-soft px-4 py-3 text-sm text-muted">No chat messages yet.</div>);
    }

    fileCards = [];
    for item in files {
        if len(fileCards) >= 6 {
            break;
        }
        fileCards.append(
            <div key={item.path} className="rounded-xl border border-border bg-panel-soft px-3 py-3">
                <div className="text-sm font-medium text-foreground">{item.path}</div>
                <div className="mt-1 text-xs text-muted">{item.rationale}</div>
            </div>
        );
    }
    if len(fileCards) == 0 {
        fileCards.append(<div key="no-files" className="rounded-xl border border-border bg-panel-soft px-3 py-3 text-sm text-muted">No relevant files yet.</div>);
    }

    blockerCards = [];
    for item in blockers {
        if len(blockerCards) >= 6 {
            break;
        }
        blockerCards.append(
            <div key={item.title} className="rounded-xl border border-danger/30 bg-danger/10 px-3 py-3">
                <div className="text-sm font-medium text-foreground">{item.title}</div>
                <div className="mt-1 text-xs text-muted">{item.detail}</div>
            </div>
        );
    }
    if len(blockerCards) == 0 {
        blockerCards.append(<div key="no-blockers" className="rounded-xl border border-border bg-panel-soft px-3 py-3 text-sm text-muted">No blockers yet.</div>);
    }

    taskCards = [];
    for item in tasks {
        if len(taskCards) >= 6 {
            break;
        }
        taskCards.append(
            <div key={item.title} className="rounded-xl border border-border bg-panel-soft px-3 py-3">
                <div className="text-sm font-medium text-foreground">{item.title}</div>
                <div className="mt-1 text-xs text-muted">{item.summary}</div>
            </div>
        );
    }
    if len(taskCards) == 0 {
        taskCards.append(<div key="no-tasks" className="rounded-xl border border-border bg-panel-soft px-3 py-3 text-sm text-muted">No tasks yet.</div>);
    }

    ticketCards = [];
    for item in tickets {
        if len(ticketCards) >= 6 {
            break;
        }
        ticketCards.append(
            <div key={item.title} className="rounded-xl border border-border bg-panel-soft px-3 py-3">
                <div className="text-sm font-medium text-foreground">{item.title}</div>
                <div className="mt-1 text-xs text-muted">{item.summary}</div>
            </div>
        );
    }
    if len(ticketCards) == 0 {
        ticketCards.append(<div key="no-tickets" className="rounded-xl border border-border bg-panel-soft px-3 py-3 text-sm text-muted">No tickets yet.</div>);
    }

    traceCards = [];
    for item in trace {
        if len(traceCards) >= 8 {
            break;
        }
        traceCards.append(
            <div key={trace_card_key(item)} className="rounded-xl border border-border bg-panel-soft px-3 py-3">
                <div className="text-sm font-medium text-foreground">{item.agent}</div>
                <div className="mt-1 text-xs uppercase tracking-[0.18em] text-muted">{trace_card_status(item)}</div>
                <div className="mt-2 text-xs text-muted">{item.detail}</div>
            </div>
        );
    }
    if len(traceCards) == 0 {
        traceCards.append(<div key="no-trace" className="rounded-xl border border-border bg-panel-soft px-3 py-3 text-sm text-muted">No workflow trace yet.</div>);
    }

    graphCards = [];
    for item in graphNodes {
        if len(graphCards) >= 8 {
            break;
        }
        graphCards.append(
            <div key={item.id} className="rounded-xl border border-border bg-panel-soft px-3 py-3">
                <div className="text-sm font-medium text-foreground">{item.label}</div>
                <div className="mt-1 text-xs text-muted">{item.detail}</div>
            </div>
        );
    }
    if len(graphCards) == 0 {
        graphCards.append(<div key="no-graph" className="rounded-xl border border-border bg-panel-soft px-3 py-3 text-sm text-muted">No graph nodes yet.</div>);
    }

    focusCards = [];
    for item in graphFocusPaths {
        if len(focusCards) >= 6 {
            break;
        }
        focusCards.append(<div key={item} className="rounded-full border border-border bg-panel px-3 py-1 text-xs text-muted">{item}</div>);
    }
    if len(focusCards) == 0 {
        focusCards.append(<div key="no-focus" className="rounded-full border border-border bg-panel px-3 py-1 text-xs text-muted">No focus paths yet</div>);
    }

    resolvedCards = [];
    for item in planningResolved {
        resolvedCards.append(<div key={item.title} className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-foreground">{item.title}</div>);
    }
    if len(resolvedCards) == 0 {
        resolvedCards.append(<div key="no-resolved" className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-muted">No resolved areas yet.</div>);
    }

    impactCards = [];
    for item in planningImpacts {
        impactCards.append(<div key={item.title} className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-foreground">{item.title}</div>);
    }
    if len(impactCards) == 0 {
        impactCards.append(<div key="no-impacts" className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-muted">No impact hotspots yet.</div>);
    }

    riskCards = [];
    for item in planningBlockers {
        riskCards.append(<div key={item.title} className="rounded-xl border border-danger/30 bg-danger/10 px-3 py-2 text-sm text-foreground">{item.title}</div>);
    }
    for item in planningTestGaps {
        riskCards.append(<div key={item.title} className="rounded-xl border border-warning/30 bg-warning/10 px-3 py-2 text-sm text-foreground">{item.title}</div>);
    }
    if len(riskCards) == 0 {
        riskCards.append(<div key="no-risks" className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-muted">No planning risks yet.</div>);
    }

    decisionCards = [];
    for item in decisions {
        decisionCards.append(<div key={item.title} className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-foreground">{item.title}</div>);
    }
    if len(decisionCards) == 0 {
        decisionCards.append(<div key="no-decisions" className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-muted">No decisions yet.</div>);
    }

    hotspotCards = [];
    for item in reviewHotspots {
        hotspotCards.append(<div key={item} className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-foreground">{item}</div>);
    }
    if len(hotspotCards) == 0 {
        hotspotCards.append(<div key="no-hotspots" className="rounded-xl border border-border bg-panel-soft px-3 py-2 text-sm text-muted">No review hotspots yet.</div>);
    }

    return <section className="rounded-[2rem] border border-border bg-panel/85 p-5 shadow-[var(--shadow-glow)] backdrop-blur">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-start xl:justify-between">
            <div>
                <div className="text-xs uppercase tracking-[0.28em] text-accent-2">Expanded workspace</div>
                <h2 className="mt-2 text-3xl font-semibold text-foreground">Engineering workspace</h2>
                <div className="mt-2 text-sm text-muted">{lastRunLabel + " • tab " + activeTab}</div>
            </div>
            <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
                <div className="rounded-2xl border border-border bg-panel-soft px-4 py-3 text-sm text-foreground">{str(len(graphNodes)) + " nodes"}</div>
                <div className="rounded-2xl border border-border bg-panel-soft px-4 py-3 text-sm text-foreground">{str(len(graphEdges)) + " edges"}</div>
                <div className="rounded-2xl border border-border bg-panel-soft px-4 py-3 text-sm text-foreground">{str(len(tasks)) + " tasks"}</div>
                <div className="rounded-2xl border border-border bg-panel-soft px-4 py-3 text-sm text-foreground">{str(len(tickets)) + " tickets"}</div>
            </div>
        </div>

        <div className="mt-4 grid gap-4 lg:grid-cols-3">
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4 lg:col-span-1">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Repo path</div>
                <input value={repoPath} onChange={lambda (e: any) -> None { if onRepo { invoke_callback(onRepo, e.target.value); } }} className="mt-2 w-full rounded-2xl border border-border bg-panel px-3 py-3 text-sm text-foreground outline-none focus:border-accent" placeholder="C:/path/to/repo" />
                <div className="mt-4 text-xs uppercase tracking-[0.18em] text-muted">Meeting notes</div>
                <textarea value={meetingText} onChange={lambda (e: any) -> None { if onMeeting { invoke_callback(onMeeting, e.target.value); } }} className="mt-2 min-h-[140px] w-full rounded-2xl border border-border bg-panel px-3 py-3 text-sm text-foreground outline-none focus:border-accent" placeholder="Paste meeting notes or transcript" />
                <div className="mt-4 text-xs uppercase tracking-[0.18em] text-muted">Prompt</div>
                <textarea value={draftPrompt} onChange={lambda (e: any) -> None { if onDraft { invoke_callback(onDraft, e.target.value); } }} className="mt-2 min-h-[120px] w-full rounded-2xl border border-border bg-panel px-3 py-3 text-sm text-foreground outline-none focus:border-accent" placeholder="Turn this meeting into tickets" />
                <button onClick={sendPrompt} className="mt-3 w-full rounded-2xl bg-accent px-4 py-3 text-sm font-semibold text-background transition hover:brightness-110 disabled:cursor-not-allowed disabled:opacity-60" disabled={loading}>{workspace_button_label(loading)}</button>
            </div>

            <div className="space-y-4 lg:col-span-2">
                {workspace_error_panel(error)}
                <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                    <div className="text-xs uppercase tracking-[0.18em] text-muted">Chat thread</div>
                    <div className="mt-3 space-y-3">{chatCards}</div>
                </div>
                <div className="grid gap-4 md:grid-cols-2">
                    <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                        <div className="text-xs uppercase tracking-[0.18em] text-muted">Repo overview</div>
                        <div className="mt-2 text-sm leading-6 text-foreground">{repoOverview}</div>
                    </div>
                    <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                        <div className="text-xs uppercase tracking-[0.18em] text-muted">Meeting summary</div>
                        <div className="mt-2 text-sm leading-6 text-foreground">{meetingSummary}</div>
                    </div>
                    <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                        <div className="text-xs uppercase tracking-[0.18em] text-muted">Action plan</div>
                        <div className="mt-2 text-sm leading-6 text-foreground">{actionHeadline}</div>
                    </div>
                    <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                        <div className="text-xs uppercase tracking-[0.18em] text-muted">Review summary</div>
                        <div className="mt-2 text-sm leading-6 text-foreground">{reviewSummary}</div>
                    </div>
                </div>
            </div>
        </div>

        <div className="mt-4 grid gap-4 xl:grid-cols-3">
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Relevant files</div>
                <div className="mt-3 space-y-2">{fileCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Tasks</div>
                <div className="mt-3 space-y-2">{taskCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Tickets</div>
                <div className="mt-3 space-y-2">{ticketCards}</div>
            </div>
        </div>

        <div className="mt-4 grid gap-4 xl:grid-cols-3">
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Blockers</div>
                <div className="mt-3 space-y-2">{blockerCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Planning resolved</div>
                <div className="mt-3 space-y-2">{resolvedCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Impact hotspots</div>
                <div className="mt-3 space-y-2">{impactCards}</div>
            </div>
        </div>

        <div className="mt-4 grid gap-4 xl:grid-cols-3">
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Planning risks</div>
                <div className="mt-3 space-y-2">{riskCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Decisions</div>
                <div className="mt-3 space-y-2">{decisionCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Review hotspots</div>
                <div className="mt-3 space-y-2">{hotspotCards}</div>
            </div>
        </div>

        <div className="mt-4 grid gap-4 xl:grid-cols-3">
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4 xl:col-span-2">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Workflow trace</div>
                <div className="mt-3 grid gap-2 md:grid-cols-2">{traceCards}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Graph focus</div>
                <div className="mt-3 flex flex-wrap gap-2">{focusCards}</div>
                <div className="mt-4 text-xs uppercase tracking-[0.18em] text-muted">Graph nodes</div>
                <div className="mt-3 space-y-2">{graphCards}</div>
            </div>
        </div>

        <div className="mt-4 grid gap-4 md:grid-cols-2">
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Handoff</div>
                <div className="mt-2 text-sm leading-6 text-foreground">{handoffSummary}</div>
            </div>
            <div className="rounded-[1.5rem] border border-border bg-panel-soft p-4">
                <div className="text-xs uppercase tracking-[0.18em] text-muted">Active tab</div>
                <div className="mt-2 text-sm leading-6 text-foreground">{activeTab}</div>
            </div>
        </div>
    </section>;
}
