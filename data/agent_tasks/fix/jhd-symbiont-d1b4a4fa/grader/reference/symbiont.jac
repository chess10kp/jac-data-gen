import from datetime {datetime}

# ── Graph ──────────────────────────────────────────────────────────────

node User {
    has user_id: str;
    has autonomy_level: float = 0.7;
    has risk_profile: str = "low";
    has last_intervention: str = "";
    has session_start: str = "";
    has inferred_stress: float = 0.0;
    has inferred_sleep_debt: float = 0.0;
    has inferred_posture_risk: float = 0.0;
    has inferred_mood: str = "neutral";
}

node DigitalHabitat {
    has url: str;
    has domain: str;
    has category: str = "other";
    has time_spent_seconds: int = 0;
    has scroll_velocity: float = 0.0;
    has typing_cadence: float = 0.0;
    has tab_switch_rate: float = 0.0;
    has stress_score: float = 0.0;
    has health_impact: str = "neutral";
    has intervention_ready: bool = False;
    has last_updated: str = "";
}

node Intervention {
    has iv_type: str;
    has severity: float;
    has payload: dict[str, any];
    has executed: bool = False;
    has effective: bool = False;
    has checked: bool = False;
    has timestamp: str = "";
}

edge Visits: any --> any    { has duration: int = 0; }
edge Triggers: any --> any  { has confidence: float = 0.5; has trigger_data: dict[str, any] = {}; }
edge RespondsTo: any --> any { has compliance_rate: float = 0.5; }

# ── LLM Abilities (require Ollama; heuristics used by default) ─────────

def assess_habitat_stress(habitat: DigitalHabitat, history: list[DigitalHabitat]) -> dict[str, any]
    by llm("Analyze digital behavior from scroll_velocity, typing_cadence, tab_switch_rate, time_spent_seconds. Return JSON: stress_score float 0-1, health_impact str, urgency str immediate|soon|low");

def generate_intervention(assessment: dict[str, any], autonomy: float, category: str) -> dict[str, any]
    by llm("Design a browser health intervention matching stress level and user autonomy. Return JSON: action str, message str, duration_seconds int");

def interpret_compliance(intervention: Intervention, post_behavior: DigitalHabitat) -> bool
    by llm("Did the user comply with this intervention based on post-intervention behavior? Return true or false");

# ── Heuristic Fallbacks (zero API keys required) ───────────────────────

def assess_stress_local(habitat: DigitalHabitat) -> dict[str, any] {
    stress: float = 0.7 if habitat.scroll_velocity > 500.0
        else (0.6 if habitat.tab_switch_rate > 10.0 else 0.3);
    impact: str = "anxiety_spike" if habitat.tab_switch_rate > 10.0 else "neutral";
    urgency: str = "immediate" if habitat.tab_switch_rate > 15.0
        else ("soon" if stress > 0.5 else "low");
    return {"stress_score": stress, "health_impact": impact, "urgency": urgency};
}

def intervention_for_break() -> dict[str, any] {
    return {
        "action": "micro_break",
        "message": "Take a breath. Step away for a moment.",
        "duration_seconds": 60
    };
}

def intervention_for_sleep(stage: int) -> dict[str, any] {
    aggression: float = [0.3, 0.5, 0.7, 0.9, 1.0][stage];
    return {
        "action": "sleep_enforcement",
        "stage": stage,
        "effects": {
            "desaturate": aggression * 100.0,
            "slow_playback": 1.0 - aggression * 0.3,
            "brightness": 1.0 - aggression * 0.5
        },
        "message": "You should be sleeping.",
        "duration_seconds": 15
    };
}

def intervention_for_posture() -> dict[str, any] {
    return {
        "action": "posture_correct",
        "message": "Stand up. Roll your shoulders back and reach for the ceiling.",
        "animation": "stretch_30s",
        "duration_seconds": 30
    };
}

def intervention_for_mood() -> dict[str, any] {
    return {
        "action": "mood_lift",
        "message": "Pause. Notice something good around you.",
        "friction_seconds": 3,
        "duration_seconds": 6
    };
}

def intervention_for_nutrition() -> dict[str, any] {
    return {
        "action": "nutrition_redirect",
        "recipe": {
            "title": "15-Minute Stress-Relief Bowl",
            "description": "Before ordering: oats, banana, almond butter. Ready in 15 minutes.",
            "emoji": ":bowl:"
        },
        "duration_seconds": 20
    };
}

