"""Response generation walkers conditioned on persona and memory context."""

import from models.persona { PersonaCore, PersonaState }
import from models.memory { MemoryNode }

def generate_personalized(
    prompt: str,
    persona_description: str,
    tone: str,
    memories: list[str],
    mode: str
) -> str
    by llm(
        reason="Generate a response to the prompt that reflects the given persona description and tone. Use the provided memories as context. Mode controls perspective: speak_as_me means write as if you are the user, speak_to_me means write to the user as their assistant, speak_for_me means draft something on the user's behalf. Return the generated text."
    );

def select_context(
    audience: str,
    situation: str,
    available_contexts: list[str]
) -> str
    by llm(
        reason="Given the target audience and situation, select the most appropriate context from the available list. Consider formality level, relationship type, and communication norms. Return exactly one context name from the list."
    );

walker GenerateResponse {
    has prompt: str;
    has target_audience: str = "";
    has mode: str = "speak_to_me";
    has recalled_memories: list[str] = [];
    has generated_text: str = "";
    has confidence: float = 0.0;
    has active_context: str = "";

    can with entry {
        visit [-->][?:PersonaCore];
    }

    can with PersonaCore entry {
        # Determine the right context for this generation
        available = [];
        for ctx in [-->][?:PersonaState] {
            available.append(str(ctx.context));
        }

        if self.target_audience and len(available) > 0 {
            selected = select_context(
                self.target_audience,
                self.prompt,
                available
            );
            self.active_context = selected;
        } else {
            self.active_context = str(here.active_context);
        }

        # Visit the matching PersonaState
        for state in [-->][?:PersonaState] {
            if str(state.context) == self.active_context {
                visit state;
                disengage;
            }
        }

        # Fallback: generate with base persona if no state matched
        persona_desc = here.base_style_description;
        self.generated_text = generate_personalized(
            self.prompt,
            persona_desc,
            "balanced",
            self.recalled_memories,
            self.mode
        );
        self.confidence = 0.4;

        report {
            "text": self.generated_text,
            "confidence": self.confidence,
            "active_context": self.active_context
        };
    }

    can with PersonaState entry {
        # Build tone description from params
        tp = here.tone_params;
        tone_desc = "directness=" + str(tp.directness)
            + " warmth=" + str(tp.warmth)
            + " formality=" + str(tp.formality)
            + " humor=" + str(tp.humor)
            + " verbosity=" + str(tp.verbosity);

        # Build persona description from vocabulary and boundaries
        persona_desc = "Context: " + str(here.context)
            + ". Vocabulary: " + str(here.vocabulary_profile)
            + ". Boundaries: " + str(here.boundary_rules);

        self.generated_text = generate_personalized(
            self.prompt,
            persona_desc,
            tone_desc,
            self.recalled_memories,
            self.mode
        );
        self.confidence = here.confidence;
        self.active_context = str(here.context);

        report {
            "text": self.generated_text,
            "confidence": self.confidence,
            "active_context": self.active_context
        };
    }
}
