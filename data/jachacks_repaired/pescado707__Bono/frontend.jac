def:pub app() -> JsxElement {
    has selectedMode: str = "text";
    has selectedLanguage: str = "english";
    has quietMode: bool = False;
    has autoErase: bool = False;
    has showPrompt: bool = False;
    has textPrompt: str = "";
    has isLoading: bool = False;
    has isFollowUp: bool = False;
    has followUpInput: str = "";
    has originalInput: str = "";
    has selectedModel: str = "claude-haiku-4-5-20251001";
    has lastAssistantMessage: str = "Press GO to search for guidance.";
    has situationSummary: str = "";
    has yourRights: str = "";
    has toDo: str = "";
    has notToDo: str = "";
    has questions: str = "";
    has legalJargon: str = "";
    has whoCanHelp: str = "";
    has whatHappensNext: str = "";
    has nodesExpanded: bool = False;
    has showSummary: bool = False;
    has caseSummary: str = "";

    def modeButtonClass(kind: str) -> str {
        base = "rounded-full border px-4 py-2 text-sm font-semibold transition ";
        if selectedMode == kind {
            return base + "border-emerald-700 bg-emerald-700 text-white";
        }
        return base + "border-emerald-300 bg-white text-emerald-900";
    }

    def languageButtonClass(kind: str) -> str {
        base = "rounded-full border px-4 py-2 text-sm font-semibold transition ";
        if selectedLanguage == kind {
            return base + "border-emerald-700 bg-emerald-700 text-white";
        }
        return base + "border-emerald-300 bg-white text-emerald-900";
    }

    def modelButtonClass(kind: str) -> str {
        base = "rounded-full border px-3 py-1 text-xs font-semibold transition ";
        if selectedModel == kind {
            return base + "border-emerald-700 bg-emerald-700 text-white";
        }
        return base + "border-emerald-300 bg-white text-emerald-900";
    }

    def panelClass() -> str {
        if showPrompt {
            return "mt-8 rounded-3xl border border-emerald-200 bg-white p-5 shadow-sm";
        }
        return "hidden";
    }

    def quietBannerClass() -> str {
        if quietMode {
            return "mt-6 rounded-3xl border border-emerald-300 bg-emerald-50 p-4 text-sm text-emerald-900";
        }
        return "hidden";
    }

    def autoEraseClass() -> str {
        if autoErase {
            return "rounded-full bg-emerald-700 px-4 py-2 text-sm font-semibold text-white";
        }
        return "rounded-full border border-emerald-300 bg-white px-4 py-2 text-sm font-semibold text-emerald-900";
    }

    def statusText() -> str {
        if isLoading {
            return "Analyzing your situation...";
        }
        return lastAssistantMessage;
    }

    def selectText() -> None { selectedMode = "text"; }
    def selectMic() -> None { selectedMode = "mic"; }
    def selectWritten() -> None { selectedMode = "written"; }
    def selectEnglish() -> None { selectedLanguage = "english"; }
    def selectChinese() -> None { selectedLanguage = "chinese"; }
    def enableQuietMode() -> None { quietMode = True; }
    def disableQuietMode() -> None { quietMode = False; }
    def toggleAutoErase() -> None { autoErase = not autoErase; }
    def closePrompt() -> None { showPrompt = False; }
    def updatePrompt(e: any) -> None { textPrompt = e.target.value; }
    def updateFollowUpInput(e: any) -> None { followUpInput = e.target.value; }

    def goAction() -> None {
        if selectedMode == "text" {
            showPrompt = True;
            return;
        }
        lastAssistantMessage = "Please use text mode to describe your situation.";
    }

    def unpackResults(results: dict) -> None {
        situationSummary = results.get("case_assessment", {}).get("value", "");
        yourRights = results.get("rights_protections", {}).get("value", "");
        toDo = results.get("urgent_steps", {}).get("value", "");
        notToDo = results.get("critical_warnings", {}).get("value", "");
        questions = results.get("follow_up_questions", {}).get("value", "");
        legalJargon = results.get("legal_glossary", {}).get("value", "");
        whoCanHelp = results.get("help_contacts", {}).get("value", "");
        whatHappensNext = results.get("process_outlook", {}).get("value", "");
        lastAssistantMessage = questions if questions != "" else "Analysis complete. See the nodes below.";
        nodesExpanded = True;
        isFollowUp = True;
    }

    async def submitPrompt() -> None {
        if not textPrompt.strip() {
            return;
        }
        isLoading = True;
        showSummary = False;
        originalInput = textPrompt.strip();

        fetch("/walker/AnalyzeSituation", {
            "method": "POST",
            "headers": {"Content-Type": "application/json"},
            "body": JSON.stringify({"user_input": originalInput})
        }).then(lambda (r: any) -> any { return r.json(); })
        .then(lambda (data: any) -> None {
            reports = data.reports if data.reports else [];
            if len(reports) > 0 {
                unpackResults(reports[0]);
            } else {
                lastAssistantMessage = "Something went wrong. Please try again.";
            }
            showPrompt = False;
            textPrompt = "";
            isLoading = False;
        }).catch(lambda (err: any) -> None {
            lastAssistantMessage = "Connection error. Please try again.";
            isLoading = False;
        });
    }

    async def submitFollowUp() -> None {
        if not followUpInput.strip() {
            return;
        }
        isLoading = True;

        fetch("/walker/FollowUp", {
            "method": "POST",
            "headers": {"Content-Type": "application/json"},
            "body": JSON.stringify({
                "original_input": originalInput,
                "follow_up_answer": followUpInput.strip()
            })
        }).then(lambda (r: any) -> any { return r.json(); })
        .then(lambda (data: any) -> None {
            if data.reports and len(data.reports) > 0 {
                result = data.reports[0];
                if result.get("limit_reached", False) {
                    caseSummary = result.get("summary", "");
                    showSummary = True;
                    isFollowUp = False;
                    lastAssistantMessage = "Summary complete. Share this with a lawyer.";
                } else {
                    unpackResults(result.get("results", result));
                }
            }
            followUpInput = "";
            isLoading = False;
        }).catch(lambda (err: any) -> None {
            lastAssistantMessage = "Connection error. Please try again.";
            isLoading = False;
        });
    }

    async def switchModel(new_model: str) -> None {
        selectedModel = new_model;
        fetch("/walker/SwitchModel", {
            "method": "POST",
            "headers": {"Content-Type": "application/json"},
            "body": JSON.stringify({"target_label": "all", "new_model": new_model})
        }).then(lambda (r: any) -> any { return r.json(); })
        .then(lambda (data: any) -> None {
            lastAssistantMessage = "Model switched to " + new_model + ".";
        });
    }

    async def resetSession() -> None {
        fetch("/walker/ResetAll", {
            "method": "POST",
            "headers": {"Content-Type": "application/json"},
            "body": JSON.stringify({})
        }).then(lambda (r: any) -> any { return r.json(); })
        .then(lambda (data: any) -> None {
            situationSummary = "";
            yourRights = "";
            toDo = "";
            notToDo = "";
            questions = "";
            legalJargon = "";
            whoCanHelp = "";
            whatHappensNext = "";
            caseSummary = "";
            nodesExpanded = False;
            showSummary = False;
            isFollowUp = False;
            originalInput = "";
            lastAssistantMessage = "Session reset. Press GO to start again.";
        });
    }

    return (
        <div className="min-h-screen bg-emerald-50 text-emerald-950">
            <div className="mx-auto max-w-5xl px-6 py-6">

                <div className="flex items-start justify-between gap-4">
                    <div className="flex flex-wrap gap-2">
                        <button className={modeButtonClass("text")} onClick={selectText}>Text</button>
                        <button className={modeButtonClass("mic")} onClick={selectMic}>Mic</button>
                        <button className={modeButtonClass("written")} onClick={selectWritten}>Written</button>
                    </div>
                    <div className="flex flex-wrap gap-2">
                        <button className={languageButtonClass("english")} onClick={selectEnglish}>English</button>
                        <button className={languageButtonClass("chinese")} onClick={selectChinese}>中文</button>
                    </div>
                </div>

                <div className="mt-4 flex flex-wrap gap-2">
                    <button className={modelButtonClass("claude-haiku-4-5-20251001")} onClick={lambda -> None { switchModel("claude-haiku-4-5-20251001"); }}>Haiku — fast</button>
                    <button className={modelButtonClass("claude-sonnet-4-6")} onClick={lambda -> None { switchModel("claude-sonnet-4-6"); }}>Sonnet — balanced</button>
                    <button className={modelButtonClass("claude-opus-4-6")} onClick={lambda -> None { switchModel("claude-opus-4-6"); }}>Opus — powerful</button>
                    <p className="ml-auto self-center text-xs text-emerald-700">Model: {selectedModel}</p>
                </div>

                <div className="mt-4 flex flex-wrap gap-3">
                    <button className="rounded-full border border-emerald-300 bg-white px-4 py-2 text-sm font-semibold text-emerald-900" onClick={enableQuietMode}>Quiet Mode</button>
                    <button className="rounded-full border border-emerald-300 bg-white px-4 py-2 text-sm font-semibold text-emerald-900" onClick={disableQuietMode}>Normal Mode</button>
                    <button className={autoEraseClass()} onClick={toggleAutoErase}>Auto-erase</button>
                    <button className="rounded-full border border-red-300 bg-white px-4 py-2 text-sm font-semibold text-red-700" onClick={resetSession}>Reset session</button>
                </div>

                <div className={quietBannerClass()}>
                    Quiet Mode is active. Press Enter to close the tab immediately if needed.
                </div>

                <div className="mt-10 flex justify-center">
                    <div className="flex h-80 w-80 items-center justify-center rounded-full border-8 border-emerald-200 bg-white shadow-xl">
                        <button className="flex h-64 w-64 items-center justify-center rounded-full bg-emerald-700 text-6xl font-black uppercase tracking-wide text-white" onClick={goAction}>GO</button>
                    </div>
                </div>

                <div className={panelClass()}>
                    <p className="text-sm font-semibold uppercase tracking-wide text-emerald-700">Describe your situation</p>
                    <textarea className="mt-3 min-h-32 w-full rounded-2xl border border-emerald-200 p-4 text-base text-emerald-950" value={textPrompt} onChange={updatePrompt} placeholder="Describe what is happening in your own words..." />
                    <div className="mt-4 flex gap-3">
                        <button className="rounded-full bg-emerald-700 px-5 py-2 text-sm font-semibold text-white" onClick={submitPrompt}>Analyze</button>
                        <button className="rounded-full border border-emerald-300 bg-white px-5 py-2 text-sm font-semibold text-emerald-900" onClick={closePrompt}>Cancel</button>
                    </div>
                </div>

                <div className="mt-8 rounded-3xl border border-emerald-200 bg-white p-5 shadow-sm">
                    <p className="text-sm font-semibold uppercase tracking-wide text-emerald-700">Status</p>
                    <p className="mt-3 text-base text-emerald-950">{statusText()}</p>
                </div>

                {nodesExpanded and not showSummary and
                    <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                        <div className="rounded-3xl border border-emerald-200 bg-white p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-emerald-700">Situation</p>
                            <p className="mt-2 text-sm text-emerald-950">{situationSummary}</p>
                        </div>
                        <div className="rounded-3xl border border-blue-200 bg-blue-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">Your rights</p>
                            <p className="mt-2 text-sm text-blue-950">{yourRights}</p>
                        </div>
                        <div className="rounded-3xl border border-emerald-200 bg-emerald-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-emerald-700">Do this now</p>
                            <p className="mt-2 text-sm text-emerald-950">{toDo}</p>
                        </div>
                        <div className="rounded-3xl border border-red-200 bg-red-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-red-700">Do not do this</p>
                            <p className="mt-2 text-sm text-red-950">{notToDo}</p>
                        </div>
                        <div className="rounded-3xl border border-amber-200 bg-amber-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-amber-700">Follow-up question</p>
                            <p className="mt-2 text-sm text-amber-950">{questions}</p>
                        </div>
                        <div className="rounded-3xl border border-purple-200 bg-purple-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-purple-700">Legal terms</p>
                            <p className="mt-2 text-sm text-purple-950">{legalJargon}</p>
                        </div>
                        <div className="rounded-3xl border border-cyan-200 bg-cyan-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-cyan-700">Who can help</p>
                            <p className="mt-2 text-sm text-cyan-950">{whoCanHelp}</p>
                        </div>
                        <div className="rounded-3xl border border-slate-200 bg-slate-50 p-5 shadow-sm">
                            <p className="text-xs font-semibold uppercase tracking-wide text-slate-700">What happens next</p>
                            <p className="mt-2 text-sm text-slate-950">{whatHappensNext}</p>
                        </div>
                    </div>
                }

                {isFollowUp and not showSummary and
                    <div className="mt-6 rounded-3xl border border-amber-200 bg-amber-50 p-5 shadow-sm">
                        <p className="text-sm font-semibold uppercase tracking-wide text-amber-700">Answer the follow-up question above</p>
                        <div className="mt-3 flex gap-3">
                            <input
                                className="w-full rounded-2xl border border-amber-200 bg-white px-4 py-3 text-sm text-emerald-950 outline-none focus:border-emerald-500"
                                value={followUpInput}
                                onChange={updateFollowUpInput}
                                placeholder="Type your answer here..."
                            />
                            <button className="rounded-2xl bg-emerald-700 px-5 py-3 text-sm font-semibold text-white" onClick={submitFollowUp}>Answer</button>
                        </div>
                    </div>
                }

                {showSummary and
                    <div className="mt-6 rounded-3xl border border-emerald-300 bg-emerald-50 p-6 shadow-sm">
                        <p className="text-sm font-semibold uppercase tracking-wide text-emerald-700">Case summary — share this with a lawyer</p>
                        <pre className="mt-3 whitespace-pre-wrap text-sm text-emerald-950">{caseSummary}</pre>
                    </div>
                }

            </div>
        </div>
    );
}