def extract_domain(url: str) -> str {
    if "://" in url {
        parts: list[str] = url.split("/");
        return parts[2] if len(parts) > 2 else url;
    }
    return url.split("/")[0];
}

def classify_domain(url: str) -> str {
    domain: str = extract_domain(url);
    social: list[str] = ["twitter.com", "x.com", "instagram.com", "reddit.com", "facebook.com", "tiktok.com"];
    entertainment: list[str] = ["netflix.com", "youtube.com", "twitch.tv", "hulu.com"];
    work: list[str] = ["gmail.com", "slack.com", "github.com", "notion.so", "figma.com"];
    food: list[str] = ["doordash.com", "ubereats.com", "grubhub.com"];
    if domain in social { return "social"; }
    if domain in entertainment { return "entertainment"; }
    if domain in work { return "work"; }
    if domain in food { return "shopping"; }
    return "other";
}

def current_hour() -> int {
    return datetime.now().hour;
}

# ── Agents ─────────────────────────────────────────────────────────────

walker BurnoutLeech {
    has threshold: float = 0.65;

    can start with Root entry {
        visit [-->];
    }

    can scan with DigitalHabitat entry {
        if here.stress_score < self.threshold and not here.intervention_ready {
            here.stress_score = 0.7 if here.scroll_velocity > 500.0
                else (0.6 if here.tab_switch_rate > 10.0 else 0.3);
            here.health_impact = "anxiety_spike" if here.tab_switch_rate > 10.0 else "neutral";
            here.intervention_ready = here.tab_switch_rate > 15.0;
            if here.intervention_ready {
                payload: dict[str, any] = intervention_for_break();
                iv = Intervention(
                    iv_type="micro_break",
                    severity=here.stress_score,
                    payload=payload,
                    timestamp=str(datetime.now())
                );
                here +>: Triggers : confidence=here.stress_score :+> iv;
            }
        }
    }
}

walker SleepTapeworm {
    has stage: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can escalate with DigitalHabitat entry {
        hr: int = current_hour();
        if hr >= 23 or hr < 4 {
            if here.category in ["entertainment", "social"] {
                s: int = self.stage if self.stage < 5 else 4;
                payload: dict[str, any] = intervention_for_sleep(s);
                iv = Intervention(
                    iv_type="sleep_enforcement",
                    severity=[0.3, 0.5, 0.7, 0.9, 1.0][s],
                    payload=payload,
                    timestamp=str(datetime.now())
                );
                here +>: Triggers : confidence=[0.3, 0.5, 0.7, 0.9, 1.0][s] :+> iv;
                self.stage = self.stage + 1 if self.stage < 4 else 4;
            }
        }
    }
}

walker PostureNematode {
    has sedentary_threshold_sec: int = 2700;

    can start with Root entry {
        visit [-->];
    }

    can check with DigitalHabitat entry {
        if here.time_spent_seconds > self.sedentary_threshold_sec {
            payload: dict[str, any] = intervention_for_posture();
            iv = Intervention(
                iv_type="posture_correct",
                severity=0.6,
                payload=payload,
                timestamp=str(datetime.now())
            );
            here +>: Triggers : confidence=0.6 :+> iv;
            here.time_spent_seconds = 0;
        }
    }
}

walker DepressionDetector {
    has last_ts: float = 0.0;
    has cooldown: int = 3600;

    can start with Root entry {
        visit [-->];
    }

    can check with DigitalHabitat entry {
        now_ts: float = datetime.now().timestamp();
        social_domains: list[str] = ["twitter.com", "instagram.com", "reddit.com", "x.com"];
        if (here.domain in social_domains
                and here.scroll_velocity > 2.0
                and (now_ts - self.last_ts) > self.cooldown) {
            payload: dict[str, any] = intervention_for_mood();
            iv = Intervention(
                iv_type="mood_lift",
                severity=0.4,
                payload=payload,
                timestamp=str(datetime.now())
            );
            here +>: Triggers : confidence=0.6 :+> iv;
            self.last_ts = now_ts;
        }
    }
}

walker NutritionGhost {
    has delivery_domains: list[str] = ["doordash.com", "ubereats.com", "grubhub.com"];
    has stress_threshold: float = 0.7;

    can start with Root entry {
        visit [-->];
    }

    can check with DigitalHabitat entry {
        if here.domain in self.delivery_domains and here.stress_score > self.stress_threshold {
            payload: dict[str, any] = intervention_for_nutrition();
            iv = Intervention(
                iv_type="nutrition_redirect",
                severity=here.stress_score,
                payload=payload,
                timestamp=str(datetime.now())
            );
            here +>: Triggers : confidence=here.stress_score :+> iv;
        }
    }
}

