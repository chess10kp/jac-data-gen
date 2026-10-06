import from "@jac/runtime" {
    jacIsLoggedIn as runtimeIsLoggedIn,
    useLocation as runtimeUseLocation,
}
import from ..services.flair { FlairReport, FlairPillarSummary, get_flair_report }
import from ..components.AppShell { AppShell }
import from ..components.FlairShared { PageHeader, ScorePillar, queryValue }

def scoreFor(pillars: list[FlairPillarSummary], key: str, fallback: int) -> int {
    for pillar in pillars {
        if pillar.pillar == key {
            return pillar.score;
        }
    }
    return fallback;
}

def titleFor(audit_report: FlairReport | None) -> str {
    if audit_report is not None and audit_report.audit is not None {
        return audit_report.audit.name;
    }
    return "Website Name";
}

def crawledUrlFor(audit_report: FlairReport | None) -> str {
    if audit_report is not None and audit_report.audit is not None {
        return audit_report.audit.target_url;
    }
    return "https://specific-url-crawled.com/";
}

def pillarScoreFor(audit_report: FlairReport | None, key: str, fallback: int) -> int {
    if audit_report is not None and audit_report.audit is not None {
        return scoreFor(audit_report.pillars, key, fallback);
    }
    return fallback;
}

def:pub ReportOverviewPage() -> JsxElement {
    has audit_report: FlairReport | None = None;
    has loading: bool = True;
    location = runtimeUseLocation();
    search: str = str(location["search"]) if location["search"] else "";
    audit_id: str = queryValue(search, "audit");

    async def loadReport() -> None {
        if not runtimeIsLoggedIn() {
            return;
        }
        loaded_report: FlairReport | None = None;
        loaded_report = await get_flair_report(audit_id);
        audit_report = loaded_report;
        loading = False;
    }

    async can with entry {
        await loadReport();
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb="Audit report" />
            <div className="px-6 py-10">
                <div className="text-center">
                    <div className="text-xs uppercase tracking-[0.25em] text-muted-foreground mb-2">
                        {titleFor(audit_report) + " - Audit Report"}
                    </div>
                    <div className="text-sm font-mono text-muted-foreground">
                        {crawledUrlFor(audit_report)}
                    </div>
                    {loading and <div className="mt-4 text-sm text-muted-foreground">Loading report...</div>}
                </div>

                <div className="mt-16 max-w-4xl mx-auto relative">
                    <div className="flex justify-center">
                        <ScorePillar destination={"/report/aesthetics?audit=" + audit_id} label="Aesthetics" score={pillarScoreFor(audit_report, "aesthetics", 96)} />
                    </div>

                    <svg viewBox="0 0 600 200" className="w-full h-40 my-2 text-foreground/30" fill="none" stroke="currentColor" strokeWidth="1.5">
                        <path d="M 300 0 C 300 80, 140 80, 140 180" />
                        <path d="M 300 0 C 300 80, 460 80, 460 180" />
                        <polyline points="135,170 140,180 145,170" />
                        <polyline points="455,170 460,180 465,170" />
                    </svg>

                    <div className="grid grid-cols-2 gap-12 max-w-2xl mx-auto -mt-4">
                        <ScorePillar destination={"/report/textual?audit=" + audit_id} label="Textual Clarity" score={pillarScoreFor(audit_report, "textual", 88)} />
                        <ScorePillar destination={"/report/visual?audit=" + audit_id} label="Visual Clarity" score={pillarScoreFor(audit_report, "visual", 92)} />
                    </div>
                </div>
            </div>
        </div>
    </AppShell>;
}
