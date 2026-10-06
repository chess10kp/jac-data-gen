import from "@jac/runtime" { useNavigate as runtimeUseNavigate }
import from ..components.AppShell { AppShell }
import from ..components.FlairIcons { ArrowRightIcon }
import from ..components.FlairShared { PageHeader }

def:pub AuditInputPage() -> JsxElement {
    has url: str = "";
    nav = runtimeUseNavigate();

    def handleInput(e: ChangeEvent) -> None {
        url = e.target.value;
    }

    def submit(e: FormEvent) -> None {
        e.preventDefault();
        if len(url.strip()) > 0 {
            nav("/start?url=" + url.strip());
        }
    }

    return <AppShell>
        <div className="min-h-screen flex flex-col">
            <PageHeader crumb="New audit" />
            <div className="flex-1 grid place-items-center px-6">
                <div className="w-full max-w-2xl text-center">
                    <div className="text-xs uppercase tracking-[0.25em] text-muted-foreground mb-6">
                        Insert link to audit:
                    </div>
                    <form onSubmit={submit} className="paper-card p-2 flex items-center gap-2">
                        <input
                            type="url"
                            required={True}
                            value={url}
                            onChange={handleInput}
                            placeholder="paste link"
                            className="flex-1 bg-transparent outline-none px-4 py-4 text-center text-lg placeholder:text-muted-foreground/60"
                        />
                        <button type="submit" className="w-12 h-12 grid place-items-center rounded-[calc(var(--radius)-4px)] bg-primary text-primary-foreground hover:opacity-90 transition" aria-label="Continue">
                            <ArrowRightIcon className="w-5 h-5" />
                        </button>
                    </form>
                    <p className="mt-3 text-xs text-muted-foreground">* Must be a valid, public domain link.</p>
                </div>
            </div>
        </div>
    </AppShell>;
}
