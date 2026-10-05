#* ============================================================
   main.jac — Orbit / Bubbul
   ============================================================ *#

import from byllm.lib { Model }
import from threading { Thread }
import from backboard_memory {
    get_briefing_with_memory,
    store_activation,
    store_url_visit
}
import os;

glob llm = Model(
    model_name="anthropic/claude-3-haiku",
    config={
        "base_url": "https://openrouter.ai/api/v1",
        "proxy": True,
        "api_key": os.getenv("OPENROUTER_API_KEY")
    }
);

glob LEISURE_THRESHOLD_MINUTES: float = 0.5;

glob DEFAULT_BUBBULS: list[dict[str, any]] = [
    {"name": "Deep Work", "description": "Maximum focus, no distractions.", "actions": ["block social", "mute notifications", "set DND"]},
    {"name": "Meeting",   "description": "Collaborative mode for calls.",   "actions": ["open Zoom", "show calendar"]},
    {"name": "Leisure",   "description": "Wind down and entertainment.",    "actions": ["open Spotify", "allow notifications"]},
];

node Bubbul {
    has name:        str;
    has description: str       = "";
    has actions:     list[str] = [];
    has is_active:   bool      = False;
    has activations: int       = 0;
    has created_at:  str       = "";
}

node UserProfile {
    has user_id:            str;
    has active_bubbul_name: str  = "Deep Work";
    has auto_switch:        bool = True;
}

node SwitchSuggestion {
    has from_bubbul:     str;
    has to_bubbul:       str;
    has reason:          str                  = "";
    has suggested_links: list[dict[str, str]] = [];
    has accepted:        bool                 = False;
    has dismissed:       bool                 = False;
    has created_at:      str                  = "";
}

node AppState {
    has tick_activity_log:   list[str]                       = [];
    has bubbul_url_history:  dict[str, list[dict[str, str]]] = {};
    has bubbul_active_since: dict[str, str]                  = {};
}

edge HasProfile {}
edge HasBubbul {}
edge HasSuggestion {}
edge HasState {}

obj ClassificationResult {
    has bubbul:          str | None           = None;
    has reason:          str | None           = None;
    has suggested_links: list[dict[str, str]] = [];
}

def now_str() -> str {
    ::py::
from datetime import datetime as _dt
return str(_dt.now())
    ::py::
    return "";
}

def time_of_day() -> str {
    ::py::
from datetime import datetime as _dt
h = _dt.now().hour
if h < 6:  return "night"
if h < 12: return "morning"
if h < 17: return "afternoon"
if h < 21: return "evening"
return "night"
    ::py::
    return "";
}

def minutes_since(dt_str: str) -> float {
    ::py::
from datetime import datetime as _dt
try:
    past = _dt.fromisoformat(dt_str)
    return (_dt.now() - past).total_seconds() / 60
except Exception:
    return 0.0
    ::py::
    return 0.0;
}

def extract_url_and_label(raw: str) -> tuple[str, str] {
    ::py::
url = ""
if "https://" in raw:
    url = "https://" + raw.split("https://")[-1].split(" ")[0]
elif "http://" in raw:
    url = "http://" + raw.split("http://")[-1].split(" ")[0]
label = raw.replace(url, "").strip()[:30] if url else raw[:30]
if not label and url:
    label = url.split("/")[2]
return (url, label)
    ::py::
    return ("", "");
}

def classify_tab_with_ai(app_name: str, current_bubbul: str) -> ClassificationResult by llm();
sem classify_tab_with_ai = """
You are helping classify a browser tab for a focus mode app called Orbit.

You MUST only choose from these 3 modes. No other modes exist:
- Deep Work: productivity, coding, writing, email, documents, github, figma, notion, canvas, google docs, slack, research
- Meeting: video calls, calendar, scheduling, zoom, google meet, microsoft teams
- Leisure: entertainment, youtube, netflix, spotify, reddit, twitter, instagram, gaming, social media, chess

Rules:
- ONLY return Deep Work, Meeting, or Leisure in the bubbul field — never anything else
- Only suggest a switch if the new mode is clearly different from current_bubbul
- If the tab doesn't clearly belong to a different mode than current_bubbul, set bubbul and reason to null and suggested_links to []
- suggested_links should be 2-3 relevant URLs for that mode as list of {label, url} dicts
- Keep reason to one short sentence
""";
sem classify_tab_with_ai.app_name = "The browser tab title or URL info to classify";
sem classify_tab_with_ai.current_bubbul = "The mode the user is currently in (Deep Work, Meeting, or Leisure)";
sem classify_tab_with_ai.return = "A ClassificationResult with bubbul (str or null), reason (str or null), and suggested_links (list of {label, url} dicts)";

