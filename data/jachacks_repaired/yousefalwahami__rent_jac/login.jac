import from "@jac/runtime" { jacLogin, jacSignup }
import from shared { panel_classes }

def:pub LoginView(props: dict) -> JsxElement {
    has mode: str = "login";
    has email: str = "";
    has password: str = "";
    has alert_number: str = "";
    has loading: bool = False;
    has error: str = "";
    on_auth_success = props["on_auth_success"] if (props and "on_auth_success" in props) else None;

    async def handle_submit(e: any) -> None {
        e.preventDefault();
        if not email or not password {
            error = "Please fill in all fields";
            return;
        }
        loading = True;
        error = "";
        if mode == "login" {
            try {
                success = await jacLogin(email, password);
                loading = False;
                if success {
                    if on_auth_success {
                        on_auth_success();
                    }
                } else {
                    error = "Invalid email or password";
                }
            } except Exception as ex {
                loading = False;
                error = "Invalid email or password";
            }
        } else {
            try {
                result = await jacSignup(email, password);
                loading = False;
                if result["success"] {
                    localStorage.setItem("rentora_email", email);
                    if alert_number {
                        localStorage.setItem("rentora_phone", alert_number);
                    }
                    if on_auth_success {
                        on_auth_success();
                    }
                } else {
                    err = result["error"];
                    error = str(err["message"]) if (err and err["message"]) else (str(err) if err else "Registration failed");
                }
            } except Exception as ex {
                loading = False;
                error = "Registration failed";
            }
        }
    }

    return (
        <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
            <div className="w-full max-w-sm">
                <div className="flex items-center gap-3 justify-center mb-8">
                    <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-900 text-white text-sm font-semibold shadow-sm">
                        R
                    </div>
                    <div>
                        <h1 className="text-[15px] font-semibold tracking-tight text-slate-900">Rentora</h1>
                        <p className="text-[12px] text-slate-500">Property Management</p>
                    </div>
                </div>

                <div className={panel_classes() + " p-8"}>
                    <div className="mb-6">
                        <h2 className="text-xl font-semibold tracking-[-0.03em] text-slate-950">
                            {("Welcome back" if mode == "login" else "Create account")}
                        </h2>
                        <p className="mt-1 text-sm text-slate-500">
                            {("Sign in to your Rentora account" if mode == "login" else "Set up your workspace in seconds")}
                        </p>
                    </div>

                    <form onSubmit={handle_submit} className="space-y-4">
                        <div>
                            <label className="block text-xs font-semibold text-slate-600 mb-1.5">Email</label>
                            <input
                                type="text"
                                value={email}
                                onChange={lambda (e: any) { email = e.target.value; }}
                                placeholder="you@example.com"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition"
                                disabled={loading}
                            />
                        </div>

                        <div>
                            <label className="block text-xs font-semibold text-slate-600 mb-1.5">Password</label>
                            <input
                                type="password"
                                value={password}
                                onChange={lambda (e: any) { password = e.target.value; }}
                                placeholder="••••••••"
                                className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition"
                                disabled={loading}
                            />
                        </div>

                        {mode == "register" and (
                            <div>
                                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Alert Number</label>
                                <input
                                    type="tel"
                                    value={alert_number}
                                    onChange={lambda (e: any) { alert_number = e.target.value; }}
                                    placeholder="+1 555 000 0000"
                                    className="w-full rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition"
                                    disabled={loading}
                                />
                                <p className="mt-1.5 text-xs text-slate-400">The number that receives maintenance alerts. You can change this later in Settings.</p>
                            </div>
                        )}

                        {error and (
                            <div className="rounded-xl bg-red-50 border border-red-200 px-3.5 py-2.5">
                                <p className="text-xs font-medium text-red-700">{error}</p>
                            </div>
                        )}

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full rounded-xl bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:opacity-90 disabled:opacity-50 transition mt-2"
                        >
                            {(("Signing in..." if mode == "login" else "Creating account...") if loading else ("Sign in" if mode == "login" else "Create account"))}
                        </button>
                    </form>

                    <p className="mt-5 text-center text-xs text-slate-500">
                        {("Don't have an account? " if mode == "login" else "Already have an account? ")}
                        <button
                            onClick={lambda () -> None { mode = ("register" if mode == "login" else "login"); error = ""; }}
                            className="font-semibold text-slate-900 hover:underline cursor-pointer"
                        >
                            {("Sign up" if mode == "login" else "Sign in")}
                        </button>
                    </p>
                </div>
            </div>
        </div>
    );
}
