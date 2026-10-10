import from "@jac/runtime" { __doFuncFetch }
import from shared { panel_classes }

def:pub SettingsView() -> JsxElement {
    has email: str = localStorage.getItem("rentora_email") or "";
    has twilio_number: str = "";
    has alert_number: str = localStorage.getItem("rentora_phone") or "";
    has alert_input: str = localStorage.getItem("rentora_phone") or "";
    has name: str = localStorage.getItem("rentora_name") or "";
    has name_input: str = localStorage.getItem("rentora_name") or "";
    has loading: bool = True;
    has saving_phone: bool = False;
    has save_success_phone: bool = False;
    has saving_profile: bool = False;
    has save_success_profile: bool = False;

    async def load_settings() -> None {
        loading = True;
        t = await __doFuncFetch("get_twilio_number", {});
        twilio_number = t["number"] if (t and t["number"]) else "Not configured";
        email = localStorage.getItem("rentora_email") or "";
        alert_number = localStorage.getItem("rentora_phone") or "";
        alert_input = alert_number;
        name = localStorage.getItem("rentora_name") or "";
        name_input = name;
        loading = False;
    }

    async can with entry {
        await load_settings();
    }

    async def handle_save_profile(e: any) -> None {
        e.preventDefault();
        saving_profile = True;
        save_success_profile = False;
        localStorage.setItem("rentora_name", name_input);
        name = name_input;
        saving_profile = False;
        save_success_profile = True;
    }

    async def handle_save_phone(e: any) -> None {
        e.preventDefault();
        saving_phone = True;
        save_success_phone = False;
        localStorage.setItem("rentora_phone", alert_input);
        await __doFuncFetch("set_alert_number", {"phone_number": alert_input});
        alert_number = alert_input;
        saving_phone = False;
        save_success_phone = True;
    }

    return (
        <div className="space-y-6 p-6">
            <div className={panel_classes() + " p-6"}>
                <p className="text-sm font-semibold text-slate-500">Workspace</p>
                <h1 className="mt-1 text-2xl font-semibold tracking-[-0.03em] text-slate-950">Settings</h1>
            </div>

            {loading and (
                <div className={panel_classes() + " p-6 flex items-center gap-2 text-sm text-slate-500"}>
                    <div className="h-4 w-4 rounded-full border-2 border-slate-300 border-t-slate-700 animate-spin"></div>
                    Loading...
                </div>
            )}

            {not loading and (
                <div className="space-y-6">

                    <div className={panel_classes() + " p-6"}>
                        <h2 className="text-base font-semibold text-slate-900 mb-1">Account</h2>
                        <p className="text-sm text-slate-500 mb-6">Your login credentials. Email cannot be changed here.</p>
                        <div>
                            <label className="block text-xs font-semibold text-slate-600 mb-1.5">Email</label>
                            <input
                                type="text"
                                value={email if email else "—"}
                                disabled={True}
                                className="w-full max-w-xs rounded-xl border border-slate-200 bg-slate-100 px-3.5 py-2.5 text-sm text-slate-500 cursor-not-allowed"
                            />
                        </div>
                    </div>

                    <div className={panel_classes() + " p-6"}>
                        <h2 className="text-base font-semibold text-slate-900 mb-1">Profile</h2>
                        <p className="text-sm text-slate-500 mb-6">Your display name shown across the workspace.</p>
                        <form onSubmit={handle_save_profile}>
                            <div className="space-y-4">
                                <div>
                                    <label className="block text-xs font-semibold text-slate-600 mb-1.5">Display Name</label>
                                    <div className="flex items-center gap-3">
                                        <input
                                            type="text"
                                            value={name_input}
                                            onChange={lambda (e: any) { name_input = e.target.value; save_success_profile = False; }}
                                            placeholder="Your name"
                                            className="w-full max-w-xs rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition"
                                            disabled={saving_profile}
                                        />
                                        <button
                                            type="submit"
                                            disabled={saving_profile or name_input == name}
                                            className="rounded-xl bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-40 transition shrink-0"
                                        >
                                            {("Saving..." if saving_profile else "Save")}
                                        </button>
                                    </div>
                                    {save_success_profile and (
                                        <p className="mt-2 text-xs font-medium text-emerald-600">Profile updated.</p>
                                    )}
                                </div>
                            </div>
                        </form>
                    </div>

                    <div className={panel_classes() + " p-6"}>
                        <h2 className="text-base font-semibold text-slate-900 mb-1">Phone Numbers</h2>
                        <p className="text-sm text-slate-500 mb-6">Configure the numbers used for inbound tenant texts and outbound owner alerts.</p>

                        <div className="space-y-6">
                            <div>
                                <label className="block text-xs font-semibold text-slate-600 mb-1.5">Inbound Number</label>
                                <p className="text-xs text-slate-400 mb-2">The Twilio number tenants send maintenance requests to. Set via <span className="font-mono bg-slate-100 px-1 rounded">TWILIO_PHONE_NUMBER</span> in your .env file.</p>
                                <input
                                    type="text"
                                    value={twilio_number}
                                    disabled={True}
                                    className="w-full max-w-xs rounded-xl border border-slate-200 bg-slate-100 px-3.5 py-2.5 text-sm text-slate-500 cursor-not-allowed font-mono"
                                />
                            </div>

                            <div className="border-t border-slate-100 pt-6">
                                <form onSubmit={handle_save_phone}>
                                    <label className="block text-xs font-semibold text-slate-600 mb-1.5">Alert Number</label>
                                    <p className="text-xs text-slate-400 mb-2">Your number. Receives notifications when a maintenance issue is flagged.</p>
                                    <div className="flex items-center gap-3">
                                        <input
                                            type="tel"
                                            value={alert_input}
                                            onChange={lambda (e: any) { alert_input = e.target.value; save_success_phone = False; }}
                                            placeholder="+1 555 000 0000"
                                            className="w-full max-w-xs rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2.5 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-slate-900 focus:border-transparent transition font-mono"
                                            disabled={saving_phone}
                                        />
                                        <button
                                            type="submit"
                                            disabled={saving_phone or alert_input == alert_number}
                                            className="rounded-xl bg-slate-950 px-4 py-2.5 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-40 transition shrink-0"
                                        >
                                            {("Saving..." if saving_phone else "Save")}
                                        </button>
                                    </div>
                                    {save_success_phone and (
                                        <p className="mt-2 text-xs font-medium text-emerald-600">Alert number updated.</p>
                                    )}
                                </form>
                            </div>
                        </div>
                    </div>

                </div>
            )}
        </div>
    );
}