walker bootstrap {
    obj __specs__ { static has auth: bool = False; }

    can setup with `root() entry {
        existing_profiles = [-->][?:UserProfile];
        if len(existing_profiles) > 0 {
            report {"status": "already bootstrapped"};
            disengage;
        }
        here ++> UserProfile(user_id="local_user");
        here ++> AppState();
        for d in DEFAULT_BUBBULS {
            here ++> Bubbul(
                name=str(d["name"]),
                description=str(d["description"]),
                actions=list(d["actions"]),
                is_active=str(d["name"]) == "Deep Work",
                created_at=now_str()
            );
        }
        states = [-->][?:AppState];
        if len(states) > 0 {
            states[0].bubbul_active_since["Deep Work"] = now_str();
        }
        report {"status": "bootstrapped", "bubbuls": len(DEFAULT_BUBBULS)};
    }
}

walker list_bubbuls {
    obj __specs__ { static has auth: bool = False; }

    can fetch with `root() entry {
        bubbuls: list[Bubbul] = [-->][?:Bubbul];
        if len(bubbuls) == 0 {
            root spawn bootstrap();
            bubbuls = [-->][?:Bubbul];
        }
        result: list[dict[str, any]] = [];
        for b in bubbuls {
            result.append({
                "name":        b.name,
                "description": b.description,
                "actions":     b.actions,
                "is_active":   b.is_active,
                "activations": b.activations
            });
        }
        report {"bubbuls": result};
    }
}

walker activate_bubbul {
    has bubbul_name: str;

    obj __specs__ { static has auth: bool = False; }

    can activate with `root() entry {
        bubbuls: list[Bubbul] = [-->][?:Bubbul];
        if len(bubbuls) == 0 {
            root spawn bootstrap();
            bubbuls = [-->][?:Bubbul];
        }
        profiles: list[UserProfile] = [-->][?:UserProfile];
        if len(profiles) == 0 {
            report {"error": "No profile found."};
            disengage;
        }
        profile = profiles[0];
        target: Bubbul | None = None;
        for b in bubbuls {
            b.is_active = False;
            if b.name == self.bubbul_name {
                target = b;
            }
        }
        if target is None {
            report {"error": f"Bubbul '{self.bubbul_name}' not found."};
            disengage;
        }
        target.is_active   = True;
        target.activations += 1;
        profile.active_bubbul_name = self.bubbul_name;
        states: list[AppState] = [-->][?:AppState];
        if len(states) > 0 {
            states[0].bubbul_active_since[self.bubbul_name] = now_str();
        }
        tod: str         = time_of_day();
        actions_str: str = ", ".join(target.actions);
        bname: str       = self.bubbul_name;
        def _async_backboard() {
            store_activation(bname, tod);
            get_briefing_with_memory(bname, actions_str, tod);
        }
        Thread(target=_async_backboard, daemon=True).start();
        report {
            "status":    "activated",
            "bubbul":    self.bubbul_name,
            "briefing":  f"Switched to {self.bubbul_name}.",
            "actions":   target.actions,
            "timestamp": now_str()
        };
    }
}

walker create_bubbul {
    has name:        str;
    has description: str       = "";
    has actions:     list[str] = [];

    obj __specs__ { static has auth: bool = False; }

    can create with `root() entry {
        existing: list[Bubbul] = [-->][?:Bubbul];
        for b in existing {
            if b.name == self.name {
                report {"error": f"Bubbul '{self.name}' already exists."};
                disengage;
            }
        }
        here ++> Bubbul(
            name=self.name,
            description=self.description,
            actions=self.actions,
            created_at=now_str()
        );
        report {"status": "created", "bubbul": self.name};
    }
}

