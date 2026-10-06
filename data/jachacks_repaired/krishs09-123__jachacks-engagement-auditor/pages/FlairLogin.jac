import from "@jac/runtime" {
    Navigate as RuntimeNavigate,
    Link as RuntimeLink,
    jacIsLoggedIn as runtimeIsLoggedIn,
    jacLogin as runtimeLogin,
    jacSignup as runtimeSignup,
    useNavigate as runtimeUseNavigate,
}
import from ..services.flair { FlairUserProfileResult, save_flair_user_profile }
import from ..components.FlairIcons { ArrowRightIcon, EyeIcon, EyeOffIcon, SparklesIcon }

def:pub FlairLoginPage(initialMode: str = "signin") -> JsxElement {
    has mode: str = "signup" if initialMode == "signup" else "signin";
    has email: str = "";
    has password: str = "";
    has confirm_password: str = "";
    has error: str = "";
    has loading: bool = False;
    has showPassword: bool = False;
    nav = runtimeUseNavigate();

    def toggleMode() -> None {
        mode = "signup" if mode == "signin" else "signin";
        error = "";
        password = "";
        confirm_password = "";
    }

    def togglePassword() -> None {
        showPassword = not showPassword;
    }

    def handleEmail(e: ChangeEvent) -> None {
        email = e.target.value;
    }

    def handlePassword(e: ChangeEvent) -> None {
        password = e.target.value;
    }

    def handleConfirmPassword(e: ChangeEvent) -> None {
        confirm_password = e.target.value;
    }

    async def submit(e: FormEvent) -> None {
        e.preventDefault();
        if loading {
            return;
        }
        error = "";
        clean_email: str = email.strip().lower();
        if len(clean_email) == 0 or clean_email.find("@") <= 0 {
            error = "Enter a valid email address.";
            return;
        }
        if len(password) < 6 {
            error = "Password must be at least 6 characters.";
            return;
        }
        if mode == "signup" and password != confirm_password {
            error = "Passwords do not match.";
            return;
        }
        loading = True;
        login_ok: bool = False;
        if mode == "signup" {
            signup_result: dict | None = None;
            signup_success: bool = False;
            signup_result = await runtimeSignup(clean_email, password);
            if signup_result {
                try {
                    signup_success = bool(signup_result["success"]);
                } except Exception as signup_error {
                    signup_success = False;
                }
            }
            if not signup_success {
                error = "Could not create that account. It may already exist.";
                loading = False;
                return;
            }
            login_ok = await runtimeLogin(clean_email, password);
        } else {
            login_ok = await runtimeLogin(clean_email, password);
        }
        if login_ok {
            profile_result: FlairUserProfileResult | None = None;
            profile_result = await save_flair_user_profile(clean_email);
            nav("/audit");
        } else {
            error = "Invalid email or password. Create an account first, then sign in with those credentials.";
        }
        loading = False;
    }

    if runtimeIsLoggedIn() {
        return <RuntimeNavigate to="/audit" replace={True} />;
    }

    return <div className="min-h-screen bg-background text-foreground flex flex-col">
        <div className="mx-auto w-full max-w-7xl px-6 py-6 flex items-center justify-between">
            <RuntimeLink to="/" className="flex items-center gap-2">
                <span className="relative inline-flex items-center justify-center w-8 h-8 rounded-full bg-primary">
                    <span className="absolute inset-0 rounded-full bg-primary animate-pulse-ring" />
                    <SparklesIcon className="w-4 h-4 text-primary-foreground relative" />
                </span>
                <span className="font-display text-2xl leading-none">Flair</span>
            </RuntimeLink>
        </div>

        <main className="flex-1 grid place-items-center px-6 pb-16">
            <div className="paper-card w-full max-w-md p-10">
                <div className="text-xs uppercase tracking-[0.2em] text-muted-foreground mb-4">
                    {"Welcome back" if mode == "signin" else "Make an account"}
                </div>
                <h1 className="font-display text-5xl leading-[0.95] tracking-tight">
                    Sign <em className="italic text-primary">{"in" if mode == "signin" else "up"}</em>
                </h1>
                <p className="mt-4 text-muted-foreground">
                    Audits, but with flair. Paste a link, get a designer-grade report.
                </p>

                <form onSubmit={submit} className="mt-8 space-y-3">
                    <label className="block">
                        <span className="text-xs uppercase tracking-widest text-muted-foreground">Email</span>
                        <input
                            type="email"
                            required={True}
                            value={email}
                            onChange={handleEmail}
                            placeholder="you@studio.com"
                            className="mt-1.5 w-full bg-surface border border-border rounded-md px-4 py-3 outline-none focus:border-primary"
                        />
                    </label>
                    <label className="block">
                        <span className="text-xs uppercase tracking-widest text-muted-foreground">Password</span>
                        <div className="relative mt-1.5">
                            <input
                                type={"text" if showPassword else "password"}
                                required={True}
                                value={password}
                                onChange={handlePassword}
                                placeholder="********"
                                className="w-full bg-surface border border-border rounded-md px-4 py-3 pr-11 outline-none focus:border-primary"
                            />
                            <button
                                type="button"
                                onClick={togglePassword}
                                aria-label={"Hide password" if showPassword else "Show password"}
                                className="absolute right-2 top-1/2 -translate-y-1/2 w-9 h-9 grid place-items-center rounded-md text-muted-foreground hover:text-foreground hover:bg-background/60 transition"
                            >
                                {showPassword and <EyeOffIcon className="w-4 h-4" />}
                                {not showPassword and <EyeIcon className="w-4 h-4" />}
                            </button>
                        </div>
                    </label>
                    {mode == "signup" and <label className="block">
                        <span className="text-xs uppercase tracking-widest text-muted-foreground">Confirm password</span>
                        <input
                            type={"text" if showPassword else "password"}
                            required={True}
                            value={confirm_password}
                            onChange={handleConfirmPassword}
                            placeholder="********"
                            className="mt-1.5 w-full bg-surface border border-border rounded-md px-4 py-3 outline-none focus:border-primary"
                        />
                    </label>}
                    {error != "" and <div className="rounded-md border border-destructive/30 bg-destructive/10 px-4 py-3 text-sm text-foreground">
                        {error}
                    </div>}
                    <button
                        type="submit"
                        disabled={loading}
                        className="group w-full mt-3 inline-flex items-center justify-center gap-2 bg-primary text-primary-foreground rounded-md px-5 py-3 font-medium hover:opacity-90 transition"
                    >
                        {"Signing in..." if loading and mode == "signin" else ("Creating account..." if loading else ("Sign in" if mode == "signin" else "Create account"))}
                        <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition" />
                    </button>
                </form>

                <button onClick={toggleMode} className="mt-6 text-sm text-muted-foreground hover:text-foreground transition">
                    {"No account? Sign up ->" if mode == "signin" else "Have an account? Sign in ->"}
                </button>
            </div>
        </main>
    </div>;
}
