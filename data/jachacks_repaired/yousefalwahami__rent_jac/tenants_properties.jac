import from "@jac/runtime" { __doFuncFetch, __doWalkerFetch }
import from shared { panel_classes }

def:pub TenantsPropertiesView() -> JsxElement {
    has properties: any = [];
    has tenants: any = [];
    has tab: str = "Properties";
    has loading: bool = False;
    has error_msg: str = "";
    has show_prop_modal: bool = False;
    has show_tenant_modal: bool = False;

    has form_prop_name: str = "";
    has form_prop_address: str = "";
    has form_prop_notes: str = "";
    has form_prop_tags: str = "";
    has edit_prop_id: str = "";

    has form_tenant_name: str = "";
    has form_tenant_phone: str = "";
    has form_tenant_email: str = "";
    has form_tenant_unit: str = "";
    has form_tenant_prop_id: str = "";
    has form_tenant_rent: str = "1200";
    has form_tenant_notes: str = "";
    has form_tenant_tags: str = "";
    has edit_tenant_id: str = "";
    has toast_msg: str = "";

    def ls_load(key: str) -> any {
        try {
            raw = localStorage.getItem(key);
            if raw { return JSON.parse(raw); }
        } except Exception {}
        return [];
    }

    def ls_save(key: str, val: list) -> None {
        try { localStorage.setItem(key, JSON.stringify(val)); } except Exception {}
    }

    def show_toast(msg: str) -> None {
        toast_msg = msg;
        setTimeout(lambda () -> None { toast_msg = ""; }, 3000);
    }

    has _loaded: bool = False;

    async def reload() -> None {
        loading = True;
        try {
            props_res = await __doWalkerFetch("fetch_properties", "", {});
            properties = props_res["reports"][0]["properties"] if (props_res and props_res["reports"] and props_res["reports"][0]) else [];
            tenants_res = await __doWalkerFetch("fetch_tenants", "", {});
            tenants = tenants_res["reports"][0]["tenants"] if (tenants_res and tenants_res["reports"] and tenants_res["reports"][0]) else [];
        } except Exception as e {
            error_msg = "Failed to load: " + str(e);
        }
        loading = False;
    }

    async def init() -> None {
        try { await __doWalkerFetch("seed_if_empty", "", {}); } except Exception {}
        await reload();
    }

    async can with entry {
        if not _loaded {
            _loaded = True;
            init();
        }
    }

    async def save_property() -> None {
        if not form_prop_name { return; }
        try {
            await __doWalkerFetch("save_property_data", "", {"name": form_prop_name, "address": form_prop_address});
            show_toast(edit_prop_id and "Property updated" or "Property added");
        } except Exception as e {
            error_msg = "Save failed: " + str(e);
            return;
        }
        show_prop_modal = False;
        form_prop_name = "";
        form_prop_address = "";
        form_prop_notes = "";
        form_prop_tags = "";
        edit_prop_id = "";
        await reload();
    }

    async def delete_property(p_id: str) -> None {
        if window.confirm("Delete this property and all its tenants?") {
            try { await __doFuncFetch("delete_property_data", {"property_id": p_id}); } except Exception {}
            show_toast("Property deleted");
            await reload();
        }
    }

    async def save_tenant() -> None {
        if not form_tenant_name or not form_tenant_phone or not form_tenant_unit {
            error_msg = "Name, phone, and unit are required.";
            return;
        }
        prop_name = "";
        for p in properties {
            if p["id"] == form_tenant_prop_id { prop_name = p["name"]; break; }
        }
        try {
            rent_f = 0.0;
            try { rent_f = float(form_tenant_rent); } except Exception {}
            await __doWalkerFetch("save_tenant_data", "", {
                "tenant_name": form_tenant_name,
                "tenant_phone": form_tenant_phone,
                "unit_number": form_tenant_unit,
                "rent_amount": rent_f,
                "property_name": prop_name
            });
            show_toast(edit_tenant_id and "Tenant updated" or "Tenant added");
        } except Exception as e {
            error_msg = "Save failed: " + str(e);
            return;
        }
        show_tenant_modal = False;
        form_tenant_name = "";
        form_tenant_phone = "";
        form_tenant_email = "";
        form_tenant_unit = "";
        form_tenant_prop_id = "";
        form_tenant_rent = "1200";
        form_tenant_notes = "";
        form_tenant_tags = "";
        edit_tenant_id = "";
        await reload();
    }

    async def delete_tenant(t_id: str) -> None {
        if window.confirm("Remove this tenant?") {
            try { await __doFuncFetch("delete_tenant_data", {"tenant_id": t_id}); } except Exception {}
            show_toast("Tenant removed");
            await reload();
        }
    }

    return (
        <div className="p-8 max-w-5xl mx-auto h-full overflow-y-auto w-full relative">
            {toast_msg and (
                <div className="fixed bottom-4 right-4 bg-slate-800 text-white px-4 py-2 rounded shadow-lg text-sm z-50 animate-pop">
                    {toast_msg}
                </div>
            )}
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-2xl font-semibold text-slate-900 tracking-tight">Tenants & Properties</h1>
                    <p className="text-sm text-slate-500 mt-1">Stored in graph. Tenant phones are used for automatic SMS triage matching.</p>
                </div>
                <div className="flex gap-3">
                    <button onClick={lambda () -> None { edit_prop_id = ""; form_prop_name = ""; form_prop_address = ""; form_prop_tags = ""; form_prop_notes = ""; show_prop_modal = True; }} className="bg-white border border-slate-200 px-4 py-2 rounded-md shadow-sm text-sm font-medium hover:bg-slate-50 transition">
                        Add Property
                    </button>
                    <button onClick={lambda () -> None { edit_tenant_id = ""; form_tenant_name = ""; form_tenant_phone = ""; form_tenant_email = ""; form_tenant_unit = ""; form_tenant_prop_id = (properties[0]["id"] if len(properties) > 0 else ""); form_tenant_tags = ""; form_tenant_notes = ""; show_tenant_modal = True; }} className="bg-slate-900 text-white px-4 py-2 rounded-md shadow-sm text-sm font-medium hover:bg-slate-800 transition">
                        Add Tenant
                    </button>
                </div>
            </div>

            {error_msg and (
                <div className="mb-5 bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3 text-sm flex items-center justify-between">
                    <span>{error_msg}</span>
                    <button onClick={lambda () -> None { error_msg = ""; }} className="ml-4 text-red-400 hover:text-red-700 font-bold text-lg leading-none">&times;</button>
                </div>
            )}

            <div className="flex gap-6 border-b border-slate-200 mb-6">
                <button onClick={lambda () -> None { tab = "Properties"; }} className={"pb-3 text-sm font-medium transition-colors border-b-2 " + str(tab == "Properties" and "border-slate-900 text-slate-900" or "border-transparent text-slate-500 hover:text-slate-700")}>
                    Properties ({len(properties)})
                </button>
                <button onClick={lambda () -> None { tab = "Tenants"; }} className={"pb-3 text-sm font-medium transition-colors border-b-2 " + str(tab == "Tenants" and "border-slate-900 text-slate-900" or "border-transparent text-slate-500 hover:text-slate-700")}>
                    Tenants ({len(tenants)})
                </button>
            </div>

            {loading and (
                <div className="flex items-center justify-center py-12 text-slate-400 text-sm gap-2">
                    <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10" opacity="0.25"/><path d="M12 2a10 10 0 0 1 10 10" strokeLinecap="round"/></svg>
                    Loading...
                </div>
            )}

            {not loading and tab == "Properties" and (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                    {len(properties) == 0 and (
                        <div className="col-span-full bg-slate-50 border border-dashed border-slate-300 rounded-xl p-12 flex flex-col items-center justify-center text-center">
                            <h3 className="text-slate-900 font-medium mb-1">No properties yet</h3>
                            <p className="text-slate-500 text-sm mb-4">Add your first property to start managing tenants.</p>
                            <button onClick={lambda () -> None { edit_prop_id = ""; form_prop_name = ""; form_prop_address = ""; form_prop_tags = ""; form_prop_notes = ""; show_prop_modal = True; }} className="text-sm font-medium text-slate-900 bg-white border border-slate-200 px-4 py-2 rounded-md shadow-sm">Add Property</button>
                        </div>
                    )}
                    {properties.map(lambda (p: any) -> JsxElement {
                        t_count = len([t for t in tenants if "property_id" in t and "id" in p and t["property_id"] == p["id"]]);
                        return (
                            <div key={p["id"]} className={panel_classes() + " p-5 flex flex-col group relative hover:border-slate-300 transition"}>
                                <div className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
                                    <button onClick={lambda () -> None { edit_prop_id = p["id"]; form_prop_name = p["name"]; form_prop_address = (p["address"] if p["address"] else ""); form_prop_notes = (p["notes"] if p["notes"] else ""); form_prop_tags = ",".join(p["tags"] if p["tags"] else []); show_prop_modal = True; }} className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded" title="Edit">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                                    </button>
                                    <button onClick={lambda () -> None { delete_property(p["id"]); }} className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded" title="Delete">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                                    </button>
                                </div>
                                <h3 className="font-semibold text-slate-900 pr-8 mb-2">{p["name"]}</h3>
                                <p className="text-sm text-slate-500 mb-6">{p["address"] if p["address"] else "No address"}</p>
                                <div className="mt-auto pt-4 border-t border-slate-100 flex justify-between items-center text-xs font-medium text-slate-600">
                                    <span>{str(t_count) + " " + str(t_count == 1 and "Tenant" or "Tenants")}</span>
                                    <button onClick={lambda () -> None { tab = "Tenants"; }} className="text-slate-500 hover:text-slate-900 flex items-center gap-1">View Tenants <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"></path><path d="m12 5 7 7-7 7"></path></svg></button>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

            {not loading and tab == "Tenants" and (
                <div className={panel_classes() + " overflow-hidden"}>
                    {len(tenants) == 0 and (
                        <div className="p-12 text-center flex flex-col items-center bg-slate-50 m-2 rounded-lg border border-dashed border-slate-200">
                            <h3 className="text-slate-900 font-medium mb-1">No tenants yet</h3>
                            <p className="text-slate-500 text-sm mb-4">Add a tenant to enable automatic SMS matching.</p>
                            <button onClick={lambda () -> None { edit_tenant_id = ""; form_tenant_name = ""; form_tenant_phone = ""; form_tenant_email = ""; form_tenant_unit = ""; form_tenant_prop_id = (properties[0]["id"] if len(properties) > 0 else ""); form_tenant_tags = ""; form_tenant_notes = ""; show_tenant_modal = True; }} className="text-sm font-medium text-slate-900 bg-white border border-slate-200 px-4 py-2 rounded-md shadow-sm">Add Tenant</button>
                        </div>
                    )}
                    {len(tenants) > 0 and (
                        <table className="w-full text-left text-sm">
                            <thead className="bg-slate-50 text-slate-500 text-xs uppercase tracking-wider">
                                <tr className="border-b border-slate-200">
                                    <th className="px-6 py-3 font-medium">Tenant</th>
                                    <th className="px-6 py-3 font-medium">Phone</th>
                                    <th className="px-6 py-3 font-medium">Unit</th>
                                    <th className="px-6 py-3 font-medium">Property</th>
                                    <th className="px-6 py-3 font-medium">Rent</th>
                                    <th className="px-6 py-3"></th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-100">
                                {tenants.map(lambda (t: any) -> JsxElement {
                                    t_id = t["id"] if "id" in t else "";
                                    t_name = t["full_name"] if "full_name" in t else (t["name"] if "name" in t else "Unknown");
                                    t_initial = t_name[0].upper() if len(t_name) > 0 else "?";
                                    t_phone = t["phone_number"] if "phone_number" in t else (t["phone"] if "phone" in t else "");
                                    t_unit = t["unit_number"] if "unit_number" in t else (t["unit"] if "unit" in t else "");
                                    t_prop_name = t["property_name"] if "property_name" in t else "—";
                                    t_prop_id = t["property_id"] if "property_id" in t else "";
                                    t_rent = t["rent"] if "rent" in t else (t["rent_amount"] if "rent_amount" in t else 0);
                                    t_email = t["email"] if "email" in t else "";
                                    t_notes = t["notes"] if "notes" in t else "";
                                    t_tags = t["tags"] if "tags" in t else [];

                                    return (
                                        <tr key={t_id} className="hover:bg-slate-50/50 group">
                                            <td className="px-6 py-4 font-medium text-slate-900">
                                                <div className="flex items-center gap-3">
                                                    <div className="w-7 h-7 rounded-full bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-semibold shrink-0">
                                                        {t_initial}
                                                    </div>
                                                    {t_name}
                                                </div>
                                            </td>
                                            <td className="px-6 py-4 font-mono text-slate-500 text-xs">{t_phone}</td>
                                            <td className="px-6 py-4"><span className="px-2 py-0.5 rounded bg-slate-100 border border-slate-200 text-xs font-mono font-medium">{t_unit}</span></td>
                                            <td className="px-6 py-4 text-slate-600 text-xs">{t_prop_name}</td>
                                            <td className="px-6 py-4 text-slate-600 text-xs">${t_rent}/mo</td>
                                            <td className="px-6 py-4 text-right">
                                                <div className="flex items-center justify-end gap-1">
                                                    <button onClick={lambda () -> None { edit_tenant_id = t_id; form_tenant_name = t_name; form_tenant_phone = t_phone; form_tenant_email = t_email; form_tenant_unit = t_unit; form_tenant_prop_id = t_prop_id; form_tenant_rent = str(t_rent); form_tenant_notes = t_notes; form_tenant_tags = ",".join(t_tags); show_tenant_modal = True; }} className="p-1.5 text-slate-300 hover:text-slate-600 hover:bg-slate-100 rounded opacity-0 group-hover:opacity-100 transition-opacity" title="Edit">
                                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                                                    </button>
                                                    <button onClick={lambda () -> None { delete_tenant(t_id); }} className="p-1.5 text-slate-300 hover:text-red-600 hover:bg-red-50 rounded opacity-0 group-hover:opacity-100 transition-opacity" title="Remove">
                                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    )}
                </div>
            )}

            {show_prop_modal and (
                <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
                    <div className={"w-full max-w-md shadow-xl " + panel_classes() + " p-6"}>
                        <h2 className="text-lg font-semibold text-slate-900 mb-5">{'Edit Property' if edit_prop_id else 'Add New Property'}</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Property Name</label>
                                <input value={form_prop_name} onChange={lambda (e: any) -> None { form_prop_name = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="e.g. Harbor Point Residences" autoFocus={True} />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Street Address</label>
                                <input value={form_prop_address} onChange={lambda (e: any) -> None { form_prop_address = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="123 Main St" />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Notes</label>
                                <input value={form_prop_notes} onChange={lambda (e: any) -> None { form_prop_notes = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="Optional notes" />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Tags (comma-separated)</label>
                                <input value={form_prop_tags} onChange={lambda (e: any) -> None { form_prop_tags = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="e.g. residential, downtown" />
                            </div>
                        </div>
                        <div className="mt-6 flex gap-3 justify-end">
                            <button onClick={lambda () -> None { show_prop_modal = False; edit_prop_id = ""; }} className="px-4 py-2 rounded-md font-medium text-slate-600 hover:bg-slate-100 text-sm transition">Cancel</button>
                            <button onClick={save_property} disabled={not form_prop_name} className="px-4 py-2 rounded-md text-sm font-medium bg-slate-900 text-white hover:bg-slate-800 transition disabled:opacity-50">{'Save Changes' if edit_prop_id else 'Save'}</button>
                        </div>
                    </div>
                </div>
            )}

            {show_tenant_modal and (
                <div className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
                    <div className={"w-full max-w-md shadow-xl " + panel_classes() + " p-6"}>
                        <h2 className="text-lg font-semibold text-slate-900 mb-5">{'Edit Tenant' if edit_tenant_id else 'Add Tenant'}</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Full Name</label>
                                <input value={form_tenant_name} onChange={lambda (e: any) -> None { form_tenant_name = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="e.g. Maya Chen" autoFocus={True} />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Phone Number</label>
                                <input value={form_tenant_phone} onChange={lambda (e: any) -> None { form_tenant_phone = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 font-mono transition-shadow" placeholder="+15551234567" />
                                <p className="text-[10px] text-slate-400 mt-1">Must match exactly the number they text from. Use +1 format.</p>
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Email</label>
                                <input value={form_tenant_email} onChange={lambda (e: any) -> None { form_tenant_email = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="tenant@email.com" />
                            </div>
                            <div className="flex gap-3">
                                <div className="flex-1">
                                    <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Unit</label>
                                    <input value={form_tenant_unit} onChange={lambda (e: any) -> None { form_tenant_unit = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 font-mono transition-shadow" placeholder="3D" />
                                </div>
                                <div className="flex-1">
                                    <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Monthly Rent ($)</label>
                                    <input type="number" value={form_tenant_rent} onChange={lambda (e: any) -> None { form_tenant_rent = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="1200" />
                                </div>
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Property</label>
                                <select value={form_tenant_prop_id} onChange={lambda (e: any) -> None { form_tenant_prop_id = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 bg-white transition-shadow">
                                    <option value="">Select property...</option>
                                    {properties.map(lambda (p: any) -> JsxElement {
                                        return <option key={p["id"]} value={p["id"]}>{p["name"]}</option>;
                                    })}
                                </select>
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Notes</label>
                                <input value={form_tenant_notes} onChange={lambda (e: any) -> None { form_tenant_notes = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="Optional notes" />
                            </div>
                            <div>
                                <label className="block text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2">Tags (comma-separated)</label>
                                <input value={form_tenant_tags} onChange={lambda (e: any) -> None { form_tenant_tags = e.target.value; }} className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-slate-900 transition-shadow" placeholder="e.g. long-term, commercial" />
                            </div>
                        </div>
                        <div className="mt-6 flex gap-3 justify-end">
                            <button onClick={lambda () -> None { show_tenant_modal = False; edit_tenant_id = ""; }} className="px-4 py-2 rounded-md font-medium text-slate-600 hover:bg-slate-100 text-sm transition">Cancel</button>
                            <button onClick={save_tenant} disabled={not form_tenant_name or not form_tenant_phone or not form_tenant_unit} className="px-4 py-2 rounded-md text-sm font-medium bg-slate-900 text-white hover:bg-slate-800 transition disabled:opacity-50">{'Save Changes' if edit_tenant_id else 'Save Tenant'}</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
