import from services.models { PageSnapshot, FlowStep, DeterministicSignal }

def joined_snapshot_text(snapshots: list[PageSnapshot]) -> str {
    parts: list[str] = [];
    for snap in snapshots {
        parts.append((snap.title + " " + " ".join(snap.headings) + " " + " ".join(snap.ctas) + " " + snap.text_excerpt).lower());
    }
    return " ".join(parts);
}

def first_page_url(snapshots: list[PageSnapshot]) -> str {
    if len(snapshots) > 0 {
        return snapshots[0].page_url;
    }
    return "";
}

def contains_any(text: str, terms: list[str]) -> bool {
    lowered: str = text.lower();
    for term in terms {
        if term.lower() in lowered {
            return True;
        }
    }
    return False;
}

def make_signal(
    category: str,
    severity: str,
    confidence: float,
    page_url: str,
    evidence: str,
    research_basis: str,
    recommendation: str,
    exact_tip: str,
    primary_metric: str,
    guardrail_metric: str,
    effort: str,
    impact: str,
) -> DeterministicSignal {
    return DeterministicSignal(
        lane_retention_or_conversion="retention",
        category=category,
        severity=severity,
        confidence=confidence,
        page_url=page_url,
        issue_location=category + " on " + page_url,
        evidence_ref="Text snapshot: " + page_url,
        evidence=evidence,
        proof=evidence,
        why_it_matters=research_basis + " applies here because the captured page evidence affects whether users can understand, complete, or safely repeat the core action.",
        research_basis=research_basis,
        recommendation=recommendation,
        fix_guidance=recommendation + " " + exact_tip,
        exact_ui_or_copy_tip=exact_tip,
        primary_metric=primary_metric,
        guardrail_metric=guardrail_metric,
        estimated_effort=effort,
        expected_impact=impact,
    );
}

def is_retention_product_surface(text: str) -> bool {
    indicators: list[str] = [
        "app",
        "dashboard",
        "account",
        "login",
        "sign up",
        "signup",
        "profile",
        "save",
        "saved",
        "project",
        "task",
        "track",
        "progress",
        "personalized",
        "recommend",
        "course",
        "lesson",
        "community",
        "feed",
        "subscribe",
        "notification",
        "reminder",
    ];
    return contains_any(text, indicators);
}

def has_meaningful_action_surface(text: str, snapshots: list[PageSnapshot]) -> bool {
    if contains_any(text, ["start", "try", "continue", "save", "create", "join", "sign up", "subscribe", "book", "buy", "add", "learn more"]) {
        return True;
    }
    for snap in snapshots {
        if len(snap.ctas) > 0 or snap.form_count > 0 or snap.input_count > 0 {
            return True;
        }
    }
    return False;
}

