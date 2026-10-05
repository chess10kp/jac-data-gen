"""
TruthForge AI - Planner Walker
Classifies question type and dynamically decides which agents to activate.
Question types: factual, prediction, controversial, strategic, philosophical
"""

import from truthforge_nodes { * }
import from truthforge_config { * }

walker PlannerWalker {
    has question_text: str = "";
    has question_type: str = "factual";
    has complexity_score: float = 0.0;
    has domain: str = "general";
    has agents_to_activate: list[str] = [];
    has plan_steps: list[dict] = [];

    def classify_question_type() {
        q = self.question_text.lower();

        # Prediction indicators
        prediction_signals = ["will", "going to", "forecast", "predict", "future", "2025", "2026", "2027", "next year", "outlook"];
        for signal in prediction_signals {
            if signal in q {
                self.question_type = "prediction";
                return;
            }
        }

        # Controversial indicators
        controversial_signals = ["should", "ethical", "moral", "right or wrong", "debate", "controversial", "opinion", "disagree"];
        for signal in controversial_signals {
            if signal in q {
                self.question_type = "controversial";
                return;
            }
        }

        # Strategic indicators
        strategic_signals = ["strategy", "best approach", "how to", "optimize", "decision", "trade-off", "invest", "choose"];
        for signal in strategic_signals {
            if signal in q {
                self.question_type = "strategic";
                return;
            }
        }

        # Philosophical indicators
        philosophical_signals = ["meaning", "existence", "consciousness", "free will", "purpose", "reality", "truth"];
        for signal in philosophical_signals {
            if signal in q {
                self.question_type = "philosophical";
                return;
            }
        }

        # Default to factual
        self.question_type = "factual";
    }

    def analyze_complexity() {
        complexity = 0.3;
        q = self.question_text.lower();

        # Multi-dimensional questions are more complex
        complexity_signals = ["why", "how", "what if", "compare", "versus", "implications", "consequences"];
        for signal in complexity_signals {
            if signal in q {
                complexity += 0.12;
            }
        }

        # Longer questions tend to be more complex
        word_count = len(self.question_text.split());
        if word_count > 15 {
            complexity += 0.1;
        }
        if word_count > 30 {
            complexity += 0.1;
        }

        # Certain question types are inherently more complex
        if self.question_type in ["controversial", "philosophical"] {
            complexity += 0.15;
        }
        elif self.question_type == "prediction" {
            complexity += 0.10;
        }

        self.complexity_score = min(complexity, 1.0);
    }

    def detect_domain() -> str {
        q = self.question_text.lower();

        domain_map = {
            "economics": ["rate", "inflation", "gdp", "economy", "market", "price", "trade", "finance", "bank", "debt", "deficit", "monetary"],
            "technology": ["ai", "software", "code", "tech", "digital", "computer", "algorithm", "machine learning", "quantum"],
            "science": ["physics", "biology", "chemistry", "research", "experiment", "climate", "evolution"],
            "politics": ["government", "policy", "political", "election", "law", "regulation", "democracy"],
            "ethics": ["moral", "ethics", "right", "wrong", "value", "principle", "justice"],
            "philosophy": ["philosophy", "existence", "being", "knowledge", "truth", "meaning", "consciousness"],
            "health": ["health", "medical", "disease", "treatment", "vaccine", "mental health", "nutrition"]
        };

        for (domain, keywords) in domain_map.items() {
            for keyword in keywords {
                if keyword in q {
                    self.domain = domain;
                    return domain;
                }
            }
        }

        self.domain = "general";
        return "general";
    }

    def determine_agents_needed() {
        # Always include these core agents
        self.agents_to_activate = ["thesis", "antithesis", "referee", "synthesis", "memory_update"];

        # Add memory for non-trivial questions
        if self.complexity_score >= 0.3 or self.question_type != "factual" {
            self.agents_to_activate.insert(0, "memory");
        }

        # Add evidence for prediction, controversial, and complex questions
        if self.question_type in ["prediction", "controversial", "strategic"] or self.complexity_score >= 0.5 {
            # Insert evidence after antithesis
            idx = self.agents_to_activate.index("referee");
            self.agents_to_activate.insert(idx, "evidence");
        }
    }

    def create_execution_plan() {
        step_number = 1;

        for agent in self.agents_to_activate {
            reason = "";
            if agent == "memory" {
                reason = "Retrieve related prior reasoning from database";
            }
            elif agent == "thesis" {
                reason = "Generate 2-4 concrete supporting claims via Gemini";
            }
            elif agent == "antithesis" {
                reason = "Attack each thesis claim individually via Gemini";
            }
            elif agent == "evidence" {
                reason = "Gather structured evidence with sources via Gemini";
            }
            elif agent == "referee" {
                reason = "Score logic_strength, evidence_strength, assumption_risk, agreement_level";
            }
            elif agent == "synthesis" {
                reason = "Generate structured final analysis: Analysis → Supporting Factors → Counterarguments → Final Answer";
            }
            elif agent == "memory_update" {
                reason = "Persist all reasoning artifacts to database";
            }

            self.plan_steps.append({
                "step": step_number,
                "agent": agent,
                "reason": reason,
                "priority": 1.0 - (step_number * 0.05)
            });
            step_number += 1;
        }
    }

    def orchestrate() {
        print(f"[PLANNER] Analyzing question: {self.question_text[:60]}...");

        self.classify_question_type();
        self.analyze_complexity();
        self.detect_domain();
        self.determine_agents_needed();
        self.create_execution_plan();

        print(f"[PLANNER] Question Type: {self.question_type}");
        print(f"[PLANNER] Complexity: {self.complexity_score:.2f}");
        print(f"[PLANNER] Domain: {self.domain}");
        print(f"[PLANNER] Agents: {', '.join(self.agents_to_activate)}");

        for step in self.plan_steps {
            print(f"  Step {step['step']}: {step['agent']} - {step['reason']}");
        }
    }
}