walker process_activity_event {
    has app_name: str;

    obj __specs__ { static has auth: bool = False; }

    can evaluate with `root() entry {
        profiles: list[UserProfile] = [-->][?:UserProfile];
        if len(profiles) == 0 { disengage; }
        profile = profiles[0];
        states: list[AppState] = [-->][?:AppState];
        if len(states) == 0 { disengage; }
        state = states[0];
        classification: ClassificationResult = classify_tab_with_ai(
            app_name=self.app_name,
            current_bubbul=profile.active_bubbul_name
        );
        expected: str | None                  = classification.bubbul;
        reason: str                           = str(classification.reason or "");
        suggested_links: list[dict[str, str]] = list(classification.suggested_links or []);
        if expected is None {
            report {"status": "ignored"};
            disengage;
        }
        expected_str: str = str(expected);
        aname: str = self.app_name;
        tod: str   = time_of_day();
        Thread(
            target=store_url_visit,
            args=(aname, expected_str, tod),
            daemon=True
        ).start();
        url_label  = extract_url_and_label(self.app_name);
        url: str   = str(url_label[0]);
        label: str = str(url_label[1]);
        if expected_str not in state.bubbul_url_history {
            state.bubbul_url_history[expected_str] = [];
        }
        history = state.bubbul_url_history[expected_str];
        if url and not any(str(e.get("url", "")) == url for e in history) {
            history.append({
                "label":        label,
                "url":          url,
                "last_visited": now_str()
            });
            state.bubbul_url_history[expected_str] = list(history[-5:]);
        }
        if expected_str == "Leisure" and "Leisure" not in state.bubbul_active_since {
            state.bubbul_active_since["Leisure"] = now_str();
        }
        if profile.active_bubbul_name == expected_str {
            report {"status": "already in correct bubbul"};
            disengage;
        }
        here ++> SwitchSuggestion(
            from_bubbul=profile.active_bubbul_name,
            to_bubbul=expected_str,
            reason=reason,
            suggested_links=suggested_links,
            created_at=now_str()
        );
        state.tick_activity_log.append(
            f"User opened {self.app_name} ({expected_str}) while in '{profile.active_bubbul_name}' mode"
        );
        report {
            "status":          "suggestion_created",
            "from_bubbul":     profile.active_bubbul_name,
            "to_bubbul":       expected_str,
            "reason":          reason,
            "suggested_links": suggested_links,
            "auto_accepted":   False
        };
    }
}

walker respond_to_suggestion {
    has from_bubbul: str;
    has to_bubbul:   str;
    has accepted:    bool;

    obj __specs__ { static has auth: bool = False; }

    can respond with `root() entry {
        suggestions: list[SwitchSuggestion] = [-->][?:SwitchSuggestion];
        profiles: list[UserProfile]         = [-->][?:UserProfile];
        states: list[AppState]              = [-->][?:AppState];
        for s in suggestions {
            if s.from_bubbul == self.from_bubbul
               and s.to_bubbul == self.to_bubbul
               and not s.accepted
               and not s.dismissed {
                if self.accepted {
                    s.accepted = True;
                    bubbuls: list[Bubbul] = [-->][?:Bubbul];
                    target: Bubbul | None = None;
                    for b in bubbuls {
                        b.is_active = False;
                        if b.name == self.to_bubbul {
                            target = b;
                        }
                    }
                    if target is not None {
                        target.is_active   = True;
                        target.activations += 1;
                        if len(profiles) > 0 {
                            profiles[0].active_bubbul_name = self.to_bubbul;
                        }
                        if self.to_bubbul == "Leisure" and len(states) > 0 {
                            states[0].bubbul_active_since["Leisure"] = now_str();
                        }
                    }
                    tb: str  = self.to_bubbul;
                    tod: str = time_of_day();
                    Thread(
                        target=store_activation,
                        args=(tb, tod),
                        daemon=True
                    ).start();
                } else {
                    s.dismissed = True;
                    tb: str  = self.to_bubbul;
                    tod: str = time_of_day();
                    Thread(
                        target=store_activation,
                        args=(f"user_dismissed_switch_to_{tb}", tod),
                        daemon=True
                    ).start();
                }
                report {"status": "recorded", "accepted": self.accepted};
                disengage;
            }
        }
        report {"status": "no_matching_suggestion"};
    }
}

