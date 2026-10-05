"""Analysis walkers for pattern detection and personalization scoring."""

import from models.memory { MemoryNode }
import from models.persona { PersonaCore, PersonaState }
import from models.preference { RewardModel }
import from models.behavior { BehaviorProfile }
import from models.decision { DecisionProfile }

import from datetime { datetime }

def identify_patterns(memories: list[str]) -> list[dict[str, str]]
    by llm(
        reason="Analyze the list of memory strings and identify recurring patterns, themes, and behavioral tendencies. For each pattern return a dict with keys: theme (str), frequency (str number), importance (str 0-1), description (str)."
    );

def extract_values(decisions: list[str]) -> list[str]
    by llm(
        reason="Analyze the list of decision descriptions and extract the underlying values that drove those decisions. Return a list of value strings ordered by how strongly they appear across the decisions. Examples of values: autonomy, security, creativity, family, achievement, fairness."
    );

walker AnalyzePatterns {
    has collected_memories: list[str] = [];
    has patterns_found: int = 0;
    has result: dict = {};

    can with entry {
        visit [-->][?:MemoryNode];
    }

    can with MemoryNode entry {
        self.collected_memories.append(here.content);
        # Continue traversing to collect all memories
        visit [-->][?:MemoryNode];
    }

    can on_exit with Root exit {
        if len(self.collected_memories) == 0 {
            report {"patterns_found": 0, "themes": []};
            disengage;
        }

        patterns = identify_patterns(self.collected_memories);

        # Create theme nodes and link related memories
        theme_nodes = [];
        for pattern in patterns {
            theme_node = MemoryNode(
                content=pattern["description"],
                memory_type="theme",
                timestamp=str(datetime.now()),
                confidence=0.6,
                importance=pattern.get("importance", 0.5),
                decay_rate=0.005,
                last_accessed=str(datetime.now()),
                access_count=0,
                user_confirmed=False
            );
            here ++> theme_node;
            theme_nodes.append({
                "theme": pattern["theme"],
                "description": pattern["description"],
                "frequency": pattern["frequency"],
                "importance": pattern.get("importance", 0.5)
            });
            self.patterns_found += 1;
        }

        self.result = {
            "patterns_found": self.patterns_found,
            "themes": theme_nodes
        };
        report self.result;
    }
}

walker ComputePersonalizationScore {
    has style_score: float = 0.0;
    has decision_score: float = 0.0;
    has timing_score: float = 0.0;
    has memory_score: float = 0.0;
    has emotion_score: float = 0.0;
    has memory_count: int = 0;
    has result: dict = {};

    can with entry {
        visit [-->][?:PersonaCore];
        visit [-->][?:RewardModel];
        visit [-->][?:BehaviorProfile];
        visit [-->][?:DecisionProfile];
        visit [-->][?:MemoryNode];
    }

    can with PersonaCore entry {
        # Style score based on persona completeness
        has_style = 1.0 if here.base_style_description else 0.0;
        has_values = min(len(here.communication_values) / 5.0, 1.0);
        has_emotional = 1.0 if here.emotional_range else 0.0;

        # Check how many persona states exist
        state_count = len([-->][?:PersonaState]);
        state_coverage = min(state_count / 4.0, 1.0);

        # Average training across states
        total_examples = 0;
        for state in [-->][?:PersonaState] {
            total_examples += state.training_examples;
        }
        training_depth = min(total_examples / 50.0, 1.0);

        self.style_score = (has_style + has_values + has_emotional + state_coverage + training_depth) / 5.0;
    }

    can with RewardModel entry {
        # Decision/preference score based on comparison count
        comparison_depth = min(here.total_comparisons / 20.0, 1.0);
        weight_balance = 1.0 - abs(here.weights.style_weight - 0.25) - abs(here.weights.utility_weight - 0.25);
        weight_balance = max(weight_balance, 0.0);

        self.decision_score = (comparison_depth * 0.7 + weight_balance * 0.3);
    }

    can with BehaviorProfile entry {
        # Timing score based on behavioral data completeness
        has_hours = 1.0 if len(here.productivity_hours) > 0 else 0.0;
        has_triggers = min(len(here.procrastination_triggers) / 3.0, 1.0);
        has_response = 1.0 if here.response_time_avg > 0 else 0.0;

        self.timing_score = (has_hours + has_triggers + has_response) / 3.0;
    }

    can with DecisionProfile entry {
        # Decision profile enrichment
        has_values = min(len(here.values_hierarchy) / 5.0, 1.0);
        has_patterns = min(len(here.self_defeating_patterns) / 2.0, 1.0);
        has_speed = 1.0 if here.avg_decision_speed > 0 else 0.0;

        # Blend with comparison-based decision score
        profile_score = (has_values + has_patterns + has_speed) / 3.0;
        self.decision_score = (self.decision_score + profile_score) / 2.0;
    }

    can with MemoryNode entry {
        self.memory_count += 1;
        # Track emotional memories for emotion score
        if here.memory_type == "emotion" {
            self.emotion_score += here.confidence;
        }
    }

    can on_exit with Root exit {
        # Finalize memory score from count
        self.memory_score = min(self.memory_count / 100.0, 1.0);

        # Normalize emotion score
        if self.memory_count > 0 {
            emotion_ratio = self.emotion_score / self.memory_count;
            self.emotion_score = min(emotion_ratio * 10.0, 1.0);
        } else {
            self.emotion_score = 0.0;
        }

        # Composite personalization score
        composite = (
            self.style_score * 0.25
            + self.decision_score * 0.20
            + self.timing_score * 0.15
            + self.memory_score * 0.25
            + self.emotion_score * 0.15
        );

        self.result = {
            "composite_score": composite,
            "dimensions": {
                "style": self.style_score,
                "decisions": self.decision_score,
                "timing": self.timing_score,
                "memory": self.memory_score,
                "emotion": self.emotion_score
            },
            "memory_count": self.memory_count
        };
        report self.result;
    }
}
