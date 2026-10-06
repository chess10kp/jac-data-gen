import from "@jac/runtime" {
    useLocation as runtimeUseLocation,
    useNavigate as runtimeUseNavigate,
}
import from ..components.AppShell { AppShell }
import from ..components.FlairShared { PageHeader, queryValue }

def:pub StartPage() -> JsxElement {
    location = runtimeUseLocation();
    nav = runtimeUseNavigate();
    search: str = str(location["search"]) if location["search"] else "";
    target_url: str = queryValue(search, "url");

    def startAudit() -> None {
        nav("/loading?url=" + target_url);
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb="Ready" />
            <div className="flex-1 grid place-items-center px-6">
                <button onClick={startAudit} className="paper-card px-20 py-16 hover:-translate-y-1 hover:border-primary transition group">
                    <div className="font-display text-7xl tracking-tight leading-none">
                        AUDIT
                        <br />
                        <em className="italic text-primary">NOW</em>
                    </div>
                    <div className="mt-6 text-xs uppercase tracking-[0.25em] text-muted-foreground group-hover:text-foreground transition">
                        Click to begin ->
                    </div>
                </button>
            </div>
        </div>
    </AppShell>;
}
