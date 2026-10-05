import from "@jac/runtime" { jacSignup, jacLogin, jacLogout, jacIsLoggedIn }
import from main { create_merchant, list_merchants, add_merchant_wallet, list_merchant_wallets, delete_merchant_wallet }
import from .WalletCreateForm { WalletCreateForm }

import ".styles.global.css";

def:pub app -> JsxElement {
    has route: str = "landing";
    has is_logged_in: bool = False;
    has merchant_id: str = "";
    has legal_name: str = "";
    has display_name: str = "";
    has email: str = "";
    has password: str = "";
    has status: str = "active";
    has default_chain: str = "base";
    has default_asset: str = "USDC";
    has wallets: list = [];
    has auth_error: str = "";

    async def sync_merchant_profile -> str;
    async def ensure_merchant_profile -> str;
    async def sync_wallets(merchant_ref: str = "");
    async def login_submit;
    async def signup_submit;
    async def remove_wallet(wallet_id: str);
    def logout;
    def go_landing;
    def go_login;
    def go_signup;
    def go_dashboard;

    can with entry {
        is_logged_in = jacIsLoggedIn();
        if is_logged_in {
            route = "dashboard";
        }
    }

    can with [is_logged_in] entry {
        if is_logged_in {
            sync_merchant_profile();
            if route == "landing" or route == "login" or route == "signup" {
                route = "dashboard";
            }
        }
    }

    welcome_text = "Welcome back, Merchant";
    if display_name.strip() {
        welcome_text = "Welcome back, " + display_name;
    } elif legal_name.strip() {
        welcome_text = "Welcome back, " + legal_name;
    }

    dashboard_email = "founder@merchant.com";
    if email.strip() {
        dashboard_email = email;
    }

    return <div className="min-h-screen bg-background text-foreground">
        <div className="mx-auto flex min-h-screen w-full max-w-7xl flex-col px-6 py-6 sm:px-8 lg:px-10">
            <header className="flex flex-col gap-4 rounded-[2rem] border border-white/10 bg-white/5 px-6 py-5 shadow-soft backdrop-blur md:flex-row md:items-center md:justify-between">
                <button className="flex items-center gap-3 text-left" onClick={go_landing}>
                    <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-cyan-400 to-blue-500 text-lg font-bold text-slate-950"><span>J</span></div>
                    <div>
                        <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Jac settlement</span></p>
                        <p className="text-lg font-semibold text-white"><span>Merchant Portal</span></p>
                    </div>
                </button>
                <nav className="flex flex-wrap items-center gap-3 text-sm">
                    {(not is_logged_in) and (<button className="rounded-full border border-white/10 px-4 py-2 text-slate-200 transition hover:bg-white/10" onClick={go_login}><span>Login</span></button>)}
                    {(not is_logged_in) and (<button className="rounded-full bg-primary px-4 py-2 font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={go_signup}><span>Sign up</span></button>)}
                    {is_logged_in and (<button className="rounded-full bg-primary px-4 py-2 font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={go_dashboard}><span>Dashboard</span></button>)}
                </nav>
            </header>

            <main className="flex-1 space-y-8 py-10">
                {route == "landing" and (
                    <section className="grid gap-10 lg:grid-cols-[1.1fr_0.9fr] lg:items-center">
                        <div className="space-y-6">
                            <div className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-medium uppercase tracking-[0.28em] text-cyan-200">
                                <span>Base Sepolia ready</span>
                            </div>
                            <div className="space-y-4">
                                <h1 className="max-w-3xl text-5xl font-semibold tracking-tight text-white sm:text-6xl">
                                    <span>Accept fiat, settle in USDC, and keep every payout traceable.</span>
                                </h1>
                                <p className="max-w-2xl text-lg leading-8 text-slate-300">
                                    <span>Sign up for a private merchant workspace backed by Jac graph persistence.</span>
                                </p>
                            </div>
                            <div className="flex flex-col gap-3 sm:flex-row">
                                <button className="rounded-2xl bg-primary px-6 py-3 text-sm font-semibold text-primary-foreground shadow-card transition hover:-translate-y-0.5 hover:bg-primary/90" onClick={go_signup}>
                                    <span>Create account</span>
                                </button>
                                <button className="rounded-2xl border border-white/15 bg-white/5 px-6 py-3 text-sm font-semibold text-white transition hover:bg-white/10" onClick={go_login}>
                                    <span>Log in</span>
                                </button>
                            </div>
                        </div>
                        <div className="rounded-[2rem] border border-cyan-400/20 bg-slate-950/60 p-6 shadow-card backdrop-blur">
                            <div className="rounded-[1.5rem] border border-white/10 bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 p-6">
                                <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Private roots</span></p>
                                <h2 className="mt-2 text-2xl font-semibold text-white"><span>Each merchant gets isolated data.</span></h2>
                                <p className="mt-4 text-sm leading-7 text-slate-300"><span>Signup and login create a private Jac session so each merchant only sees their own invoices, wallets, and payouts.</span></p>
                            </div>
                        </div>
                    </section>
                )}

                {route == "login" and (
                    <div className="mx-auto w-full max-w-md rounded-[2rem] border border-white/10 bg-card/90 p-8 shadow-card backdrop-blur">
                        <div className="space-y-2">
                            <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Welcome back</span></p>
                            <h2 className="text-3xl font-semibold text-white"><span>Log in to your account</span></h2>
                        </div>
                        <div className="mt-8 space-y-5">
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-200"><span>Email</span></label>
                                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={email} onInput={lambda (e: InputEvent) { email = e.target.value; }} placeholder="founder@merchant.com" />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-200"><span>Password</span></label>
                                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" type="password" value={password} onInput={lambda (e: InputEvent) { password = e.target.value; }} placeholder="••••••••••••" />
                            </div>
                            {(auth_error != "") and (<p className="text-sm text-rose-300">{auth_error}</p>)}
                            <button className="w-full rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={login_submit}>
                                <span>Log in</span>
                            </button>
                            <button className="w-full rounded-2xl border border-white/10 bg-white/5 px-5 py-3 text-sm font-semibold text-white transition hover:bg-white/10" onClick={go_landing}>
                                <span>Back to landing</span>
                            </button>
                        </div>
                    </div>
                )}

                {route == "signup" and (
                    <div className="mx-auto w-full max-w-2xl rounded-[2rem] border border-white/10 bg-card/90 p-8 shadow-card backdrop-blur">
                        <div className="space-y-2">
                            <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Get started</span></p>
                            <h2 className="text-3xl font-semibold text-white"><span>Create a merchant account</span></h2>
                        </div>
                        <div className="mt-8 grid gap-5 sm:grid-cols-2">
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-200"><span>Legal name</span></label>
                                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={legal_name} onInput={lambda (e: InputEvent) { legal_name = e.target.value; }} placeholder="Acme Commerce LLC" />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-200"><span>Screen name</span></label>
                                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={display_name} onInput={lambda (e: InputEvent) { display_name = e.target.value; }} placeholder="Acme" />
                            </div>
                            <div className="space-y-2 sm:col-span-2">
                                <label className="text-sm font-medium text-slate-200"><span>Email</span></label>
                                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={email} onInput={lambda (e: InputEvent) { email = e.target.value; }} placeholder="ops@acme.com" />
                            </div>
                            <div className="space-y-2 sm:col-span-2">
                                <label className="text-sm font-medium text-slate-200"><span>Password</span></label>
                                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" type="password" value={password} onInput={lambda (e: InputEvent) { password = e.target.value; }} placeholder="Create a password" />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-400"><span>Account status</span></label>
                                <input className="w-full cursor-default rounded-2xl border border-white/5 bg-slate-950/40 px-4 py-3 text-slate-400 outline-none" value={status} disabled={True} />
                            </div>
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-400"><span>Default chain</span></label>
                                <input className="w-full cursor-default rounded-2xl border border-white/5 bg-slate-950/40 px-4 py-3 text-slate-400 outline-none" value={default_chain} disabled={True} />
                            </div>
                            <div className="space-y-2 sm:col-span-2">
                                <label className="text-sm font-medium text-slate-400"><span>Settlement asset</span></label>
                                <input className="w-full cursor-default rounded-2xl border border-white/5 bg-slate-950/40 px-4 py-3 text-slate-400 outline-none" value={default_asset} disabled={True} />
                            </div>
                            <div className="sm:col-span-2 grid gap-3">
                                {(auth_error != "") and (<p className="text-sm text-rose-300">{auth_error}</p>)}
                                <button className="w-full rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90" onClick={signup_submit}>
                                    <span>Create account</span>
                                </button>
                                <button className="w-full rounded-2xl border border-white/10 bg-white/5 px-5 py-3 text-sm font-semibold text-white transition hover:bg-white/10" onClick={go_landing}>
                                    <span>Back to landing</span>
                                </button>
                            </div>
                        </div>
                    </div>
                )}

                {route == "dashboard" and (
                    <div className="space-y-8">
                        <div className="flex flex-col gap-4 rounded-[2rem] border border-white/10 bg-card/90 p-8 shadow-card backdrop-blur lg:flex-row lg:items-center lg:justify-between">
                            <div>
                                <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Merchant dashboard</span></p>
                                <h1 className="mt-3 text-4xl font-semibold text-white">{welcome_text}</h1>
                                <p className="mt-3 max-w-2xl text-slate-300"><span>This account is now backed by a private root graph. The merchant profile you create is only visible in this authenticated session.</span></p>
                            </div>
                            <div className="flex flex-wrap gap-3">
                                <button className="rounded-2xl border border-white/10 bg-white/5 px-5 py-3 text-sm font-semibold text-white transition hover:bg-white/10" onClick={logout}>
                                    <span>Log out</span>
                                </button>
                            </div>
                        </div>
                        <div className="grid gap-4 md:grid-cols-3">
                            <div className="rounded-[1.75rem] border border-white/10 bg-white/5 p-6 shadow-soft">
                                <p className="text-sm text-slate-400"><span>Merchant ID</span></p>
                                <p className="mt-3 break-all font-mono text-sm font-semibold text-white">{merchant_id or "Not loaded"}</p>
                            </div>
                            <div className="rounded-[1.75rem] border border-white/10 bg-white/5 p-6 shadow-soft">
                                <p className="text-sm text-slate-400"><span>Email</span></p>
                                <p className="mt-3 text-xl font-semibold text-white">{dashboard_email}</p>
                            </div>
                            <div className="rounded-[1.75rem] border border-white/10 bg-white/5 p-6 shadow-soft">
                                <p className="text-sm text-slate-400"><span>Preferred chain</span></p>
                                <p className="mt-3 text-xl font-semibold text-white">{default_chain}</p>
                            </div>
                            <div className="rounded-[1.75rem] border border-white/10 bg-white/5 p-6 shadow-soft">
                                <p className="text-sm text-slate-400"><span>Settlement asset</span></p>
                                <p className="mt-3 text-xl font-semibold text-white">{default_asset}</p>
                            </div>
                        </div>
                        <div className="grid gap-6 lg:grid-cols-[0.95fr_1.05fr]">
                            <WalletCreateForm props={{
                                "merchant_id": merchant_id,
                                "default_chain": default_chain,
                                "default_asset": default_asset,
                                "ensureMerchantProfile": lambda { ensure_merchant_profile(); },
                                "refreshWallets": lambda (merchant_ref: str) { sync_wallets(merchant_ref); },
                            }} />
                            <div className="rounded-[2rem] border border-white/10 bg-card/90 p-8 shadow-card">
                                <div className="flex items-center justify-between gap-4">
                                    <div>
                                        <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Merchant wallets</span></p>
                                        <h2 className="mt-2 text-2xl font-semibold text-white"><span>Active payout destinations</span></h2>
                                    </div>
                                    <div className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-slate-200">
                                        <span>{str(len(wallets))} wallets</span>
                                    </div>
                                </div>
                                <div className="mt-6 space-y-4">
                                    {(len(wallets) == 0) and (
                                        <div className="rounded-2xl border border-dashed border-white/10 bg-white/5 p-6 text-sm text-slate-300">
                                            <span>No wallets yet. Generate your first managed wallet to start routing payouts.</span>
                                        </div>
                                    )}
                                    {[
                                        <div key={wallet.wallet_id} className="rounded-2xl border border-white/10 bg-white/5 p-5">
                                            <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                                                <div className="space-y-2">
                                                    <div className="flex flex-wrap items-center gap-2">
                                                        <p className="text-lg font-semibold text-white">{wallet.label or "Wallet"}</p>
                                                        {wallet.is_default and (
                                                            <span className="rounded-full border border-cyan-400/20 bg-cyan-400/10 px-3 py-1 text-xs font-medium text-cyan-200"><span>Default</span></span>
                                                        )}
                                                    </div>
                                                    <p className="break-all font-mono text-xs text-slate-400"><span>Wallet ID: </span>{wallet.wallet_id}</p>
                                                    <p className="break-all font-mono text-sm text-slate-300">{wallet.address}</p>
                                                    <div className="flex flex-wrap gap-3 text-sm text-slate-400">
                                                        <span>{wallet.chain}</span>
                                                        <span>{wallet.asset}</span>
                                                        <span>{wallet.status}</span>
                                                    </div>
                                                </div>
                                                <button className="rounded-2xl border border-rose-400/20 bg-rose-400/10 px-4 py-2 text-sm font-semibold text-rose-200 transition hover:bg-rose-400/20" onClick={lambda { remove_wallet(wallet.wallet_id); }}>
                                                    <span>Delete</span>
                                                </button>
                                            </div>
                                        </div> for wallet in wallets
                                    ]}
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </main>
        </div>
    </div>;
}
