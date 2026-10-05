"""Training walkers for preference learning and candidate generation."""

import from models.preference { RewardModel, PreferenceComparison }
import from models.persona { PersonaCore, PersonaState }

import from datetime { datetime }

def analyze_style_preference(
    chosen: str,
    rejected: str,
    context: str
) -> dict[str, str]
    by llm(
        reason="Analyze why the user preferred the chosen text over the rejected text given the context. Return a dict with keys: style_delta (str number -1 to 1 indicating style preference shift), utility_delta (str number -1 to 1 indicating utility preference shift), timing_delta (str number -1 to 1 indicating timing/brevity preference shift), decision_delta (str number -1 to 1 indicating decisiveness preference shift), reasoning (str explanation of the preference pattern)."
    );

walker TrainPreference {
    has prompt: str;
    has generation_a: str;
    has generation_b: str;
    has user_choice: str;
    has user_edit: str = "";
    has learning_rate: float = 0.05;
    has update_applied: bool = False;
    has result: dict = {};

    can with entry {
        visit [-->][?:RewardModel];
    }

    can with RewardModel entry {
        # Determine chosen and rejected
        if self.user_choice == "a" {
            chosen = self.generation_a;
            rejected = self.generation_b;
        } else {
            chosen = self.generation_b;
            rejected = self.generation_a;
        }

        # If user provided an edit, that becomes the true preference signal
        if self.user_edit {
            chosen = self.user_edit;
        }

        # Analyze what the preference reveals about style
        analysis = analyze_style_preference(chosen, rejected, self.prompt);

        # Update reward weights with learning rate
        w = here.weights;
        w.style_weight += self.learning_rate * analysis.get("style_delta", 0.0);
        w.utility_weight += self.learning_rate * analysis.get("utility_delta", 0.0);
        w.timing_weight += self.learning_rate * analysis.get("timing_delta", 0.0);
        w.decision_weight += self.learning_rate * analysis.get("decision_delta", 0.0);

        # Normalize weights to sum to 1.0
        total = abs(w.style_weight) + abs(w.utility_weight) + abs(w.timing_weight) + abs(w.decision_weight);
        if total > 0 {
            w.style_weight = abs(w.style_weight) / total;
            w.utility_weight = abs(w.utility_weight) / total;
            w.timing_weight = abs(w.timing_weight) / total;
            w.decision_weight = abs(w.decision_weight) / total;
        }

        here.weights = w;
        here.total_comparisons += 1;
        here.last_updated = str(datetime.now());
        self.update_applied = True;

        # Store the comparison as a node for history
        comparison = PreferenceComparison(
            prompt=self.prompt,
            generation_a=self.generation_a,
            generation_b=self.generation_b,
            user_choice=self.user_choice,
            user_edit=self.user_edit,
            timestamp=str(datetime.now()),
            context=""
        );
        here ++> comparison;

        self.result = {
            "update_applied": self.update_applied,
            "new_weights": {
                "style": w.style_weight,
                "utility": w.utility_weight,
                "timing": w.timing_weight,
                "decision": w.decision_weight
            },
            "total_comparisons": here.total_comparisons,
            "reasoning": analysis.get("reasoning", "")
        };
        report self.result;
    }
}

walker GenerateCandidates {
    has prompt: str;
    has context: str = "";
    has candidate_a: str = "";
    has candidate_b: str = "";
    has result: dict = {};

    can with entry {
        visit [-->][?:PersonaCore];
    }

    can with PersonaCore entry {
        # Find the active persona state
        active_state = None;
        for state in [-->][?:PersonaState] {
            if str(state.context) == str(here.active_context) {
                active_state = state;
            }
        }

        if active_state is not None {
            tp = (active_state as PersonaState).tone_params;

            # Generate candidate A with current persona settings
            self.candidate_a = generate_candidate(
                self.prompt,
                here.base_style_description,
                tp.directness, tp.warmth, tp.formality,
                "standard"
            );

            # Generate candidate B with controlled variation
            self.candidate_b = generate_candidate(
                self.prompt,
                here.base_style_description,
                tp.directness, tp.warmth, tp.formality,
                "varied"
            );
        } else {
            # Fallback: generate with base style only
            self.candidate_a = generate_candidate(
                self.prompt,
                here.base_style_description,
                0.5, 0.5, 0.5,
                "standard"
            );
            self.candidate_b = generate_candidate(
                self.prompt,
                here.base_style_description,
                0.5, 0.5, 0.5,
                "varied"
            );
        }

        self.result = {
            "candidate_a": self.candidate_a,
            "candidate_b": self.candidate_b,
            "prompt": self.prompt,
            "context": self.context
        };
        report self.result;
    }
}

def generate_candidate(
    prompt: str,
    style_description: str,
    directness: float,
    warmth: float,
    formality: float,
    variation_mode: str
) -> str
    by llm(
        reason="Generate a response to the prompt in the given style. Use directness, warmth, and formality values (0-1 scale) to control tone. If variation_mode is 'varied', deliberately shift tone slightly from the parameters to explore the preference space. If 'standard', follow parameters closely. Return the generated text."
    );
