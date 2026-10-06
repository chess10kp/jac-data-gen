import from "@jac/runtime" {
    Navigate as RuntimeNavigate,
    Link as RuntimeLink,
    jacIsLoggedIn as runtimeIsLoggedIn,
    jacLogout as runtimeLogout,
    useLocation as runtimeUseLocation,
    useNavigate as runtimeUseNavigate,
}
import from ..services.flair { FlairUserProfileResult, get_flair_user_profile }
import from .FlairIcons { FileTextIcon, LogOutIcon, MenuIcon, PlusIcon, SparklesIcon }

def:pub AppShell(auditId: str = "", children: JsxElement = None) -> JsxElement {
    has open: bool = False;
    has username: str = "@user";
    location = runtimeUseLocation();
    nav = runtimeUseNavigate();
    path: str = str(location["pathname"]) if location["pathname"] else "";

    async can with entry {
        if runtimeIsLoggedIn() {
            result: FlairUserProfileResult | None = None;
            result = await get_flair_user_profile();
            if result is not None and result.ok and result.profile is not None {
                username = result.profile.username;
            }
        }
    }

    def toggleMenu() -> None {
        open = not open;
    }

    def handleLogout(e: MouseEvent) -> None {
        runtimeLogout();
        nav("/");
    }

    if not runtimeIsLoggedIn() {
        return <RuntimeNavigate to="/" replace={True} />;
    }

    return <div className="min-h-screen bg-background text-foreground flex">
        <aside className={(("w-64" if open else "w-16") + " shrink-0 bg-surface border-r border-border flex flex-col transition-[width] duration-300 ease-out")}>
            <div className="p-3 flex items-center gap-2">
                <button
                    onClick={toggleMenu}
                    aria-label="Toggle menu"
                    className="w-10 h-10 grid place-items-center rounded-md hover:bg-background transition"
                >
                    <MenuIcon className="w-5 h-5" />
                </button>
                {open and <RuntimeLink to="/audit" className="flex items-center gap-2">
                    <span className="relative inline-flex items-center justify-center w-7 h-7 rounded-full bg-primary">
                        <SparklesIcon className="w-3.5 h-3.5 text-primary-foreground" />
                    </span>
                    <span className="font-display text-2xl leading-none">FLAIR</span>
                </RuntimeLink>}
            </div>

            <nav className="px-2 mt-4 flex-1 space-y-1">
                <RuntimeLink
                    to="/audit"
                    className={"flex items-center gap-3 px-3 h-10 rounded-md text-sm transition " + ("bg-background text-foreground" if path == "/audit" else "text-muted-foreground hover:bg-background hover:text-foreground")}
                >
                    <PlusIcon className="w-4 h-4" />
                    {open and <span>New audit</span>}
                </RuntimeLink>
                <RuntimeLink
                    to="/audits"
                    className={"flex items-center gap-3 px-3 h-10 rounded-md text-sm transition " + ("bg-background text-foreground" if path.startswith("/audits") else "text-muted-foreground hover:bg-background hover:text-foreground")}
                >
                    <FileTextIcon className="w-4 h-4" />
                    {open and <span>Audits</span>}
                </RuntimeLink>
            </nav>

            <div className="p-3 border-t border-border">
                {open and <div>
                    <div className="text-sm font-medium">{username}</div>
                    <button onClick={handleLogout} className="text-xs text-muted-foreground hover:text-foreground inline-flex items-center gap-1">
                        <LogOutIcon className="w-3 h-3" /> Logout
                    </button>
                </div>}
                {not open and <button onClick={handleLogout} className="w-10 h-10 grid place-items-center rounded-md hover:bg-background transition" aria-label="Logout">
                    <LogOutIcon className="w-4 h-4" />
                </button>}
            </div>
        </aside>

        <main className="flex-1 min-w-0">
            {children}
        </main>
    </div>;
}