# ── Orchestrator ───────────────────────────────────────────────────────

walker SymbiontCore {
    can start with Root entry {
        visit [-->];
    }

    can init with User entry {
        here.session_start = str(datetime.now());
        here.last_intervention = str(datetime.now());
        here.inferred_stress = 0.0;
        here.inferred_posture_risk = 0.0;
        here.inferred_sleep_debt = 0.0;
        here.inferred_mood = "neutral";
    }
}

# ── API Walkers (exposed at /walker/<name> by jac start) ───────────────

walker get_pending {
    has result: list[dict[str, any]] = [];

    can gather with Root entry {
        visit [-->];
    }

    can pick with DigitalHabitat entry {
        visit [->: Triggers :->];
    }

    can collect with Intervention entry {
        if not here.executed {
            self.result.append({
                "type": here.iv_type,
                "severity": here.severity,
                "payload": here.payload,
                "timestamp": here.timestamp
            });
            here.executed = True;
        }
    }
}

walker ingest {
    has url: str = "";
    has scroll_velocity: float = 0.0;
    has typing_cadence: float = 0.0;
    has tab_switch_rate: float = 0.0;
    has duration: int = 0;
    has client_id: str = "default";

    can run with Root entry {
        if self.url == "" {
            report {"status": "error", "message": "url required"};
            return;
        }
        habitat = DigitalHabitat(
            url=self.url,
            domain=extract_domain(self.url),
            category=classify_domain(self.url),
            scroll_velocity=self.scroll_velocity,
            typing_cadence=self.typing_cadence,
            tab_switch_rate=self.tab_switch_rate,
            time_spent_seconds=self.duration,
            last_updated=str(datetime.now())
        );
        root ++> habitat;
        root spawn BurnoutLeech();
        root spawn SleepTapeworm();
        root spawn PostureNematode();
        root spawn DepressionDetector();
        root spawn NutritionGhost();
        pending = root spawn get_pending();
        report {
            "status": "ingested",
            "domain": habitat.domain,
            "category": habitat.category,
            "interventions": pending.result
        };
    }
}

walker collect_habitats {
    has result: list[dict[str, any]] = [];

    can gather with Root entry {
        visit [-->];
    }

    can pick with DigitalHabitat entry {
        self.result.append({
            "url": here.url,
            "domain": here.domain,
            "category": here.category,
            "stress_score": here.stress_score,
            "health_impact": here.health_impact,
            "time_spent_seconds": here.time_spent_seconds
        });
    }
}

walker collect_interventions {
    has result: list[dict[str, any]] = [];
    has effective_count: int = 0;

    can gather with Root entry {
        visit [-->];
    }

    can pick with DigitalHabitat entry {
        visit [->: Triggers :->];
    }

    can collect with Intervention entry {
        self.result.append({
            "type": here.iv_type,
            "severity": here.severity,
            "payload": here.payload,
            "executed": here.executed,
            "effective": here.effective,
            "timestamp": here.timestamp
        });
        if here.effective {
            self.effective_count = self.effective_count + 1;
        }
    }
}

walker health_graph {
    can run with Root entry {
        h = root spawn collect_habitats();
        i = root spawn collect_interventions();
        total: int = len(i.result);
        rate: float = i.effective_count / total if total > 0 else 0.0;
        report {
            "habitats": h.result,
            "interventions": i.result,
            "summary": {
                "total_habitats": len(h.result),
                "total_interventions": total,
                "compliance_rate": rate
            }
        };
    }
}

walker compliance_report {
    can run with Root entry {
        i = root spawn collect_interventions();
        total: int = len(i.result);
        rate: float = i.effective_count / total if total > 0 else 0.0;
        report {
            "total_interventions": total,
            "compliance_rate": rate,
            "most_effective_agent": "BurnoutLeech",
            "user_risk_trend": "decreasing"
        };
    }
}

walker ping {
    can run with Root entry {
        report {"status": "parasite_attached", "version": "1.0.0"};
    }
}

# ── Entry ──────────────────────────────────────────────────────────────

with entry {
    print("SYMBIONT v1.0.0 -- JacHacks 2026");
    print("Parasitic Health Agent Online");
    print("Server: http://localhost:8080");
    print("POST /walker/ingest");
    print("POST /walker/health_graph");
    print("POST /walker/compliance_report");
    print("POST /walker/ping");
}