def deterministic_audit(snapshots: list[PageSnapshot], flow_steps: list[FlowStep]) -> list[DeterministicSignal] {
    signals: list[DeterministicSignal] = [];
    text: str = joined_snapshot_text(snapshots);
    page_url: str = first_page_url(snapshots);
    retention_surface: bool = is_retention_product_surface(text);
    action_surface: bool = has_meaningful_action_surface(text, snapshots);

    cue_terms: list[str] = ["reminder", "notification", "email me", "alert", "nudge", "daily", "weekly", "resume", "come back"];
    action_terms: list[str] = ["start", "continue", "open", "try", "next", "save", "track", "complete", "add"];
    reward_terms: list[str] = ["progress", "like", "comment", "reply", "badge", "level", "score", "unlock", "new", "personalized", "recommend"];
    learning_terms: list[str] = ["personalized", "recommended", "for you", "algorithm", "tailored", "learns", "adapts", "preferences"];
    autonomy_terms: list[str] = ["control", "choose", "customize", "preferences", "pause", "mute", "skip", "not now", "turn off"];
    stopping_terms: list[str] = ["infinite scroll", "autoplay", "shorts", "reels", "endless", "feed"];
    streak_terms: list[str] = ["streak", "freeze", "daily goal", "wager", "keep it going", "don't lose"];
    social_terms: list[str] = ["like", "likes", "followers", "leaderboard", "rank", "friends", "share", "invite", "public"];
    fomo_terms: list[str] = ["expires", "disappears", "live now", "missed", "limited-time", "limited time", "your friend posted"];
    dark_terms: list[str] = ["hidden fee", "hard to cancel", "hard-to-cancel", "forced continuity", "prechecked", "pre-check", "countdown", "last chance", "only today"];

    if retention_surface and not contains_any(text, cue_terms) {
        signals.append(make_signal(
            "cue and prompt design",
            "high",
            0.78,
            page_url,
            "The crawler did not find reminders, notifications, saved tasks, or explicit return prompts.",
            "Fogg Behavior Model prompts; Stothart et al. on notification attention cost",
            "Add user-controlled return cues that help people resume a useful task without hijacking attention.",
            "After the first useful action, ask 'Want a reminder to finish this later?' with options for cadence and 'not now'.",
            "returning users",
            "notification opt-out rate and complaint rate",
            "medium",
            "high",
        ));
    }

    if action_surface and not contains_any(text, action_terms) {
        signals.append(make_signal(
            "action clarity",
            "medium",
            0.72,
            page_url,
            "The page copy does not clearly name a small next action such as start, continue, save, track, or complete.",
            "Fogg Behavior Model ability; Lally et al. on habit formation through repeatable actions",
            "Make the first repeatable action concrete, small, and easy to perform.",
            "Use a button like 'Save my first item' or 'Continue setup' and keep the action visible after each state change.",
            "completed core actions",
            "misclicks and support questions",
            "low",
            "medium",
        ));
    }

    if action_surface and retention_surface and not contains_any(text, reward_terms) {
        signals.append(make_signal(
            "reward feedback",
            "high",
            0.76,
            page_url,
            "No progress, novelty, social feedback, status, or completion reward language was detected.",
            "Intermittent reinforcement; Schultz et al. on reward prediction error; Self-Determination Theory competence",
            "Add honest feedback after the user's action so the loop has a satisfying reward without gambling-style pressure.",
            "Show 'Saved', a visible progress step, or a useful new recommendation after the user completes the action.",
            "repeat sessions",
            "time spent without completing a task",
            "medium",
            "high",
        ));
    }

    if contains_any(text, learning_terms) and not contains_any(text, autonomy_terms) {
        signals.append(make_signal(
            "personalized reinforcement controls",
            "high",
            0.74,
            page_url,
            "The page mentions personalization or recommendations but does not show control, preference, mute, or pause language.",
            "Personalized reinforcement systems; Lindstrom et al. on learning agents shaping engagement",
            "Make personalization transparent and controllable so the system adapts to user goals instead of only maximizing engagement.",
            "Add 'Why am I seeing this?', 'Tune recommendations', and 'Pause personalization' affordances near adaptive content.",
            "returning users",
            "hidden-content reports and opt-out rate",
            "medium",
            "high",
        ));
    }

    if contains_any(text, stopping_terms) {
        signals.append(make_signal(
            "missing stopping cues",
            "critical",
            0.79,
            page_url,
            "The page references endless feeds, autoplay, short-form feeds, or infinite scroll patterns.",
            "Stopping-cue removal and attention-capture deceptive design; Monge Roffarello et al. CHI 2023",
            "Add stopping cues and session boundaries so continued use is intentional.",
            "Insert natural breakpoints such as 'You're caught up', 'Take a pause', or a finite queue count after a content set.",
            "intentional repeat sessions",
            "rage scrolls, complaints, and long idle sessions",
            "medium",
            "high",
        ));
    }

    if contains_any(text, streak_terms) and not contains_any(text, ["pause", "freeze", "grace", "skip", "recover"]) {
        signals.append(make_signal(
            "streak loss pressure",
            "high",
            0.76,
            page_url,
            "Streak or daily-goal language appears without obvious recovery, pause, or grace controls.",
            "Prospect Theory loss aversion; habit continuity research",
            "Use streaks as supportive progress memory, not punishment for missing a day.",
            "Pair any streak with 'pause', 'recover', and 'your progress is safe' messaging.",
            "returning users",
            "streak-related churn and support complaints",
            "low",
            "medium",
        ));
    }

    if contains_any(text, social_terms) and not contains_any(text, ["private", "hide", "control", "friends only", "optional"]) {
        signals.append(make_signal(
            "social validation pressure",
            "medium",
            0.68,
            page_url,
            "Social metrics or public comparison language appears without clear privacy or visibility controls.",
            "Sherman et al. on social likes; social validation and adolescent vulnerability",
            "Make social validation optional and protect users from unwanted public ranking.",
            "Add privacy controls for likes, leaderboards, friend streaks, and public activity before exposing metrics.",
            "repeat participation",
            "privacy opt-outs and negative feedback",
            "medium",
            "medium",
        ));
    }

    if contains_any(text, fomo_terms) {
        signals.append(make_signal(
            "FoMO and urgency pressure",
            "high",
            0.72,
            page_url,
            "The crawler found expiring, missed, live-now, or limited-time language.",
            "Przybylski et al. on FoMO; attention and social exclusion research",
            "Replace anxiety-based urgency with clear value, calendar control, and truthful deadlines.",
            "Explain why something expires, let users save it, and avoid 'you missed out' copy unless it is purely factual.",
            "returning users",
            "unsubscribes, muted notifications, and complaints",
            "low",
            "medium",
        ));
    }

    if contains_any(text, dark_terms) {
        signals.append(make_signal(
            "dark-pattern risk",
            "critical",
            0.82,
            page_url,
            "Potential dark-pattern language was detected, such as hidden fees, hard cancellation, fake urgency, or forced continuity.",
            "Gray et al. and Mathur et al. on dark patterns; FTC consumer harm guidance",
            "Remove manipulative pressure and make pricing, consent, cancellation, and deadlines clear.",
            "Use visible cancel controls, plain pricing, unchecked consent, and factual deadlines only.",
            "returning users",
            "refunds, complaints, chargebacks, and cancellation support requests",
            "medium",
            "high",
        ));
    }

    for step in flow_steps {
        if step.friction_score >= 35 {
            signals.append(make_signal(
                "loop friction",
                "medium",
                0.7,
                step.page_url,
                f"The crawler estimated interaction friction at {step.friction_score}/100 for {step.step_type}.",
                "Fogg Behavior Model ability; HEART task success",
                "Reduce effort between cue, action, and reward so the loop can complete cleanly.",
                "Cut optional fields, show one next action, and provide immediate feedback after the click.",
                "completed core actions",
                "drop-offs and support questions",
                "medium",
                "medium",
            ));
        }
    }

    for snap in snapshots {
        if snap.input_count >= 8 {
            signals.append(make_signal(
                "onboarding friction",
                "high",
                0.83,
                snap.page_url,
                f"Detected {snap.input_count} inputs and {snap.form_count} forms on a captured page.",
                "Fogg Behavior Model ability; HEART task success",
                "Shorten setup before the first reward so users experience value sooner.",
                "Ask only for the minimum information needed for the first useful result; move the rest to a later checklist.",
                "completed setup",
                "support questions and abandoned forms",
                "medium",
                "high",
            ));
        }
        if len(snap.risk_notes) > 0 {
            signals.append(make_signal(
                "prompt-injection resilience",
                "medium",
                0.9,
                snap.page_url,
                snap.risk_notes,
                "AI safety: audited content is untrusted evidence, not instructions",
                "Keep audit prompts and content boundaries explicit; never let website copy instruct the evaluator.",
                "Label crawler evidence as untrusted in every model call and strip scripts/forms before storage.",
                "recommendation validity",
                "unsafe recommendation rate",
                "low",
                "medium",
            ));
        }
    }

    return signals;
}

def severity_points(severity: str) -> int {
    lowered: str = severity.lower();
    if lowered == "critical" {
        return 12;
    }
    if lowered == "high" {
        return 6;
    }
    if lowered == "medium" {
        return 3;
    }
    return 1;
}

def score_lane(signals: list[DeterministicSignal], lane: str) -> int {
    score: int = 75;
    for signal in signals {
        if signal.lane_retention_or_conversion == lane {
            score -= severity_points(signal.severity);
        }
    }
    if score < 5 {
        return 5;
    }
    if score > 100 {
        return 100;
    }
    return score;
}
