# HealthGraph: Triage Agent in Jaclang
import os;

enum SymptomSeverity {
    MILD,
    MODERATE,
    SEVERE
}

node Patient {
    has name: str;
    has age: int;
}

node Symptom {
    has description: str;
    has severity: SymptomSeverity;
    has duration_days: int;
}

node Diagnosis {
    has condition_name: str;
    has confidence: float;
    has recommendation: str;
}

# The function signature, types, and return type act as the prompt
def extract_symptoms(text: str) -> list[dict] by llm();
def evaluate_diagnoses(symptoms: list[str]) -> list[dict] by llm();

walker DiagnosticWalker {
    has collected_symptoms: list[str] = [];
    has diagnoses: list[dict] = [];

    can process_patient with Patient entry {
        visit [-->];
    }

    can process_symptom with Symptom entry {
        self.collected_symptoms.append(here.description);
    }

    can process_patient_exit with Patient exit {
        if len(self.collected_symptoms) > 0 {
            print(f"DiagnosticWalker evaluated symptoms: {self.collected_symptoms}");
            # self.diagnoses = evaluate_diagnoses(self.collected_symptoms);
            self.diagnoses = [{"condition_name": "Common Cold", "confidence": 0.85, "recommendation": "Rest and hydration"}];
            for diag_data in self.diagnoses {
                diag = Diagnosis(
                    condition_name=diag_data['condition_name'],
                    confidence=diag_data['confidence'],
                    recommendation=diag_data['recommendation']
                );
                here ++> diag;
                print(f"Added Diagnosis: {diag.condition_name} ({diag.confidence}) - {diag.recommendation}");
            }
        }
    }
}

walker TriageAgent {
    has patient_input: str = "";

    can process_root with Root entry {
        print("Triage Agent Started.");
        
        # 1. Create Patient
        patient = Patient(name="John Doe", age=30);
        here ++> patient;
        print(f"Created Patient: {patient.name}");
        
        # 2. Extract Symptoms (Mocking for now to avoid LLM runtime if no key)
        # extracted = extract_symptoms(self.patient_input);
        extracted = [{"description": "severe headache", "severity": "SEVERE", "duration_days": 3}, {"description": "mild fever", "severity": "MILD", "duration_days": 3}];
        print(f"Extracted Symptoms: {extracted}");
        
        # 3. Add Symptoms to Graph
        for sym_data in extracted {
            sym = Symptom(
                description=sym_data['description'],
                severity=SymptomSeverity.MILD, 
                duration_days=sym_data['duration_days']
            );
            patient ++> sym;
            print(f"Added Symptom: {sym.description}");
        }
        
        # 4. Trigger Diagnostic Walker
        patient spawn DiagnosticWalker();
    }
}

with entry {
    print("Entry point reached.");
    input_text = os.getenv("PATIENT_INPUT", "I have had a severe headache for 3 days and a mild fever.");
    root spawn TriageAgent(patient_input=input_text);
}
