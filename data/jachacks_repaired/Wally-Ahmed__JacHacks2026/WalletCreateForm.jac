import from main { add_merchant_wallet }

def:pub WalletCreateForm(props: dict) -> JsxElement {
    form_props = props["props"] or props;

    has wallet_label: str = "";
    has wallet_chain: str = form_props["default_chain"] or "base";
    has wallet_asset: str = form_props["default_asset"] or "USDC";
    has form_error: str = "";
    has is_submitting: bool = False;

    async def submit_wallet {
        form_error = "";
        resolved_merchant_id = str(form_props["merchant_id"] or "").strip();
        if not resolved_merchant_id {
            resolved_merchant_id = await form_props["ensureMerchantProfile"]();
        }
        if not resolved_merchant_id {
            form_error = "No merchant profile was found for this session.";
            return;
        }

        label_value = str(wallet_label).strip();
        chain_value = str(wallet_chain).strip();
        asset_value = str(wallet_asset).strip();

        if not chain_value {
            chain_value = "base";
        }
        if not asset_value {
            asset_value = "USDC";
        }
        if not label_value {
            label_value = "wallet";
        }

        is_submitting = True;
        form_error = "Submitting wallet request...";
        await add_merchant_wallet(
            resolved_merchant_id,
            chain_value,
            asset_value,
            label_value,
        );
        wallet_label = "";
        wallet_chain = form_props["default_chain"] or "base";
        wallet_asset = form_props["default_asset"] or "USDC";
        form_error = "";
        is_submitting = False;
        window.location.reload();
    }

    return <div className="rounded-[2rem] border border-white/10 bg-card/90 p-8 shadow-card">
        <p className="text-sm uppercase tracking-[0.28em] text-cyan-200"><span>Generate wallet</span></p>
        <h2 className="mt-2 text-2xl font-semibold text-white"><span>Create a managed merchant wallet</span></h2>
        <div className="mt-6 space-y-4">
            <div className="space-y-2">
                <label className="text-sm font-medium text-slate-200"><span>Label</span></label>
                <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={str(wallet_label)} onInput={lambda (e: InputEvent) { wallet_label = e.target.value; }} placeholder="Treasury wallet" />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-200"><span>Chain</span></label>
                    <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={str(wallet_chain)} onInput={lambda (e: InputEvent) { wallet_chain = e.target.value; }} placeholder="base" />
                </div>
                <div className="space-y-2">
                    <label className="text-sm font-medium text-slate-200"><span>Asset</span></label>
                    <input className="w-full rounded-2xl border border-white/10 bg-slate-950/70 px-4 py-3 text-white outline-none transition focus:border-cyan-400/60 focus:ring-2 focus:ring-cyan-400/20" value={str(wallet_asset)} onInput={lambda (e: InputEvent) { wallet_asset = e.target.value; }} placeholder="USDC" />
                </div>
            </div>
            {(form_error != "") and (<p className="text-sm text-rose-300">{form_error}</p>)}
            <button className="w-full rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground transition hover:bg-primary/90 disabled:cursor-not-allowed disabled:opacity-70" onClick={lambda { submit_wallet(); }} disabled={is_submitting}>
                <span>{("Generating wallet..." if is_submitting else "Generate wallet")}</span>
            </button>
        </div>
    </div>;
}
