import from "@jac/runtime" {
    Link as RuntimeLink,
    jacIsLoggedIn as runtimeIsLoggedIn,
    useLocation as runtimeUseLocation,
    useParams as runtimeUseParams,
}
import from ..services.flair { FlairEvidenceView, get_flair_evidence }
import from ..components.AppShell { AppShell }
import from ..components.FlairIcons { ArrowLeftIcon }
import from ..components.FlairShared { PageHeader, queryValue }

def screenshotsFor(view: FlairEvidenceView | None) -> list[str] {
    if view is not None and view.issue is not None {
        if len(view.issue.screenshot_data_urls) > 0 {
            return view.issue.screenshot_data_urls;
        }
        if len(view.issue.screenshot_data_url) > 0 {
            return [view.issue.screenshot_data_url];
        }
    }
    return [];
}

def issueNumberFor(view: FlairEvidenceView | None, fallback: str) -> str {
    if view is not None and view.issue is not None {
        return str(view.issue.issue_number);
    }
    return fallback;
}

def issueSummaryFor(view: FlairEvidenceView | None) -> str {
    if view is not None and view.issue is not None {
        category: str = view.issue.category if len(view.issue.category) > 0 else view.issue.pillar;
        return category + ", " + view.issue.priority + ", " + view.issue.element;
    }
    return "Issue";
}

def issueProblemFor(view: FlairEvidenceView | None) -> str {
    if view is not None and view.issue is not None {
        if len(view.issue.problem) > 0 {
            return view.issue.problem;
        }
        return view.issue.title;
    }
    return "";
}

def issueRecommendationFor(view: FlairEvidenceView | None) -> str {
    if view is not None and view.issue is not None {
        if len(view.issue.recommendation) > 0 {
            return view.issue.recommendation;
        }
        for rec in view.recommendations {
            if rec.issue_id == view.issue.uid and len(rec.text) > 0 {
                return rec.text;
            }
        }
    }
    return "";
}

def issueTargetFor(view: FlairEvidenceView | None) -> str {
    if view is not None and view.issue is not None {
        if len(view.issue.target_element) > 0 and len(view.issue.location) > 0 {
            return view.issue.target_element + " - " + view.issue.location;
        }
        if len(view.issue.target_element) > 0 {
            return view.issue.target_element;
        }
        if len(view.issue.location) > 0 {
            return view.issue.location;
        }
    }
    return "";
}

def evidenceNotesFor(view: FlairEvidenceView | None) -> list[str] {
    notes: list[str] = [];
    if view is not None and view.issue is not None {
        if len(view.issue.screenshot_observation) > 0 {
            notes.append(view.issue.screenshot_observation);
        }
        if len(view.issue.crawler_text_observation) > 0 {
            notes.append(view.issue.crawler_text_observation);
        }
    }
    return notes;
}

def:pub EvidenceDetailPage() -> JsxElement {
    has view: FlairEvidenceView | None = None;
    params = runtimeUseParams();
    id_value = params["id"];
    id_text: str = str(id_value) if id_value else "1";
    location = runtimeUseLocation();
    search: str = str(location["search"]) if location["search"] else "";
    audit_id: str = queryValue(search, "audit");
    pillar: str = queryValue(search, "pillar");

    async def loadEvidence() -> None {
        if not runtimeIsLoggedIn() {
            return;
        }
        loaded_view: FlairEvidenceView | None = None;
        loaded_view = await get_flair_evidence(id_text);
        view = loaded_view;
    }

    async can with entry {
        await loadEvidence();
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb={"Evidence / Issue #" + issueNumberFor(view, id_text)} />
            <div className="px-6 py-10 max-w-4xl mx-auto w-full">
                <RuntimeLink to={"/report/" + pillar + "?audit=" + audit_id} className="inline-flex items-center gap-1 text-xs uppercase tracking-widest text-muted-foreground hover:text-foreground transition">
                    <ArrowLeftIcon className="w-3 h-3" /> back
                </RuntimeLink>

                <h1 className="mt-6 font-display text-4xl text-center tracking-tight">
                    Captured Evidence for Issue <em className="italic text-primary">{"#" + issueNumberFor(view, id_text)}</em>
                </h1>

                <div className="mt-10 paper-card p-6">
                    <div className="text-xs uppercase tracking-[0.2em] text-muted-foreground mb-3">
                        Captured screenshots
                    </div>
                    <div className="flex flex-col gap-4">
                        {[<div key={str(i)} className="w-full aspect-[16/9] rounded-md bg-surface border border-border overflow-hidden">
                            <img src={screenshotsFor(view)[i]} alt={"captured evidence screenshot " + str(i + 1)} className="w-full h-full object-cover" />
                        </div> for i in range(len(screenshotsFor(view)))]}
                        {len(screenshotsFor(view)) == 0 and <div className="w-full aspect-[16/9] rounded-md bg-surface border border-border grid place-items-center text-muted-foreground text-sm">
                            <span>No screenshot evidence was captured for this issue.</span>
                        </div>}
                    </div>
                </div>

                {view is not None and view.issue is not None and <div className="mt-6 paper-card p-6">
                    <div className="text-xs uppercase tracking-[0.2em] text-muted-foreground">
                        {issueSummaryFor(view)}
                    </div>
                    {len(issueTargetFor(view)) > 0 and <div className="mt-5">
                        <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Target</div>
                        <p className="mt-2 text-base leading-relaxed">{issueTargetFor(view)}</p>
                        {view is not None and view.issue is not None and len(view.issue.visible_text) > 0 and <p className="mt-1 text-sm text-muted-foreground">{"Visible text: " + view.issue.visible_text}</p>}
                    </div>}
                    <div className="mt-5 grid gap-5 md:grid-cols-2">
                        <div>
                            <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Problem</div>
                            <p className="mt-2 font-display text-xl leading-tight">{issueProblemFor(view)}</p>
                        </div>
                        <div>
                            <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Recommendation</div>
                            <p className="mt-2 text-base leading-relaxed">{issueRecommendationFor(view)}</p>
                        </div>
                    </div>

                    {len(evidenceNotesFor(view)) > 0 and <div className="mt-6">
                        <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Evidence Notes</div>
                        <div className="mt-3 space-y-2">
                            {[<p key={str(i)} className="text-sm text-muted-foreground leading-relaxed">{evidenceNotesFor(view)[i]}</p> for i in range(len(evidenceNotesFor(view)))]}
                        </div>
                    </div>}
                </div>}
            </div>
        </div>
    </AppShell>;
}
