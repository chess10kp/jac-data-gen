# ── NODE DEFINITIONS ─────────────────────

node UserProfile {
    has name: str = "Ramesh";
    has age: int = 78;
    has mode: str = "normal";
    has preferred_check_in_time: str = "09:00";
    has medical_conditions: list = [];
    has medications: list = [];
    has alert_threshold_hours: int = 4;
    has family_contacts: list = [];
    has sos_contact_name: str = "";
    has sos_contact_phone: str = "";
}

node MedicationNode {
    has med_name: str;
    has dose: str;
    has time: str;
    has taken: bool = False;
}

node CheckInNode {
    has mood: str = "";
    has logged_at: str = "";
    has notes: str = "";
}

# ── PROFILE WALKERS ──────────────────────

walker:pub get_profile {
    has skip_init: bool = False;

    can fetch with entry {
        for p in [-->][?:UserProfile] {
            report p;
            disengage;
        }
        if not self.skip_init {
            p = UserProfile(name="Ramesh", age=78, mode="normal");
            here ++> p;
            report p;
        }
    }
}

walker:pub toggle_mode {
    has new_mode: str;

    can update with entry {
        for p in [-->][?:UserProfile] {
            p.mode = self.new_mode;
        }
        report {"mode": self.new_mode, "status": "updated"};
    }
}

walker:pub set_alert_threshold {
    has hours: int;

    can update with entry {
        for p in [-->][?:UserProfile] {
            p.alert_threshold_hours = self.hours;
        }
        report {"threshold": self.hours, "status": "updated"};
    }
}

# ── CHECK-IN WALKERS ─────────────────────

walker:pub log_checkin {
    has mood: str;
    has notes: str = "";

    can save with entry {
        checkin = CheckInNode(mood=self.mood, logged_at="today", notes=self.notes);
        here ++> checkin;
        report {"status": "saved", "mood": self.mood};
    }
}

walker:pub get_checkins {
    can fetch with entry {
        checkins = [-->][?:CheckInNode];
        report checkins;
    }
}

# ── MEDICATION WALKERS ───────────────────

walker:pub schedule_med {
    has med_name: str;
    has dose: str;
    has time: str;

    can create with entry {
        med = MedicationNode(med_name=self.med_name, dose=self.dose, time=self.time);
        here ++> med;
        report {"status": "scheduled", "med_name": self.med_name, "time": self.time};
    }
}

walker:pub mark_med_taken {
    has med_name: str;

    can update with entry {
        for m in [-->][?:MedicationNode] {
            if m.med_name == self.med_name {
                m.taken = True;
            }
        }
        report {"status": "done", "med_name": self.med_name};
    }
}

walker:pub get_med_schedule {
    has skip_init: bool = False;

    can fetch with entry {
        meds = [-->][?:MedicationNode];
        if not self.skip_init and len(meds) == 0 {
            here ++> MedicationNode(med_name="Aspirin", dose="100mg", time="08:00");
            here ++> MedicationNode(med_name="Metformin", dose="500mg", time="12:00");
            here ++> MedicationNode(med_name="Atorvastatin", dose="20mg", time="20:00");
            meds = [-->][?:MedicationNode];
        }
        report meds;
    }
}

walker:pub check_missed_meds {
    can check with entry {
        import datetime;
        now = str(datetime.datetime.now().strftime("%H:%M"));
        missed = [];
        for m in [-->][?:MedicationNode] {
            if not m.taken and m.time < now {
                missed.append({"med_name": m.med_name, "time": m.time});
            }
        }
        report {"missed": missed};
    }
}

# ── SOS WALKERS ──────────────────────────

walker:pub add_family_contact {
    has name: str;
    has contact: str;
    has notify_on_sos: bool = True;

    can save with entry {
        for p in [-->][?:UserProfile] {
            p.family_contacts.append(
                {
                    "name": self.name,
                    "contact": self.contact,
                    "notify_on_sos": self.notify_on_sos
                }
            );
        }
        report {"status": "added", "name": self.name};
    }
}

walker:pub trigger_sos {
    can alert with entry {
        for p in [-->][?:UserProfile] {
            report {
                "sos": True,
                "message": "SOS: " + p.name + " needs immediate help!",
                "contacts": p.family_contacts,
                "sos_contact": {
                    "name": p.sos_contact_name,
                    "phone": p.sos_contact_phone
                }
            };
        }
    }
}

walker:pub set_sos_contact {
    has name: str;
    has phone: str;

    can update with entry {
        for p in [-->][?:UserProfile] {
            p.sos_contact_name = self.name;
            p.sos_contact_phone = self.phone;
        }
        report {"status": "updated", "name": self.name, "phone": self.phone};
    }
}

# ── INITIALIZATION ───────────────────────

with entry {
    grant(root, level="WRITE");
    root ++> UserProfile(name="Ramesh", age=78, mode="normal");
    root ++> MedicationNode(med_name="Aspirin", dose="100mg", time="08:00");
    root ++> MedicationNode(med_name="Metformin", dose="500mg", time="12:00");
    root ++> MedicationNode(med_name="Atorvastatin", dose="20mg", time="20:00");
    root ++> CheckInNode(mood="good", logged_at="today");
    print("Granny Care initialized.");
}

# ── CLIENT FRONTEND ──────────────────────

