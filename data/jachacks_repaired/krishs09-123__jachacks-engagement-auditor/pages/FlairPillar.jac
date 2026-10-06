import from "@jac/runtime" {
    Link as RuntimeLink,
    jacIsLoggedIn as runtimeIsLoggedIn,
    useLocation as runtimeUseLocation,
    useParams as runtimeUseParams,
}
import from ..services.flair {
    FlairIssue,
    FlairPillarReport,
    FlairRecommendation,
    get_flair_pillar,
}
import from ..components.AppShell { AppShell }
import from ..components.FlairIcons { ArrowLeftIcon, CameraIcon }
import from ..components.FlairShared { PageHeader, TagRow, queryValue }

def recommendationsFor(recommendations: list[FlairRecommendation], issue_id: str) -> list[FlairRecommendation] {
    rows: list[FlairRecommendation] = [];
    for rec in recommendations {
        if rec.issue_id == issue_id {
            rows.append(rec);
        }
    }
    return rows;
}

def labelFor(pillar: str) -> str {
    if pillar == "textual" {
        return "Textual Clarity";
    }
    if pillar == "visual" {
        return "Visual Clarity";
    }
    return "Aesthetics";
}

def reportLabelFor(pillar_report: FlairPillarReport | None, pillar: str) -> str {
    if pillar_report is not None and pillar_report.pillar is not None {
        return pillar_report.pillar.label;
    }
    return labelFor(pillar);
}

def reportScoreFor(pillar_report: FlairPillarReport | None) -> int {
    if pillar_report is not None and pillar_report.pillar is not None {
        return pillar_report.pillar.score;
    }
    return 96;
}

def reportTitleFor(pillar_report: FlairPillarReport | None) -> str {
    if pillar_report is not None and pillar_report.audit is not None {
        return pillar_report.audit.name;
    }
    return "Website Name";
}

def reportIssuesFor(pillar_report: FlairPillarReport | None) -> list[FlairIssue] {
    if pillar_report is not None {
        return pillar_report.issues;
    }
    return [];
}

def reportRecommendationsFor(pillar_report: FlairPillarReport | None) -> list[FlairRecommendation] {
    if pillar_report is not None {
        return pillar_report.recommendations;
    }
    return [];
}

def issueCategoryFor(issue: FlairIssue, fallback_pillar: str) -> str {
    if len(issue.category) > 0 {
        return issue.category;
    }
    return labelFor(fallback_pillar);
}

def issueProblemFor(issue: FlairIssue) -> str {
    if len(issue.problem) > 0 {
        return issue.problem;
    }
    return issue.title;
}

def issueRecommendationFor(issue: FlairIssue, recommendations: list[FlairRecommendation]) -> str {
    if len(issue.recommendation) > 0 {
        return issue.recommendation;
    }
    for rec in recommendations {
        if rec.issue_id == issue.uid and len(rec.text) > 0 {
            return rec.text;
        }
    }
    return "Review this page element and make the recommended design change explicit.";
}

def issueTargetFor(issue: FlairIssue) -> str {
    if len(issue.target_element) > 0 and len(issue.location) > 0 {
        return issue.target_element + " - " + issue.location;
    }
    if len(issue.target_element) > 0 {
        return issue.target_element;
    }
    if len(issue.location) > 0 {
        return issue.location;
    }
    return "Specific page element";
}

