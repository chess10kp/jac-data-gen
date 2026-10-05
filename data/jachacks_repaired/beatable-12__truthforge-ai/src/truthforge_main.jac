"""
TruthForge AI - Main Orchestration
Entry point for the backend reasoning engine.
Coordinates all walkers in the execution order:
  Question → Planner → Memory → Thesis → Antithesis → Evidence → Referee → Synthesis → MemoryUpdate

NOTE: At runtime, the actual execution happens in TypeScript (truthforge_api.ts).
This file serves as the architectural specification and Jac-native entry point.
"""

import time;
import from truthforge_nodes { * }
import from truthforge_config { * }
import from truthforge_planner { PlannerWalker }
import from truthforge_memory { MemoryWalker }
import from truthforge_thesis { ThesisWalker }
import from truthforge_antithesis { AntithesisWalker }
import from truthforge_evidence { EvidenceWalker }
import from truthforge_referee { RefereeWalker }
import from truthforge_synthesis { SynthesisWalker }
import from truthforge_memory_update { MemoryUpdateWalker }

obj DebateGraph {
    has nodes: dict = {};
    has edges: dict = {};
    has execution_log: list[str] = [];
    has agent_events: list[dict] = [];

    def generate_session_id() -> str {
        return f"session_{len(self.nodes)}_{time.time()}";
    }

    def log_execution(message: str) {
        self.execution_log.append(message);
        print(message);
    }

    def emit_event(agent: str, status: str, detail: str) {
        event = {
            "agent": agent,
            "status": status,
            "detail": detail,
            "timestamp": "current_timestamp"
        };
        self.agent_events.append(event);
        self.log_execution(f"[{status.upper()}] {agent}: {detail}");
    }

    def run_debate(question: str) -> dict {
        session_id = self.generate_session_id();
        question_id = f"question_{session_id}";

        self.log_execution("\n╔════════════════════════════════════════════════════╗");
        self.log_execution("║          TRUTHFORGE AI - DEBATE ORCHESTRATION       ║");
        self.log_execution("╚════════════════════════════════════════════════════╝");

        # Store initial question
        self.nodes[session_id] = {
            "question": question,
            "question_id": question_id,
            "status": "in_progress"
        };

        # ── Step 1: PLANNER ──────────────────────────────────────────
        self.emit_event("planner", "started", "Classifying question type");

        planner = PlannerWalker();
        planner.question_text = question;
        planner.orchestrate();

        self.emit_event("planner", "complete",
            f"Type: {planner.question_type} | Domain: {planner.domain} | Complexity: {planner.complexity_score:.2f}");

        complexity = "simple";
        if planner.complexity_score >= 0.6 {
            complexity = "complex";
        }
        elif planner.complexity_score >= 0.3 {
            complexity = "moderate";
        }

        # ── Step 2: MEMORY ───────────────────────────────────────────
        self.emit_event("memory", "started", "Retrieving prior reasoning");

        memory = MemoryWalker();
        memory.question_text = question;
        memory.retrieve_memory();

        memory_count = len(memory.related_memories);
        self.emit_event("memory", "complete", f"Retrieved: {memory_count} prior analyses");

        # ── Step 3: THESIS ───────────────────────────────────────────
        self.emit_event("thesis", "started", "Generating supporting claims via Gemini");

        thesis = ThesisWalker();
        thesis.question_text = question;
        thesis.question_type = planner.question_type;
        thesis.domain = planner.domain;
        thesis_result = thesis.generate_thesis(session_id);

        claim_count = thesis_result.get("total_claims", 0);
        self.emit_event("thesis", "complete", f"Claims generated: {claim_count}");

        # ── Step 4: ANTITHESIS ───────────────────────────────────────
        self.emit_event("antithesis", "started", "Generating counter-arguments via Gemini");

        thesis_claims = thesis_result.get("claims", []) as list[dict];
        if len(thesis_claims) == 0 {
            thesis_claims = thesis_result.get("supporting_claims", []) as list[dict];
            if thesis_result.get("primary_claim", {}) {
                thesis_claims.insert(0, thesis_result["primary_claim"] as dict);
            }
        }

        antithesis = AntithesisWalker();
        antithesis_result = antithesis.generate_antithesis(thesis_claims, session_id);

        counter_count = antithesis_result.get("total_counter_claims", 0);
        self.emit_event("antithesis", "complete", f"Counterclaims generated: {counter_count}");

        # ── Step 5: EVIDENCE ─────────────────────────────────────────
        evidence_list: list[dict] = [];
        if "evidence" in planner.agents_to_activate {
            self.emit_event("evidence", "started", "Gathering structured evidence via Gemini");

            evidence = EvidenceWalker();
            evidence.question_text = question;
            counter_claims = antithesis_result.get("counter_claims", antithesis_result.get("supporting_counters", [])) as list[dict];
            evidence_list = evidence.gather(thesis_claims, counter_claims, session_id);

            self.emit_event("evidence", "complete", f"Evidence retrieved: {len(evidence_list)} sources");
        }

        # ── Step 6: REFEREE ──────────────────────────────────────────
        self.emit_event("referee", "started", "Evaluating debate quality");

        referee = RefereeWalker();
        counter_claims_for_referee = antithesis_result.get("counter_claims", antithesis_result.get("supporting_counters", [])) as list[dict];
        verdict = referee.evaluate(thesis_claims, counter_claims_for_referee, evidence_list, session_id);

        self.emit_event("referee", "complete",
            f"Logic: {(verdict.get('logic_strength', 0) as float):.2f} | Evidence: {(verdict.get('evidence_strength', 0) as float):.2f}");

        # ── Step 7: SYNTHESIS ────────────────────────────────────────
        self.emit_event("synthesis", "started", "Generating final analysis");

        synthesis = SynthesisWalker();
        synthesis_result = synthesis.synthesize(
            question,
            thesis_claims,
            counter_claims_for_referee,
            evidence_list,
            verdict,
            session_id
        );

        self.emit_event("synthesis", "complete",
            f"Confidence: {synthesis_result.get('confidence', 'Moderate')}");

        # ── Step 8: MEMORY UPDATE ────────────────────────────────────
        self.emit_event("memory_update", "started", "Persisting results to database");

        agents_executed = ["planner", "memory", "thesis", "antithesis"];
        if "evidence" in planner.agents_to_activate {
            agents_executed.append("evidence");
        }
        agents_executed.extend(["referee", "synthesis", "memory_update"]);

        memory_update = MemoryUpdateWalker();
        persistence_result = memory_update.persist(
            session_id,
            question_id,
            question,
            complexity,
            thesis_claims,
            counter_claims_for_referee,
            evidence_list,
            verdict,
            synthesis_result,
            agents_executed
        );

        self.emit_event("memory_update", "complete",
            f"Persisted: {'validated' if persistence_result.get('persistence_validated') else 'failed'}");

        # ── Summary ──────────────────────────────────────────────────
        self.log_execution("\n╔════════════════════════════════════════════════════╗");
        self.log_execution("║               DEBATE COMPLETE - SUMMARY              ║");
        self.log_execution("╚════════════════════════════════════════════════════╝");
        self.log_execution(f"\nSession: {session_id}");
        self.log_execution(f"Question Type: {planner.question_type}");
        self.log_execution(f"Complexity: {complexity}");
        self.log_execution(f"Claims: {claim_count} | Counter-claims: {counter_count}");
        self.log_execution(f"Evidence: {len(evidence_list)}");

        # Update session status
        self.nodes[session_id]["status"] = "completed";

        return {
            "session_id": session_id,
            "question_id": question_id,
            "question_type": planner.question_type,
            "complexity": complexity,
            "thesis": thesis_result,
            "antithesis": antithesis_result,
            "evidence": evidence_list,
            "verdict": verdict,
            "synthesis": synthesis_result,
            "persistence": persistence_result,
            "agent_events": self.agent_events,
            "execution_log": self.execution_log
        };
    }
}

# Main entry point
def initialize_truthforge() -> DebateGraph {
    debate_graph = DebateGraph();

    # Validate config
    required_edges = ["supports", "attacks", "validated_by", "related_to", "generated_from", "discussed_in", "references", "similar_to"];

    print("TruthForge AI - Backend Core Initialized");
    print("[VALIDATION] Verifying required relation types...");

    missing_relations = [];
    for rel in required_edges {
        if rel not in RELATION_TYPES {
            missing_relations.append(rel);
        }
    }

    if len(missing_relations) > 0 {
        print(f"[VALIDATION] ⚠ Missing relation types: {', '.join(missing_relations)}");
    }
    else {
        print("[VALIDATION] ✓ All required relation types present");
    }

    print("[VALIDATION] ✓ Agent pipeline: Planner → Memory → Thesis → Antithesis → Evidence → Referee → Synthesis → MemoryUpdate");

    return debate_graph;
}