def:pub app() -> JsxElement {
    has mode: str = "normal";
    has user_name: str = "";
    has meds: list = [];
    has checkins: list = [];
    has taken_count: int = 0;
    has missed_meds: list = [];
    has sos_fired: bool = False;
    has alert_msg: str = "";
    has greeting: str = "Good evening";
    has tab: str = "home";
    has is_desktop: bool = False;

    async can with entry {
        doc_head: any = document.head;
        l1: any = document.createElement("link");
        l1.rel = "stylesheet";
        l1.href = "https://fonts.googleapis.com/css2?family=Literata:wght@400;500;600;700&family=Nunito+Sans:wght@400;600;700&family=Lora:wght@400;500;600;700&display=swap";
        doc_head.appendChild(l1);
        l2: any = document.createElement("link");
        l2.rel = "stylesheet";
        l2.href = "https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap";
        doc_head.appendChild(l2);
        s: any = document.createElement("style");
        s.textContent = "*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Nunito Sans',sans-serif;background:#f9f9f6;color:#1a1c1b;-webkit-tap-highlight-color:transparent}@media(min-width:1024px){body{background:#e8e8e5}}.app-shell{max-width:720px;margin:0 auto;min-height:100dvh;position:relative;background:#f9f9f6;padding-bottom:72px}.material-symbols-outlined{font-variation-settings:'FILL' 0,'wght' 400,'GRAD' 0,'opsz' 24;user-select:none;vertical-align:middle;line-height:1}.hd{background:#2d7d62;color:white;padding:28px 24px 20px}.hd-ttl{font-family:'Literata',serif;font-size:22px;font-weight:600;margin-bottom:2px;display:flex;align-items:center;gap:8px}.hd-sub{font-size:15px;opacity:.88;margin-top:2px}.hd-elder{background:#1A5443;color:white;padding:36px 24px 28px;text-align:center}.clock{font-family:'Lora',serif;font-size:56px;font-weight:500;line-height:1.1;margin-bottom:8px;letter-spacing:2px}.elder-greeting{font-family:'Literata',serif;font-size:24px;font-weight:500;margin-bottom:4px}.elder-sub{font-size:16px;opacity:.8}.s{display:flex;flex-direction:column;gap:16px;padding:20px 24px}.sh2{font-family:'Literata',serif;font-size:20px;font-weight:500;color:#1a1c1b;margin-bottom:10px;display:flex;align-items:center;gap:8px}.sh2 .material-symbols-outlined{font-size:22px;color:#06644a}.btn{display:inline-flex;align-items:center;justify-content:center;gap:6px;font-family:'Nunito Sans',sans-serif;font-size:15px;font-weight:700;padding:12px 20px;border:none;border-radius:8px;cursor:pointer;transition:all .15s;min-height:44px;white-space:nowrap}.btn:active{transform:scale(.97)}.btn-p{background:#2d7d62;color:white}.btn-c{background:#b4efd8;color:#15503f}.btn-elder-med{background:#2d7d62;color:white;font-size:20px;padding:24px 20px;border-radius:16px;width:100%;text-align:left;justify-content:flex-start;gap:16px}.btn-elder-med .material-symbols-outlined{font-size:32px}.btn-elder-med .med-info{display:flex;flex-direction:column;gap:2px}.btn-elder-med .med-name{font-size:20px;font-weight:700}.btn-elder-med .med-dose{font-size:15px;font-weight:400;opacity:.85}.btn-sos{background:#E8784C;color:white;border-radius:16px;font-size:18px;padding:18px 28px;width:100%;justify-content:center}.btn-sos-elder{background:#E8784C;color:white;border-radius:24px;font-size:24px;padding:28px 36px;width:100%;justify-content:center;gap:12px;font-weight:800;letter-spacing:1px;box-shadow:0 4px 20px rgba(232,120,76,0.4);animation:sh 2s ease-in-out infinite}.cg{display:flex;gap:10px;flex-wrap:wrap}.cg .btn{flex:1;min-width:90px}.mc{background:white;border-radius:14px;padding:14px 16px;display:flex;align-items:center;gap:10px;justify-content:space-between}.mn{font-size:15px;font-weight:700;color:#1a1c1b}.md{font-size:13px;color:#3f4944;margin-top:1px}.ms{padding:4px 10px;border-radius:9999px;font-size:11px;font-weight:700;white-space:nowrap}.ms-t{background:#b4efd8;color:#06644a}.ms-p{background:#ffdbcf;color:#380d00}.bt{font-size:13px;padding:8px 14px;min-height:34px}.mw{text-align:center;padding:20px;color:#3f4944;font-size:14px}.al{background:#1a1c1b;color:white;padding:10px 20px;border-radius:8px;font-size:13px;font-weight:600;margin:12px 0;text-align:center}.tb{position:fixed;bottom:0;left:50%;transform:translateX(-50%);width:100%;max-width:720px;background:white;display:flex;border-top:1px solid #e8e8e5;padding:4px 0;z-index:50;height:64px}.tb-btn{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;padding:6px 0;border:none;background:none;cursor:pointer;color:#8c9196;font-family:'Nunito Sans',sans-serif;font-size:11px;font-weight:600;transition:color .15s}.tb-btn.active{color:#06644a}.tb-btn .material-symbols-outlined{font-size:24px}.tb-btn.active .material-symbols-outlined{font-variation-settings:'FILL' 1,'wght' 400,'GRAD' 0,'opsz' 24}.stats-row{display:flex;gap:10px;margin-bottom:4px}.stat-card{background:white;border-radius:14px;padding:14px;flex:1;text-align:center}.stat-num{font-family:'Literata',serif;font-size:24px;font-weight:700;color:#06644a;display:block}.stat-label{font-size:11px;color:#3f4944;margin-top:2px;display:block}.missed-alert{background:#fff3ee;border-left:4px solid #E8784C;padding:12px 14px;border-radius:8px;margin-bottom:10px;display:flex;align-items:center;gap:10px}.missed-alert .material-symbols-outlined{color:#E8784C;font-size:22px}.missed-alert .missed-text{font-size:13px;font-weight:600;color:#380d00}.missed-alert .missed-sub{font-size:12px;color:#3f4944;margin-top:1px}.ch{background:white;border-radius:14px;padding:12px 14px;display:flex;align-items:center;gap:10px;margin-bottom:6px}.ch .material-symbols-outlined{font-size:20px;padding:6px;border-radius:50%}.ch-bg{background:#b4efd8;color:#06644a}.ch-d{font-size:13px;color:#1a1c1b}.ch-m{font-size:12px;color:#3f4944}.view-elder .s{gap:20px}.view-elder .sh2{font-size:24px;font-weight:600;margin-bottom:14px}.view-elder .hd-sub{font-size:18px}.mwb{text-align:center;padding:4px 24px}.mwb .btn{min-width:200px}.toast{position:fixed;top:16px;left:50%;transform:translateX(-50%);background:#1a1c1b;color:white;padding:10px 20px;border-radius:8px;font-size:13px;font-weight:600;z-index:100;animation:su .3s ease-out;white-space:nowrap}@keyframes su{from{opacity:0;transform:translateX(-50%) translateY(-12px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}@keyframes sh{0%,100%{box-shadow:0 4px 20px rgba(232,120,76,0.4)}50%{box-shadow:0 4px 32px rgba(232,120,76,0.7)}}.dtp-layout{display:flex;min-height:100vh;background:#e8e8e5}@media(max-width:1023px){.dtp-layout{display:none}}.sb{width:240px;background:white;border-right:1px solid #e0e0dd;display:flex;flex-direction:column;position:fixed;top:0;left:0;bottom:0;z-index:60}.sb-hd{padding:24px 20px 16px;border-bottom:1px solid #f0f0ee}.sb-logo{font-family:'Literata',serif;font-size:18px;font-weight:600;color:#06644a;display:flex;align-items:center;gap:8px;text-decoration:none;margin-bottom:12px}.sb-user{font-size:13px;color:#3f4944;margin-bottom:2px}.sb-mode{font-size:11px;color:#06644a;font-weight:600;padding:2px 8px;background:#b4efd8;border-radius:9999px;display:inline-block}.sb-nav{flex:1;padding:8px 12px}.sb-item{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:8px;border:none;background:none;cursor:pointer;font-family:'Nunito Sans',sans-serif;font-size:14px;font-weight:600;color:#3f4944;width:100%;text-align:left;transition:all .12s}.sb-item:hover{background:#f0f0ee}.sb-item.active{background:#b4efd8;color:#06644a}.sb-item .material-symbols-outlined{font-size:20px}.sb-btm{padding:12px;border-top:1px solid #f0f0ee;display:flex;flex-direction:column;gap:4px}.sb-sos{background:#E8784C;color:white;border:none;border-radius:8px;padding:10px 14px;font-family:'Nunito Sans',sans-serif;font-size:13px;font-weight:700;cursor:pointer;display:flex;align-items:center;gap:8px;width:100%;justify-content:center;margin-bottom:4px}.sb-link{display:flex;align-items:center;gap:8px;padding:8px 12px;border:none;background:none;cursor:pointer;font-family:'Nunito Sans',sans-serif;font-size:13px;color:#3f4944;border-radius:6px;width:100%}.sb-link:hover{background:#f0f0ee}.tp{position:fixed;top:0;left:240px;right:0;height:64px;background:white;border-bottom:1px solid #e0e0dd;display:flex;align-items:center;padding:0 24px;gap:16px;z-index:55}.tp-search{flex:1;max-width:360px;display:flex;align-items:center;gap:8px;background:#f0f0ee;border-radius:8px;padding:8px 14px;border:none;font-family:'Nunito Sans',sans-serif;font-size:14px;color:#1a1c1b}.tp-search .material-symbols-outlined{font-size:20px;color:#8c9196}.tp-btn{display:flex;align-items:center;gap:6px;background:#E8784C;color:white;border:none;border-radius:8px;padding:8px 14px;font-family:'Nunito Sans',sans-serif;font-size:13px;font-weight:700;cursor:pointer}.tp-icon{border:none;background:none;cursor:pointer;color:#3f4944;padding:6px;border-radius:6px;display:flex;align-items:center}.tp-icon:hover{background:#f0f0ee}.tp-icon .material-symbols-outlined{font-size:22px}.mc-area{margin-left:240px;margin-top:64px;padding:24px 32px;max-width:1000px}.mc-area h1{font-family:'Literata',serif;font-size:28px;font-weight:600;color:#1a1c1b;margin-bottom:4px}.mc-area .sub{font-size:15px;color:#3f4944;margin-bottom:20px}.dg{display:grid;grid-template-columns:1fr 1fr;gap:16px}.dgc{background:white;border-radius:16px;padding:20px}.dgc-full{grid-column:1/-1}.dgc-h{font-size:15px;font-weight:700;color:#1a1c1b;margin-bottom:12px;display:flex;align-items:center;gap:6px}.dgc-h .material-symbols-outlined{font-size:18px;color:#06644a}.dgc-v{font-family:'Literata',serif;font-size:32px;font-weight:700;color:#06644a;display:block}.dgc-l{font-size:13px;color:#3f4944;margin-top:2px}.dgc-s{display:flex;align-items:center;gap:12px;margin-top:8px}.dgc-s .btn{min-height:36px;font-size:13px;padding:8px 16px}.bar-c{display:flex;gap:6px;align-items:flex-end;height:80px;padding-top:8px}.bar{width:24px;border-radius:4px 4px 0 0;background:#b4efd8;min-height:4px;position:relative}.bar-l{font-size:10px;color:#3f4944;text-align:center;margin-top:4px}.bar-v{font-size:9px;color:#3f4944;text-align:center;position:absolute;top:-14px;left:50%;transform:translateX(-50%);white-space:nowrap}.wl{font-style:italic;font-size:14px;color:#3f4944;line-height:1.6;padding:8px 0}.wl-author{font-size:13px;font-weight:600;color:#1a1c1b;margin-top:4px}.uf{display:flex;flex-direction:column;gap:8px}.uf-item{display:flex;align-items:flex-start;gap:10px;padding:10px 0;border-bottom:1px solid #f0f0ee}.uf-item:last-child{border-bottom:none}.uf-icon{font-size:18px;padding:6px;border-radius:50%;background:#f0f0ee;color:#06644a}.uf-t{font-size:13px;color:#1a1c1b}.uf-s{font-size:11px;color:#8c9196;margin-top:1px}.uc{display:flex;gap:12px;flex-wrap:wrap}.uc-item{background:white;border-radius:14px;padding:16px;flex:1;min-width:200px;display:flex;align-items:center;gap:12px}.uc-item .material-symbols-outlined{font-size:28px;padding:8px;border-radius:12px}.uc-good{background:#b4efd8;color:#06644a}.uc-neutral{background:#e8e8e5;color:#3f4944}.uc-bad{background:#ffdbcf;color:#380d00}.uc-t{font-size:14px;font-weight:600;color:#1a1c1b}.uc-s{font-size:12px;color:#3f4944}.mc-area .mwb{text-align:left;padding:0 0 16px}.dtp-elder{display:flex;min-height:100vh;background:#1A5443}@media(max-width:1023px){.dtp-elder{display:none}}.elder-desktop{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:40px}.elder-desktop .clock{font-size:96px;color:white}.elder-desktop .elder-greeting{font-size:36px;color:white}.elder-desktop .elder-sub{font-size:20px;color:rgba(255,255,255,0.8)}.elder-desktop .btn-sos-elder{max-width:500px;font-size:28px;padding:36px 48px}.elder-desktop .btn-elder-med{max-width:500px}.elder-desktop .s{max-width:600px;width:100%}.elder-desktop .sh2{color:rgba(255,255,255,0.9)}.elder-desktop .sh2 .material-symbols-outlined{color:rgba(255,255,255,0.9)}.elder-desktop .mw{color:rgba(255,255,255,0.6)}.mc-area .btn-sos{max-width:300px}.hl{font-size:13px;font-weight:600;color:#06644a;display:flex;align-items:center;gap:4px;margin-top:12px;cursor:pointer}.hl:hover{text-decoration:underline}.e-card{background:white;border-radius:14px;padding:16px;display:flex;align-items:center;gap:12px}.e-card .material-symbols-outlined{font-size:24px;padding:8px;border-radius:10px;background:#b4efd8;color:#06644a}.e-card-t{font-size:14px;font-weight:600;color:#1a1c1b}.e-card-s{font-size:12px;color:#3f4944}@keyframes mgp{0%,100%{box-shadow:0 0 0 0 rgba(255,255,255,0.4)}50%{box-shadow:0 0 0 16px rgba(255,255,255,0)}}.mic-btn{width:64px;height:64px;border-radius:50%;background:white;border:none;cursor:pointer;display:flex;align-items:center;justify-content:center;color:#06644a;animation:mgp 2s ease-in-out infinite}.mic-btn .material-symbols-outlined{font-size:32px}";
        doc_head.appendChild(s);
        d = new(Date);
        h = d.getHours();
        if h < 12 {
            greeting = "Good morning";
        } elif h < 18 {
            greeting = "Good afternoon";
        } else {
            greeting = "Good evening";
        }
        win_width = window.innerWidth;
        is_desktop = win_width >= 1024;
        result = root spawn get_profile();
        if result.reports and len(result.reports) > 0 {
            p = result.reports[0];
            if p {
                user_name = p.name;
                mode = p.mode;
            }
        }
        med_result = root spawn get_med_schedule();
        if med_result.reports and len(med_result.reports) > 0 {
            meds = med_result.reports[0];
            taken_count = len(
                [
                    m
                    for m in meds
                    if m.taken
                ]
            );
        }
        ci_result = root spawn get_checkins();
        if ci_result.reports and len(ci_result.reports) > 0 {
            checkins = ci_result.reports[0];
        }
        mm_result = root spawn check_missed_meds();
        if mm_result.reports and len(mm_result.reports) > 0 {
            missed_meds = mm_result.reports[0].missed;
        }
    }

    async def handle_toggle_mode() {
        nm = "elder" if mode == "normal" else "normal";
        r = root spawn toggle_mode(new_mode=nm);
        if r.reports and len(r.reports) > 0 {
            mode = r.reports[0].mode;
        }
        alert_msg = "Switched to "
            + ("Elderly" if mode == "elder" else "Standard")
            + " mode";
    }

    async def handle_checkin(mood: str) {
        root spawn log_checkin(mood=mood);
        alert_msg = "Check-in recorded: feeling " + mood;
        ci_result = root spawn get_checkins();
        if ci_result.reports and len(ci_result.reports) > 0 {
            checkins = ci_result.reports[0];
        }
    }

    async def handle_take_med(med_name: str) {
        root spawn mark_med_taken(med_name=med_name);
        alert_msg = med_name + " marked as taken";
        mr = root spawn get_med_schedule();
        if mr.reports and len(mr.reports) > 0 {
            meds = mr.reports[0];
            taken_count = len(
                [
                    m
                    for m in meds
                    if m.taken
                ]
            );
        }
        mm_result = root spawn check_missed_meds();
        if mm_result.reports and len(mm_result.reports) > 0 {
            missed_meds = mm_result.reports[0].missed;
        }
    }

    async def handle_sos() {
        r = root spawn trigger_sos();
        if r.reports and len(r.reports) > 0 {
            sos_fired = True;
            alert_msg = r.reports[0].message;
        }
    }

    async def handle_tab(t: str) {
        tab = t;
        if t == "elder" and mode != "elder" {
            nm = "elder";
            r = root spawn toggle_mode(new_mode=nm);
            if r.reports and len(r.reports) > 0 {
                mode = r.reports[0].mode;
            }
        } elif t == "home" and mode != "normal" {
            nm = "normal";
            r = root spawn toggle_mode(new_mode=nm);
            if r.reports and len(r.reports) > 0 {
                mode = r.reports[0].mode;
            }
        }
    }

    mode_btn_label = mode == "normal" and "Switch to Elderly Mode" or "Standard Mode";
    show_home = tab == "home";
    show_health = tab == "health";
    show_elder = tab == "elder";

    return
        <div>
            {not is_desktop
                and <div className="app-shell">
                    {show_home
                        and <div className="view-home">
                            <div className="hd">
                                <div className="hd-ttl">
                                    <span className="material-symbols-outlined">
                                        favorite
                                    </span>
                                    Granny Care
                                </div>
                                <div className="hd-sub">{greeting}, {user_name}</div>
                            </div>
                            <div className="mwb">
                                <button
                                    className="btn btn-p"
                                    onClick={lambda -> None { handle_toggle_mode(); }}
                                >
                                    <span className="material-symbols-outlined">
                                        swap_horiz
                                    </span>
                                    {mode_btn_label}
                                </button>
                            </div>
                            <div className="s">
                                <div className="stats-row">
                                    <div className="stat-card">
                                        <span className="stat-num">
                                            {len(checkins)}
                                        </span>
                                        <span className="stat-label">Check-ins</span>
                                    </div>
                                    <div className="stat-card">
                                        <span className="stat-num">{taken_count}</span>
                                        <span className="stat-label">Meds Taken</span>
                                    </div>
                                    <div className="stat-card">
                                        <span className="stat-num">{len(meds)}</span>
                                        <span className="stat-label">Scheduled</span>
                                    </div>
                                </div>
                                <div>
                                    <div className="sh2">
                                        <span className="material-symbols-outlined">
                                            mood
                                        </span>
                                        Daily Check-In
                                    </div>
                                    <div className="cg">
                                        <button
                                            className="btn btn-c"
                                            onClick={lambda -> None { handle_checkin(
                                                "good"
                                            ); }}
                                        >
                                            <span className="material-symbols-outlined">
                                                sentiment_satisfied
                                            </span>
                                            Good
                                        </button>
                                        <button
                                            className="btn btn-c"
                                            onClick={lambda -> None { handle_checkin(
                                                "okay"
                                            ); }}
                                        >
                                            <span className="material-symbols-outlined">
                                                sentiment_neutral
                                            </span>
                                            Okay
                                        </button>
                                        <button
                                            className="btn btn-c"
                                            onClick={lambda -> None { handle_checkin(
                                                "not well"
                                            ); }}
                                        >
                                            <span className="material-symbols-outlined">
                                                sentiment_dissatisfied
                                            </span>
                                            Not Well
                                        </button>
                                    </div>
                                </div>
                                <div>
                                    <div className="sh2">
                                        <span className="material-symbols-outlined">
                                            medication
                                        </span>
                                        Medication Schedule
                                    </div>
                                    {len(meds) == 0
                                        and <div className="mw">
                                            No medications scheduled.
                                        </div>}
                                    {len(meds) > 0
                                        and <div>
                                            {[
                                                <div key={med.med_name} className="mc">
                                                    <div>
                                                        <div className="mn">
                                                            {med.med_name}
                                                        </div>
                                                        <div className="md">
                                                            {med.dose} - {med.time}
                                                        </div>
                                                    </div>
                                                    <div
                                                        style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            gap: "8px"
                                                        }}
                                                    >
                                                        {med.taken
                                                            and <span
                                                                className="ms ms-t"
                                                            >
                                                                Taken
                                                            </span>}{not med.taken
                                                            and <span
                                                                className="ms ms-p"
                                                            >
                                                                Pending
                                                            </span>}{not med.taken
                                                            and <button
                                                                className="btn btn-p bt"
                                                                onClick={lambda -> None { handle_take_med(
                                                                    med.med_name
                                                                ); }}
                                                            >
                                                                Take
                                                            </button>}
                                                    </div>
                                                </div> for med in meds
                                            ]}
                                        </div>}
                                </div>
                                <div>
                                    <button
                                        className="btn btn-sos"
                                        onClick={lambda -> None { handle_sos(); }}
                                    >
                                        <span className="material-symbols-outlined">
                                            warning
                                        </span>
                                        SOS - I NEED HELP NOW
                                    </button>
                                    {sos_fired
                                        and <div className="al">
                                            SOS alert sent to family and emergency contacts!
                                        </div>}
                                </div>
                            </div>
                        </div>}
                    {show_health
                        and <div className="view-health">
                            <div className="hd">
                                <div className="hd-ttl">
                                    <span className="material-symbols-outlined">
                                        monitoring
                                    </span>
                                    Health Insights
                                </div>
                                <div className="hd-sub">Your wellness summary</div>
                            </div>
                            <div className="s">
                                <div className="stats-row">
                                    <div className="stat-card">
                                        <span className="stat-num">
                                            {len(checkins)}
                                        </span>
                                        <span className="stat-label">
                                            Total Check-ins
                                        </span>
                                    </div>
                                    <div className="stat-card">
                                        <span className="stat-num">
                                            {taken_count}/{len(meds)}
                                        </span>
                                        <span className="stat-label">Meds Today</span>
                                    </div>
                                </div>
                                {len(missed_meds) > 0
                                    and <div className="missed-alert">
                                        <span className="material-symbols-outlined">
                                            error
                                        </span>
                                        <div>
                                            <div className="missed-text">
                                                Missed Medications
                                            </div>
                                            <div className="missed-sub">
                                                {len(
                                                    missed_meds
                                                )} medication(s) not taken yet today
                                            </div>
                                        </div>
                                    </div>}
                                <div>
                                    <div className="sh2">
                                        <span className="material-symbols-outlined">
                                            history
                                        </span>
                                        Check-In History
                                    </div>
                                    {len(checkins) == 0
                                        and <div className="mw">
                                            No check-ins logged yet.
                                        </div>}
                                    {len(checkins) > 0
                                        and <div>
                                            {[
                                                <div
                                                    key={"ci-" + ci.mood + ci.logged_at}
                                                    className="ch"
                                                >
                                                    <span
                                                        className="material-symbols-outlined ch-bg"
                                                    >
                                                        {ci.mood == "good"
                                                            and "sentiment_satisfied"
                                                            or ci.mood == "okay"
                                                            and "sentiment_neutral"
                                                            or "sentiment_dissatisfied"}
                                                    </span>
                                                    <div>
                                                        <div className="ch-d">
                                                            Feeling {ci.mood}
                                                        </div>
                                                        <div className="ch-m">
                                                            {ci.logged_at}
                                                        </div>
                                                    </div>
                                                </div> for ci in checkins
                                            ]}
                                        </div>}
                                </div>
                            </div>
                        </div>}
                    {show_elder
                        and <div className="view-elder">
                            <div className="hd-elder">
                                <div className="clock">
                                    {greeting == "Good morning"
                                        and "GOOD MORNING"
                                        or greeting == "Good afternoon"
                                        and "GOOD AFTERNOON"
                                        or "GOOD EVENING"}
                                </div>
                                <div className="elder-greeting">
                                    {greeting}, {user_name}
                                </div>
                                <div className="elder-sub">
                                    How are you feeling today?
                                </div>
                            </div>
                            <div className="s">
                                <div>
                                    <div className="sh2">
                                        <span className="material-symbols-outlined">
                                            medication
                                        </span>
                                        Your Medications
                                    </div>
                                    {len(meds) == 0
                                        and <div className="mw">
                                            No medications scheduled.
                                        </div>}
                                    {len(meds) > 0
                                        and <div>
                                            {[
                                                <div
                                                    key={med.med_name}
                                                    style={{marginBottom: "10px"}}
                                                >
                                                    <button
                                                        className="btn btn-elder-med"
                                                        onClick={lambda -> None { handle_take_med(
                                                            med.med_name
                                                        ); }}
                                                    >
                                                        <span
                                                            className="material-symbols-outlined"
                                                        >
                                                            {med.taken
                                                                and "check_circle"
                                                                or "medication"}
                                                        </span>
                                                        <div className="med-info">
                                                            <span className="med-name">
                                                                {med.med_name}
                                                            </span>
                                                            <span className="med-dose">
                                                                {med.dose} at {med.time} - {med.taken
                                                                    and "Taken"
                                                                    or "Not taken yet"}
                                                            </span>
                                                        </div>
                                                    </button>
                                                </div> for med in meds
                                            ]}
                                        </div>}
                                </div>
                                <div>
                                    <button
                                        className="btn btn-sos-elder"
                                        onClick={lambda -> None { handle_sos(); }}
                                    >
                                        <span
                                            className="material-symbols-outlined"
                                            style={{fontSize: "32px"}}
                                        >
                                            warning
                                        </span>
                                        SOS EMERGENCY
                                    </button>
                                    {sos_fired
                                        and <div className="al">
                                            Emergency contacts have been notified!
                                        </div>}
                                </div>
                            </div>
                        </div>}
                    <div className="tb">
                        <button
                            className={"tb-btn" + (" active" if show_home else "")}
                            onClick={lambda -> None { handle_tab("home"); }}
                        >
                            <span className="material-symbols-outlined">home</span>
                            Home
                        </button>
                        <button
                            className={"tb-btn" + (" active" if show_health else "")}
                            onClick={lambda -> None { handle_tab("health"); }}
                        >
                            <span className="material-symbols-outlined">
                                monitoring
                            </span>
                            Health
                        </button>
                        <button
                            className={"tb-btn" + (" active" if show_elder else "")}
                            onClick={lambda -> None { handle_tab("elder"); }}
                        >
                            <span className="material-symbols-outlined">elderly</span>
                            Elderly
                        </button>
                    </div>
                    {alert_msg != "" and <div className="toast">{alert_msg}</div>}
                </div>}{is_desktop
                and tab == "elder"
                and <div className="dtp-elder">
                    <div className="elder-desktop">
                        <div className="clock">00:00</div>
                        <div className="elder-greeting">{greeting}, {user_name}</div>
                        <div className="elder-sub">How are you feeling today?</div>
                        <div className="s">
                            <div>
                                <div className="sh2">
                                    <span className="material-symbols-outlined">
                                        medication
                                    </span>
                                    Your Medications
                                </div>
                                {len(meds) == 0
                                    and <div className="mw">
                                        No medications scheduled.
                                    </div>}
                                {len(meds) > 0
                                    and <div>
                                        {[
                                            <div
                                                key={med.med_name}
                                                style={{marginBottom: "10px"}}
                                            >
                                                <button
                                                    className="btn btn-elder-med"
                                                    onClick={lambda -> None { handle_take_med(
                                                        med.med_name
                                                    ); }}
                                                >
                                                    <span
                                                        className="material-symbols-outlined"
                                                    >
                                                        {med.taken
                                                            and "check_circle"
                                                            or "medication"}
                                                    </span>
                                                    <div className="med-info">
                                                        <span className="med-name">
                                                            {med.med_name}
                                                        </span>
                                                        <span className="med-dose">
                                                            {med.dose} at {med.time} - {med.taken
                                                                and "Taken"
                                                                or "Not taken yet"}
                                                        </span>
                                                    </div>
                                                </button>
                                            </div> for med in meds
                                        ]}
                                    </div>}
                            </div>
                            <div>
                                <button
                                    className="btn btn-sos-elder"
                                    onClick={lambda -> None { handle_sos(); }}
                                >
                                    <span
                                        className="material-symbols-outlined"
                                        style={{fontSize: "32px"}}
                                    >
                                        warning
                                    </span>
                                    SOS EMERGENCY
                                </button>
                                {sos_fired
                                    and <div className="al">
                                        Emergency contacts have been notified!
                                    </div>}
                            </div>
                        </div>
                    </div>
                </div>}{is_desktop
                and tab != "elder"
                and <div className="dtp-layout">
                    <div className="sb">
                        <div className="sb-hd">
                            <div className="sb-logo">
                                <span className="material-symbols-outlined">
                                    favorite
                                </span>
                                Granny Care
                            </div>
                            <div className="sb-user">{user_name}</div>
                            <span className="sb-mode">
                                {mode == "normal" and "Normal Mode" or "Elderly Care"}
                            </span>
                        </div>
                        <div className="sb-nav">
                            <button
                                className={"sb-item" + (" active" if show_home else "")}
                                onClick={lambda -> None { handle_tab("home"); }}
                            >
                                <span className="material-symbols-outlined">home</span>
                                Dashboard
                            </button>
                            <button
                                className={"sb-item"
                                    + (" active" if show_health else "")}
                                onClick={lambda -> None { handle_tab("health"); }}
                            >
                                <span className="material-symbols-outlined">
                                    monitoring
                                </span>
                                Health Logs
                            </button>
                            <button
                                className="sb-item"
                                onClick={lambda -> None { alert_msg = "Calendar coming soon!"; }}
                            >
                                <span className="material-symbols-outlined">
                                    calendar_month
                                </span>
                                Calendar
                            </button>
                            <button
                                className="sb-item"
                                onClick={lambda -> None { alert_msg = "Care Team coming soon!"; }}
                            >
                                <span className="material-symbols-outlined">group</span>
                                Care Team
                            </button>
                        </div>
                        <div className="sb-btm">
                            <button
                                className="sb-sos"
                                onClick={lambda -> None { handle_sos(); }}
                            >
                                <span className="material-symbols-outlined">
                                    emergency
                                </span>
                                Emergency SOS
                            </button>
                            <button
                                className="sb-link"
                                onClick={lambda -> None { handle_toggle_mode(); }}
                            >
                                <span className="material-symbols-outlined">
                                    swap_horiz
                                </span>
                                {mode_btn_label}
                            </button>
                            <button
                                className="sb-link"
                                onClick={lambda -> None { alert_msg = "Support coming soon!"; }}
                            >
                                <span className="material-symbols-outlined">help</span>
                                Support
                            </button>
                            <button
                                className="sb-link"
                                onClick={lambda -> None { alert_msg = "Logout coming soon!"; }}
                            >
                                <span className="material-symbols-outlined">
                                    logout
                                </span>
                                Log Out
                            </button>
                        </div>
                    </div>
                    <div className="tp">
                        <div className="tp-search">
                            <span className="material-symbols-outlined">search</span>
                            Search dashboard...
                        </div>
                        <button
                            className="tp-btn"
                            onClick={lambda -> None { handle_sos(); }}
                        >
                            <span className="material-symbols-outlined">
                                emergency_home
                            </span>
                            Emergency SOS
                        </button>
                        <button
                            className="tp-icon"
                            onClick={lambda -> None { alert_msg = "No new notifications"; }}
                        >
                            <span className="material-symbols-outlined">
                                notifications
                            </span>
                        </button>
                        <button
                            className="tp-icon"
                            onClick={lambda -> None { alert_msg = "Settings coming soon!"; }}
                        >
                            <span className="material-symbols-outlined">settings</span>
                        </button>
                    </div>
                    {show_home
                        and <div className="mc-area">
                            <h1>Hello, {user_name}</h1>
                            <div className="sub">Here's how you're doing today.</div>
                            <div className="mwb">
                                <button
                                    className="btn btn-p"
                                    onClick={lambda -> None { handle_toggle_mode(); }}
                                >
                                    <span className="material-symbols-outlined">
                                        swap_horiz
                                    </span>
                                    {mode_btn_label}
                                </button>
                            </div>
                            <div className="dg">
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            check_circle
                                        </span>
                                        Medications Taken
                                    </span>
                                    <span className="dgc-v">
                                        {taken_count}/{len(meds)}
                                    </span>
                                    <span className="dgc-l">Today's progress</span>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            schedule
                                        </span>
                                        Reminders Left
                                    </span>
                                    <span className="dgc-v">
                                        {len(meds) - taken_count}
                                    </span>
                                    <span className="dgc-l">Pending medications</span>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            mood
                                        </span>
                                        Daily Check-In
                                    </span>
                                    <div
                                        style={{
                                            display: "flex",
                                            gap: "8px",
                                            marginTop: "8px"
                                        }}
                                    >
                                        <button
                                            className="btn btn-c"
                                            onClick={lambda -> None { handle_checkin(
                                                "good"
                                            ); }}
                                        >
                                            <span className="material-symbols-outlined">
                                                sentiment_satisfied
                                            </span>
                                            Good
                                        </button>
                                        <button
                                            className="btn btn-c"
                                            onClick={lambda -> None { handle_checkin(
                                                "okay"
                                            ); }}
                                        >
                                            <span className="material-symbols-outlined">
                                                sentiment_neutral
                                            </span>
                                            Okay
                                        </button>
                                        <button
                                            className="btn btn-c"
                                            onClick={lambda -> None { handle_checkin(
                                                "not well"
                                            ); }}
                                        >
                                            <span className="material-symbols-outlined">
                                                sentiment_dissatisfied
                                            </span>
                                            Not Well
                                        </button>
                                    </div>
                                    <span className="dgc-l" style={{marginTop: "8px"}}>
                                        Feeling good - High energy today
                                    </span>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            bedtime
                                        </span>
                                        Sleep Quality
                                    </span>
                                    <span className="dgc-v">7h 42m</span>
                                    <span className="dgc-l">
                                        Total sleep - Restorative phases
                                    </span>
                                    <div className="bar-c">
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "60px"}}
                                            ></div>
                                            <div className="bar-l">Mon</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "45px"}}
                                            ></div>
                                            <div className="bar-l">Tue</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "70px"}}
                                            ></div>
                                            <div className="bar-l">Wed</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "55px"}}
                                            ></div>
                                            <div className="bar-l">Thu</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "65px"}}
                                            ></div>
                                            <div className="bar-l">Fri</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "75px"}}
                                            ></div>
                                            <div className="bar-l">Sat</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "50px"}}
                                            ></div>
                                            <div className="bar-l">Sun</div>
                                        </div>
                                    </div>
                                </div>
                                <div className="dgc dgc-full">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            medication
                                        </span>
                                        Medication Schedule
                                    </span>
                                    {len(meds) == 0
                                        and <div className="mw">
                                            No medications scheduled.
                                        </div>}
                                    {len(meds) > 0
                                        and <div>
                                            {[
                                                <div key={med.med_name} className="mc">
                                                    <div>
                                                        <div className="mn">
                                                            {med.med_name}
                                                        </div>
                                                        <div className="md">
                                                            {med.dose} - {med.time}
                                                        </div>
                                                    </div>
                                                    <div
                                                        style={{
                                                            display: "flex",
                                                            alignItems: "center",
                                                            gap: "8px"
                                                        }}
                                                    >
                                                        {med.taken
                                                            and <span
                                                                className="ms ms-t"
                                                            >
                                                                Taken
                                                            </span>}{not med.taken
                                                            and <span
                                                                className="ms ms-p"
                                                            >
                                                                Pending
                                                            </span>}{not med.taken
                                                            and <button
                                                                className="btn btn-p bt"
                                                                onClick={lambda -> None { handle_take_med(
                                                                    med.med_name
                                                                ); }}
                                                            >
                                                                Take
                                                            </button>}
                                                    </div>
                                                </div> for med in meds
                                            ]}
                                        </div>}
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            auto_stories
                                        </span>
                                        Today's Wisdom
                                    </span>
                                    <div className="wl">
                                        "The secret of health for both mind and body is not to mourn for the past, but to live in the present moment wisely and earnestly."
                                    </div>
                                    <div className="wl-author">— Buddha</div>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            updates
                                        </span>
                                        Recent Updates
                                    </span>
                                    <div className="uf">
                                        <div className="uf-item">
                                            <span
                                                className="material-symbols-outlined uf-icon"
                                            >
                                                check_circle
                                            </span>
                                            <div>
                                                <div className="uf-t">
                                                    Morning vitals checked & confirmed.
                                                </div>
                                                <div className="uf-s">14 mins ago</div>
                                            </div>
                                        </div>
                                        {len(missed_meds) > 0
                                            and <div className="uf-item">
                                                <span
                                                    className="material-symbols-outlined uf-icon"
                                                    style={{
                                                        background: "#ffdbcf",
                                                        color: "#E8784C"
                                                    }}
                                                >
                                                    medication
                                                </span>
                                                <div>
                                                    <div className="uf-t">
                                                        Medication Alert: {missed_meds[
                                                            0
                                                        ].med_name} due
                                                    </div>
                                                    <div className="uf-s">
                                                        Scheduled for {missed_meds[
                                                            0
                                                        ].time}
                                                    </div>
                                                </div>
                                            </div>}
                                    </div>
                                </div>
                            </div>
                        </div>}
                    {show_health
                        and <div className="mc-area">
                            <h1>Health Insights</h1>
                            <div className="sub">
                                Your wellness overview for the past 7 days.
                            </div>
                            <div className="mwb">
                                <button
                                    className="btn btn-p"
                                    onClick={lambda -> None {
                                        handle_checkin("good");
                                        alert_msg = "New health entry logged!";
                                    }}
                                >
                                    <span className="material-symbols-outlined">
                                        add_circle
                                    </span>
                                    Log New Health Entry
                                </button>
                            </div>
                            {len(missed_meds) > 0
                                and <div className="missed-alert">
                                    <span className="material-symbols-outlined">
                                        warning
                                    </span>
                                    <div>
                                        <div className="missed-text">
                                            Missed Dose Detected
                                        </div>
                                        <div className="missed-sub">
                                            {missed_meds[0].med_name} - {missed_meds[
                                                0
                                            ].time}
                                        </div>
                                    </div>
                                </div>}
                            <div className="dg">
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            check_circle
                                        </span>
                                        Daily Overview
                                    </span>
                                    <span
                                        className="dgc-v"
                                        style={{
                                            fontSize: "16px",
                                            fontWeight: "600",
                                            color: "#06644a",
                                            fontFamily: "'Nunito Sans', sans-serif"
                                        }}
                                    >
                                        All metrics stable
                                    </span>
                                    <span className="dgc-l">
                                        Last updated: 10:30 AM
                                    </span>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            bedtime
                                        </span>
                                        Sleep Quality
                                    </span>
                                    <span className="dgc-v">7.8 hrs</span>
                                    <span className="dgc-l">
                                        Weekly avg - Restorative phases
                                    </span>
                                    <div className="bar-c">
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "50px"}}
                                            ></div>
                                            <div className="bar-l">Mon</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "65px"}}
                                            ></div>
                                            <div className="bar-l">Tue</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "55px"}}
                                            ></div>
                                            <div className="bar-l">Wed</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "70px"}}
                                            ></div>
                                            <div className="bar-l">Thu</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "45px"}}
                                            ></div>
                                            <div className="bar-l">Fri</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "60px"}}
                                            ></div>
                                            <div className="bar-l">Sat</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "55px"}}
                                            ></div>
                                            <div className="bar-l">Sun</div>
                                        </div>
                                    </div>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            water_drop
                                        </span>
                                        Hydration
                                    </span>
                                    <div className="dgc-s">
                                        <span
                                            className="dgc-v"
                                            style={{fontSize: "24px"}}
                                        >
                                            64
                                        </span>
                                        <span className="dgc-l">/ 72 oz</span>
                                    </div>
                                    <div className="bar-c">
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "40px"}}
                                            ></div>
                                            <div className="bar-l">M</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "55px"}}
                                            ></div>
                                            <div className="bar-l">T</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "35px"}}
                                            ></div>
                                            <div className="bar-l">W</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "60px"}}
                                            ></div>
                                            <div className="bar-l">T</div>
                                        </div>
                                        <div>
                                            <div
                                                className="bar"
                                                style={{height: "45px"}}
                                            ></div>
                                            <div className="bar-l">F</div>
                                        </div>
                                    </div>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            pill
                                        </span>
                                        Medication Adherence
                                    </span>
                                    <span className="dgc-v">
                                        {taken_count > 0
                                            and str(int(taken_count / len(meds) * 100))
                                                + "%"
                                            or "0%"}
                                    </span>
                                    <span className="dgc-l">
                                        30-day compliance (Target: 98%)
                                    </span>
                                    <div
                                        className="hl"
                                        onClick={lambda -> None { alert_msg = "Adherence details coming soon!"; }}
                                    >
                                        View detailed report
                                    </div>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            lightbulb
                                        </span>
                                        Quick Health Tips
                                    </span>
                                    <div
                                        className="uc-item"
                                        style={{marginBottom: "8px", minWidth: "auto"}}
                                    >
                                        <span
                                            className="material-symbols-outlined uc-good"
                                        >
                                            directions_walk
                                        </span>
                                        <div>
                                            <div className="uc-t">Light walk</div>
                                            <div className="uc-s">
                                                Try a 10-min walk after dinner
                                            </div>
                                        </div>
                                    </div>
                                    <div className="uc-item" style={{minWidth: "auto"}}>
                                        <span
                                            className="material-symbols-outlined uc-good"
                                        >
                                            nutrition
                                        </span>
                                        <div>
                                            <div className="uc-t">Hydration tip</div>
                                            <div className="uc-s">
                                                Add cucumber to your water
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div className="dgc">
                                    <span className="dgc-h">
                                        <span className="material-symbols-outlined">
                                            history
                                        </span>
                                        Check-In History
                                    </span>
                                    {len(checkins) == 0
                                        and <div className="mw">
                                            No check-ins logged yet.
                                        </div>}
                                    {len(checkins) > 0
                                        and <div>
                                            {[
                                                <div
                                                    key={"ci-" + ci.mood + ci.logged_at}
                                                    className="ch"
                                                >
                                                    <span
                                                        className="material-symbols-outlined ch-bg"
                                                    >
                                                        {ci.mood == "good"
                                                            and "sentiment_satisfied"
                                                            or ci.mood == "okay"
                                                            and "sentiment_neutral"
                                                            or "sentiment_dissatisfied"}
                                                    </span>
                                                    <div>
                                                        <div className="ch-d">
                                                            Feeling {ci.mood}
                                                        </div>
                                                        <div className="ch-m">
                                                            {ci.logged_at}
                                                        </div>
                                                    </div>
                                                </div> for ci in checkins
                                            ]}
                                        </div>}
                                </div>
                            </div>
                        </div>}
                    {alert_msg != "" and <div className="toast">{alert_msg}</div>}
                </div>}
        </div>;
}