walker set_auto_switch {
    has enabled: bool;

    obj __specs__ { static has auth: bool = False; }

    can update with `root() entry {
        profiles: list[UserProfile] = [-->][?:UserProfile];
        if len(profiles) == 0 {
            report {"error": "No profile found."};
            disengage;
        }
        profiles[0].auto_switch = self.enabled;
        report {"auto_switch": self.enabled};
    }
}

walker status {
    obj __specs__ { static has auth: bool = False; }

    can get_status with `root() entry {
        profiles:    list[UserProfile]      = [-->][?:UserProfile];
        bubbuls:     list[Bubbul]           = [-->][?:Bubbul];
        suggestions: list[SwitchSuggestion] = [-->][?:SwitchSuggestion];
        pending:     list[SwitchSuggestion] = [s for s in suggestions if not s.accepted and not s.dismissed];
        active_name: str = profiles[0].active_bubbul_name if len(profiles) > 0 else "none";
        auto_sw: bool    = profiles[0].auto_switch if len(profiles) > 0 else True;
        report {
            "active_bubbul":       active_name,
            "total_bubbuls":       len(bubbuls),
            "pending_suggestions": len(pending),
            "auto_switch":         auto_sw,
            "time_of_day":         time_of_day()
        };
    }
}

walker get_suggestions {
    obj __specs__ { static has auth: bool = False; }

    can fetch with `root() entry {
        profiles:    list[UserProfile]      = [-->][?:UserProfile];
        suggestions: list[SwitchSuggestion] = [-->][?:SwitchSuggestion];
        states:      list[AppState]         = [-->][?:AppState];
        pending: list[SwitchSuggestion] = [s for s in suggestions if not s.accepted and not s.dismissed];
        active: str = profiles[0].active_bubbul_name if len(profiles) > 0 else "none";
        tod: str    = time_of_day();
        motivational_text: str | None = None;
        if len(states) > 0 and len(states[0].tick_activity_log) > 0 {
            activity_summary: str = "; ".join(states[0].tick_activity_log);
            motivational_text     = get_briefing_with_memory(active, activity_summary, tod);
            states[0].tick_activity_log = [];
        }
        result: list[dict[str, any]] = [];
        for s in pending {
            result.append({
                "from_bubbul":     s.from_bubbul,
                "to_bubbul":       s.to_bubbul,
                "reason":          s.reason,
                "suggested_links": s.suggested_links,
                "accepted":        s.accepted,
                "dismissed":       s.dismissed,
                "created_at":      s.created_at
            });
        }
        report {
            "suggestions":       result,
            "motivational_text": motivational_text
        };
    }
}

walker check_nudge {
    obj __specs__ { static has auth: bool = False; }

    can check with `root() entry {
        states: list[AppState] = [-->][?:AppState];
        if len(states) == 0 {
            report {"nudge": None};
            disengage;
        }
        state = states[0];
        if "Leisure" not in state.bubbul_active_since {
            report {"nudge": None};
            disengage;
        }
        leisure_since_str: str = state.bubbul_active_since["Leisure"];
        mins_elapsed: float    = minutes_since(leisure_since_str);
        if mins_elapsed < LEISURE_THRESHOLD_MINUTES {
            report {"nudge": None};
            disengage;
        }
        work_modes: list[str]           = ["Deep Work", "Meeting"];
        best_bubbul: str                = "Deep Work";
        best_urls: list[dict[str, str]] = [];
        for mode in work_modes {
            urls = state.bubbul_url_history.get(mode, []);
            if len(urls) > 0 {
                best_bubbul = mode;
                best_urls   = list(urls[-3:]);
                break;
            }
        }
        del state.bubbul_active_since["Leisure"];
        _rounded: float = 0.0;
        ::py::
_rounded = round(mins_elapsed, 1)
        ::py::
        report {
            "nudge": {
                "from_bubbul":     "Leisure",
                "to_bubbul":       best_bubbul,
                "minutes_elapsed": _rounded,
                "resume_urls":     best_urls
            }
        };
    }
}

walker healthz {
    obj __specs__ {
        static has auth:    bool      = False;
        static has methods: list[str] = ["get"];
    }

    can check with `root() entry {
        report {"status": "ok"};
    }
}

with entry {
    root spawn bootstrap();
    print("[Orbit] Initialised. Use 'jac start main.jac' to expose REST API.");
}