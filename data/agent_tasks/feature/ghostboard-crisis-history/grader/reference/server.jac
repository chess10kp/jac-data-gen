"""GHOST BOARD — Server Logic.

Handles graph persistence, LLM orchestration, and background walkers.
"""

import from .models { Executive, SystemMetrics, Crisis, IntelligenceReport, ExecutiveStatus, Severity }
import from datetime { datetime }

# -----------------------------------------------------------------------------
# AI Brain (MTP)
# -----------------------------------------------------------------------------

def generate_executive_response(crisis: str, role: str) -> str by llm(temperature=0.7);
sem generate_executive_response = "As the {role} in an AI command center, provide a strategic response to the given crisis. Keep it professional, data-driven, and under 50 words.";
sem generate_executive_response.crisis = "The crisis to respond to.";
sem generate_executive_response.role = "The executive's role.";

def generate_final_report(responses: list[str], crisis: str) -> IntelligenceReport by llm();
sem generate_final_report = "Synthesize the executive responses regarding the crisis into a final Intelligence Report. Ensure the report includes a summary, operational risk (Low/Elevated/High), infrastructure status, and actionable recommendations.";
sem generate_final_report.responses = "The executive responses to synthesize.";
sem generate_final_report.crisis = "The crisis being responded to.";

# -----------------------------------------------------------------------------
# Public API Functions
# -----------------------------------------------------------------------------

def:pub get_executives() -> list[Executive] {
    return [root-->[?:Executive]];
}

def:pub get_system_metrics() -> SystemMetrics {
    return [root-->[?:SystemMetrics]][0];
}

glob SEVERITY_RANK: dict[str, int] = {
    "INFO": 0, "WARNING": 1, "ELEVATED": 2, "HIGH": 3, "CRITICAL": 4
};

"""Past crises, newest first, optionally only those at or above a severity."""
def:pub get_crisis_history(limit: int = 10, min_severity: str = "INFO") -> list[Crisis] {
    floor = SEVERITY_RANK.get(min_severity.upper(), 0);
    crises = [
        c for c in [root-->[?:Crisis]]
        if SEVERITY_RANK.get(c.severity.value, 0) >= floor
    ];
    crises.sort(key=lambda (c: Crisis) -> str { return c.triggered_at; }, reverse=True);
    if limit <= 0 {
        return [];
    }
    return crises[:limit];
}

def:pub trigger_orchestration(crisis_msg: str) {
    root spawn OrchestrateCrisis(crisis_msg=crisis_msg);
}

# -----------------------------------------------------------------------------
# Walkers
# -----------------------------------------------------------------------------

walker OrchestrateCrisis {
    has crisis_msg: str;
    has responses: list[str] = [];

    can enter_crisis with Root entry {
        here ++> Crisis(
            id="crisis_" + datetime.now().strftime("%Y%m%d%H%M%S"),
            severity=Severity.HIGH,
            message=self.crisis_msg,
            triggered_at=datetime.now().isoformat()
        );
        visit [-->[?:Executive]];
    }

    can process_executive with Executive entry {
        here.is_thinking = True;
        here.status = ExecutiveStatus.CRISIS;

        response = generate_executive_response(self.crisis_msg, here.role);

        here.reasoning = response;
        here.is_thinking = False;
        here.status = ExecutiveStatus.SYNC;

        self.responses.append(response);
    }

    can finalize with Root exit {
        if len(self.responses) > 0 {
            report_data = generate_final_report(self.responses, self.crisis_msg);
            report_data.generated_at = datetime.now().isoformat();
            here ++> report_data;
            print("Orchestration Complete. Intelligence Report generated.");
        }
    }
}

walker SyncSystemStatus {
    can update_metrics with SystemMetrics entry {
        here.uptime_seconds += 5;
        here.system_load = 20.0 + (datetime.now().second % 30);
        here.net_latency = 10 + (datetime.now().second % 15);
    }

    can update_executive with Executive entry {
        if here.status != ExecutiveStatus.CRISIS {
            here.workflow_load = (here.workflow_load + 2.5) % 100;
            here.confidence = 95.0 + (here.workflow_load / 50.0);
        }
    }
}

# -----------------------------------------------------------------------------
# Initialization
# -----------------------------------------------------------------------------

def initialize_graph() {
    # Only spawn if they don't exist (persistence check)
    if not [root-->[?:Executive]] {
        root ++> Executive(id="ceo", name="Aura", role="CEO", color="white");
        root ++> Executive(id="cto", name="Nexus", role="CTO", color="cyan");
        root ++> Executive(id="mkt", name="Vibe", role="Marketing", color="violet");
        root ++> Executive(id="hr", name="Pulse", role="HR", color="green");
        root ++> Executive(id="ops", name="Vector", role="Operations", color="orange");
        root ++> Executive(id="sec", name="Aegis", role="Security", color="red");
    }

    if not [root-->[?:SystemMetrics]] {
        root ++> SystemMetrics();
    }
}