def:pub FlairPillarPage() -> JsxElement {
    has pillar_report: FlairPillarReport | None = None;
    params = runtimeUseParams();
    pillar_value = params["pillar"];
    pillar: str = str(pillar_value) if pillar_value else "aesthetics";
    location = runtimeUseLocation();
    search: str = str(location["search"]) if location["search"] else "";
    audit_id: str = queryValue(search, "audit");

    async def loadPillar() -> None {
        if not runtimeIsLoggedIn() {
            return;
        }
        loaded_report: FlairPillarReport | None = None;
        loaded_report = await get_flair_pillar(audit_id, pillar);
        pillar_report = loaded_report;
    }

    async can with entry {
        await loadPillar();
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb={"Report / " + reportLabelFor(pillar_report, pillar)} />
            <div className="px-6 py-10 max-w-6xl mx-auto w-full">
                <RuntimeLink to={"/report?audit=" + audit_id} className="inline-flex items-center gap-1 text-xs uppercase tracking-widest text-muted-foreground hover:text-foreground transition">
                    <ArrowLeftIcon className="w-3 h-3" /> back to report
                </RuntimeLink>

                <div className="mt-6 text-center">
                    <div className="text-xs uppercase tracking-[0.25em] text-muted-foreground mb-2">
                        {reportTitleFor(pillar_report) + " - Audit Report"}
                    </div>
                    <div className="mt-3 inline-flex items-center gap-4">
                        <div className="relative w-20 h-20">
                            <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
                                <circle cx="50" cy="50" r="40" fill="none" stroke="var(--surface)" strokeWidth="8" />
                                <circle cx="50" cy="50" r="40" fill="none" stroke="var(--primary)" strokeWidth="8" strokeLinecap="round" strokeDasharray={str((float(reportScoreFor(pillar_report)) / 100.0) * 251.2) + " 251.2"} />
                            </svg>
                            <div className="absolute inset-0 grid place-items-center font-display text-lg leading-none">
                                {reportScoreFor(pillar_report)}
                            </div>
                        </div>
                        <h1 className="font-display text-5xl tracking-tight">
                            {reportLabelFor(pillar_report, pillar) + " - "} <em className="italic text-primary">{str(reportScoreFor(pillar_report)) + "/100"}</em>
                        </h1>
                    </div>
                </div>

                <div className="mt-14 space-y-5">
                    {[<article key={reportIssuesFor(pillar_report)[i].uid} className="paper-card p-6">
                        <div className="flex flex-wrap items-center justify-between gap-3">
                            <div className="text-xs uppercase tracking-[0.18em] text-muted-foreground">
                                {issueCategoryFor(reportIssuesFor(pillar_report)[i], pillar) + ", " + reportIssuesFor(pillar_report)[i].priority + ", " + reportIssuesFor(pillar_report)[i].element}
                            </div>
                            <div className="font-mono text-xs text-muted-foreground">{"#" + str(reportIssuesFor(pillar_report)[i].issue_number)}</div>
                        </div>

                        <div className="mt-5">
                            <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Target</div>
                            <p className="mt-2 text-base leading-relaxed">{issueTargetFor(reportIssuesFor(pillar_report)[i])}</p>
                            {len(reportIssuesFor(pillar_report)[i].visible_text) > 0 and <p className="mt-1 text-sm text-muted-foreground">{"Visible text: " + reportIssuesFor(pillar_report)[i].visible_text}</p>}
                        </div>

                        <div className="mt-5 grid gap-5 md:grid-cols-2">
                            <div>
                                <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Problem</div>
                                <p className="mt-2 font-display text-xl leading-tight">{issueProblemFor(reportIssuesFor(pillar_report)[i])}</p>
                            </div>
                            <div>
                                <div className="text-xs uppercase tracking-[0.16em] text-muted-foreground">Recommendation</div>
                                <p className="mt-2 text-base leading-relaxed">{issueRecommendationFor(reportIssuesFor(pillar_report)[i], reportRecommendationsFor(pillar_report))}</p>
                            </div>
                        </div>

                        <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
                            <TagRow priority={reportIssuesFor(pillar_report)[i].priority} element={reportIssuesFor(pillar_report)[i].element} />
                            <RuntimeLink
                                to={"/evidence/" + reportIssuesFor(pillar_report)[i].uid + "?audit=" + audit_id + "&pillar=" + pillar}
                                className="inline-flex items-center gap-1 text-xs hover:text-primary transition"
                            >
                                <CameraIcon className="w-3 h-3" /> view captured evidence ->
                            </RuntimeLink>
                        </div>
                    </article> for i in range(len(reportIssuesFor(pillar_report)))]}

                    {len(reportIssuesFor(pillar_report)) == 0 and <div className="paper-card p-8 mt-8 text-center text-muted-foreground">
                        No issues captured yet.
                    </div>}
                </div>
            </div>
        </div>
    </AppShell>;
}
