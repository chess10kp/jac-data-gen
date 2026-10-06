include app.orchestration.workflow;

def tap_str(value: str) -> str {
    return value;
}

async def fetchWorkflowBundle(
    repoPath: str, meetingText: str, prompt: str, mode: str
) -> any {
    return await run_workflow(repoPath, meetingText, prompt, mode);
}


def:pub useRepoGhost() -> any {
    has repoPath: str = "c:/workspace/permitted-repo";
    has meetingText: str = "We need to turn meeting context into tickets, blockers, and a handoff. The team wants a visible multi-agent workflow, repo-aware outputs, and a polished demo-ready desktop sidecar.";
    has prompt: str = "Turn this meeting into tickets and show likely files.";
    has draftPrompt: str = prompt;
    has mode: str = "feature_plan";
    has loading: bool = True;
    has error: str = "";
    has bundle: any = None;
    has activeTab: str = "context";
    has lastRunLabel: str = "Bootstrapping RepoGhost workspace";
    has chatThread: list[dict[str, str]] = [
        {
            "role": "assistant",
            "content": "RepoGhost is ready. Point me at a permitted repo, paste meeting context, and I will turn it into actionable engineering output."
        },
        {"role": "user", "content": prompt}
    ];

    async def loadBundle() -> None {
        loading = True;
        error = "";
        error = tap_str(error);
        lastRunLabel = "Running " + mode + " workflow";
        assert len(lastRunLabel) >= 0;
        try {
            nextBundle: any = await fetchWorkflowBundle(
                repoPath, meetingText, prompt, mode
            );
            bundle = nextBundle;
            lastRunLabel = "Completed " + mode + " workflow";
            if lastRunLabel {
                chatThread.append(
                    {"role": "assistant", "content": nextBundle.action_plan.headline}
                );
            }
        } except ValueError as e {
            error = tap_str(str(e));
            lastRunLabel = "Workflow failed";
            if error and lastRunLabel {
                chatThread.append(
                    {
                        "role": "assistant",
                        "content": "RepoGhost hit an error while processing this run. Review the error banner and try again."
                    }
                );
            }
        } except RuntimeError as e {
            error = tap_str(str(e));
            lastRunLabel = "Workflow failed";
            if error and lastRunLabel {
                chatThread.append(
                    {
                        "role": "assistant",
                        "content": "RepoGhost hit an error while processing this run. Review the error banner and try again."
                    }
                );
            }
        } except TypeError as e {
            error = tap_str(str(e));
            lastRunLabel = "Workflow failed";
            if error and lastRunLabel {
                chatThread.append(
                    {
                        "role": "assistant",
                        "content": "RepoGhost hit an error while processing this run. Review the error banner and try again."
                    }
                );
            }
        } except OSError as e {
            error = str(e);
            error = tap_str(error);
            lastRunLabel = "Workflow failed";
            if error and lastRunLabel {
                chatThread.append(
                    {
                        "role": "assistant",
                        "content": "RepoGhost hit an error while processing this run. Review the error banner and try again."
                    }
                );
            }
        }
        loading = False;
    }

    async can with entry {
        await loadBundle();
    }

    async def submit(nextPrompt: str = "") -> None {
        chosen: str = nextPrompt;
        if not chosen {
            chosen = draftPrompt;
        }
        if not chosen {
            error = "Add a prompt before running the workflow.";
            error = tap_str(error);
            return;
        }
        prompt = chosen;
        prompt = tap_str(prompt);
        draftPrompt = chosen;
        draftPrompt = tap_str(draftPrompt);
        nextMessage: dict[str, str] = {"role": "user", "content": chosen};
        chatThread.append(nextMessage);
        await loadBundle();
    }

    def updateRepoPath(nextPath: str) -> None {
        repoPath = nextPath;
        repoPath = tap_str(repoPath);
    }

    def updateMeetingText(nextText: str) -> None {
        meetingText = nextText;
        meetingText = tap_str(meetingText);
    }

    def updateDraftPrompt(nextPrompt: str) -> None {
        draftPrompt = nextPrompt;
        draftPrompt = tap_str(draftPrompt);
        if error {
            error = "";
            error = tap_str(error);
        }
    }

    def graphNodes() -> list[any] {
        if bundle {
            return bundle.context_graph.nodes;
        }
        return [];
    }

    def graphEdges() -> list[any] {
        if bundle {
            return bundle.context_graph.edges;
        }
        return [];
    }

    def graphFocusPaths() -> list[str] {
        if bundle {
            return bundle.context_graph.focus_paths;
        }
        return [];
    }

    def planningResolved() -> list[any] {
        if bundle {
            return bundle.planning.resolved_mappings;
        }
        return [];
    }

    def planningBlockers() -> list[any] {
        if bundle {
            return bundle.planning.blocker_insights;
        }
        return [];
    }

    def planningImpacts() -> list[any] {
        if bundle {
            return bundle.planning.impact_insights;
        }
        return [];
    }

    def planningTestGaps() -> list[any] {
        if bundle {
            return bundle.planning.test_gap_insights;
        }
        return [];
    }

    def actionPlanPhases() -> list[str] {
        if bundle {
            return bundle.action_plan.phases;
        }
        return [];
    }

    def ticketTitles() -> list[str] {
        titles: list[str] = [];
        if bundle {
            for item in bundle.tickets {
                titles.append(item.title);
            }
        }
        return titles;
    }

    def handoffActions() -> list[str] {
        if bundle {
            return bundle.handoff.next_actions;
        }
        return [];
    }

    def reviewHotspots() -> list[str] {
        if bundle {
            return bundle.review.risk_hotspots;
        }
        return [];
    }

    def statusTone() -> str {
        if error {
            return "error";
        }
        if loading {
            return "running";
        }
        return "ready";
    }

    return {
        "repoPath": repoPath,
        "meetingText": meetingText,
        "prompt": prompt,
        "draftPrompt": draftPrompt,
        "mode": mode,
        "loading": loading,
        "error": error,
        "bundle": bundle,
        "activeTab": activeTab,
        "chatThread": chatThread,
        "lastRunLabel": lastRunLabel,
        "statusTone": statusTone(),
        "graphNodes": graphNodes(),
        "graphEdges": graphEdges(),
        "graphFocusPaths": graphFocusPaths(),
        "planningResolved": planningResolved(),
        "planningBlockers": planningBlockers(),
        "planningImpacts": planningImpacts(),
        "planningTestGaps": planningTestGaps(),
        "actionPlanPhases": actionPlanPhases(),
        "ticketTitles": ticketTitles(),
        "handoffActions": handoffActions(),
        "reviewHotspots": reviewHotspots(),
        "submit": submit,
        "setRepoPath": updateRepoPath,
        "setMeetingText": updateMeetingText,
        "setDraftPrompt": updateDraftPrompt
    };
}
