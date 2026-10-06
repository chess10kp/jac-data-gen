import from "@jac/runtime" {
    jacIsLoggedIn as runtimeIsLoggedIn,
    useLocation as runtimeUseLocation,
    useNavigate as runtimeUseNavigate,
}
import from ..services.flair { FlairAuditMutationResult, create_flair_audit }
import from ..components.AppShell { AppShell }
import from ..components.FlairIcons { LoaderIcon }
import from ..components.FlairShared { PageHeader, queryValue }

def:pub LoadingPage() -> JsxElement {
    has error: str = "";
    location = runtimeUseLocation();
    nav = runtimeUseNavigate();
    search: str = str(location["search"]) if location["search"] else "";
    target_url: str = queryValue(search, "url");

    async def runAudit() -> None {
        if not runtimeIsLoggedIn() {
            return;
        }
        if len(target_url) == 0 {
            nav("/audit");
            return;
        }
        result: FlairAuditMutationResult | None = None;
        result = await create_flair_audit(target_url);
        if result is not None and result.ok and result.audit is not None {
            nav("/report?audit=" + result.audit.uid);
            return;
        }
        if result is not None {
            error = result.message;
        } else {
            error = "Audit failed.";
        }
    }

    async can with entry {
        await runAudit();
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb="Auditing" />
            <div className="flex-1 grid place-items-center px-6">
                <div className="text-center">
                    <div className="inline-flex items-center gap-3 paper-card px-8 py-5">
                        <LoaderIcon className="w-5 h-5 animate-spin text-primary" />
                        <span className="font-display text-3xl italic">loading...</span>
                    </div>
                    <div className="mt-8 font-display text-2xl italic text-muted-foreground transition-opacity duration-500 flair-phrase-cycle">
                        <span>(measuring whitespace...)</span>
                        <span>(reading between the lines...)</span>
                        <span>(checking contrast ratios...)</span>
                        <span>(judging your font pairings gently...)</span>
                        <span>(looking for vibes...)</span>
                    </div>
                    {error != "" and <div className="mt-6 paper-card p-5 text-sm text-muted-foreground">
                        {error}
                    </div>}
                </div>
            </div>
        </div>
    </AppShell>;
}
