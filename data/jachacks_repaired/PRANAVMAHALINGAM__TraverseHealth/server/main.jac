# Traverse Health — Pure API Backend
# Run with: jac serve main.jac
# Endpoints auto-generated at http://localhost:8000
import from os { environ }
import from urllib.request { urlopen, Request }
import from urllib.parse { urlencode, quote }
import from json { loads as json_loads, dumps as json_dumps }

# ============================================================
# Data Models
# ============================================================
obj ProviderInfo {
    has name: str = "";
    has organization: str = "";
    has specialty: str = "";
    has phone: str = "";
    has address: str = "";
    has directions_url: str = "";
}

obj SessionResult {
    has urgency: str = "PRIMARY_CARE";
    has specialty: str = "General Practice";
    has summary: str = "";
    has prep: str = "";
    has providers: list[ProviderInfo] = [];
    has language: str = "English";
}

# ============================================================
# Globals
# ============================================================
glob SPECIALTY_MAP: dict[str, list[str]] = {
         "Cardiology": [
             "chest",
             "heart",
             "palpitation",
             "blood pressure",
             "lisinopril",
             "cardiac",
             "angina",
             "arrhythmia"
         ],
         "Neurology": [
             "headache",
             "migraine",
             "dizzy",
             "numbness",
             "seizure",
             "stroke",
             "tingling",
             "vertigo"
         ],
         "Orthopedics": [
             "bone",
             "joint",
             "fracture",
             "sprain",
             "back pain",
             "knee",
             "shoulder",
             "hip"
         ],
         "Dermatology": ["rash", "skin", "acne", "itch", "mole", "eczema", "psoriasis"],
         "Gastroenterology": [
             "stomach",
             "nausea",
             "vomiting",
             "diarrhea",
             "abdominal",
             "bloating",
             "acid reflux"
         ],
         "Pulmonology": [
             "cough",
             "breathing",
             "shortness of breath",
             "asthma",
             "lung",
             "wheezing"
         ],
         "ENT": ["ear", "nose", "throat", "sinus", "hearing", "tonsil"],
         "Ophthalmology": ["eye", "vision", "blurry", "blind"],
         "Psychiatry": ["anxiety", "depression", "panic", "insomnia", "mental health"],
         "Urology": ["urinary", "kidney", "bladder", "prostate"]
     };

glob EMERGENCY_KEYWORDS: list[str] = [
         "chest pain",
         "can't breathe",
         "unconscious",
         "seizure",
         "stroke",
         "bleeding heavily",
         "heart attack",
         "severe allergic"
     ];
glob URGENT_KEYWORDS: list[str] = [
         "chest tightness",
         "shortness of breath",
         "high fever",
         "broken",
         "fracture",
         "severe pain",
         "blood in",
         "infection"
     ];
glob TELEHEALTH_KEYWORDS: list[str] = [
         "mild rash",
         "minor cold",
         "sore throat",
         "runny nose",
         "mild headache",
         "follow up",
         "refill"
     ];

# ============================================================
# State name → 2-letter abbreviation (NPI API requires abbreviation)
# ============================================================
glob STATE_ABBR: dict[str, str] = {
    "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR",
    "california": "CA", "colorado": "CO", "connecticut": "CT", "delaware": "DE",
    "florida": "FL", "georgia": "GA", "hawaii": "HI", "idaho": "ID",
    "illinois": "IL", "indiana": "IN", "iowa": "IA", "kansas": "KS",
    "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
    "massachusetts": "MA", "michigan": "MI", "minnesota": "MN", "mississippi": "MS",
    "missouri": "MO", "montana": "MT", "nebraska": "NE", "nevada": "NV",
    "new hampshire": "NH", "new jersey": "NJ", "new mexico": "NM", "new york": "NY",
    "north carolina": "NC", "north dakota": "ND", "ohio": "OH", "oklahoma": "OK",
    "oregon": "OR", "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
    "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT",
    "vermont": "VT", "virginia": "VA", "washington": "WA", "west virginia": "WV",
    "wisconsin": "WI", "wyoming": "WY", "district of columbia": "DC"
};

def to_state_abbr(state: str) -> str {
    s: str = state.strip();
    # Already an abbreviation
    if len(s) == 2 {
        return s.upper();
    }
    abbr: str = STATE_ABBR.get(s.lower(), "");
    if abbr != "" {
        return abbr;
    }
    return s;
}

# ============================================================
# NPI Registry lookup (free, no auth)
# ============================================================
"""Look up providers from the NPI Registry API.
   Returns ProviderInfo objects with name, organization, specialty, phone, address, directions_url.
   city/state come from the user's profile input."""
def lookup_npi_providers(city: str, state: str) -> list[ProviderInfo] {
    providers: list[ProviderInfo] = [];
    state_code: str = to_state_abbr(state);
    city_nospaces: str = city.replace(" ", "");
    print(f"NPI lookup: city={city_nospaces}, state={state_code}");
    try {
        params: any = urlencode(
            {
                "version": "2.1",
                "city": city_nospaces,
                "state": state_code,
                "limit": "5"
            }
        );
        url: str = f"https://npiregistry.cms.hhs.gov/api/?{params}";
        req: any = Request(url, headers={"User-Agent": "TraverseHealth/1.0"});
        response: any = urlopen(req, timeout=10);
        data: dict[str, any] = json_loads(response.read().decode("utf-8"));

        npi_results: list[any] = data.get("results", []);
        for r in npi_results {
            basic: dict[str, any] = r.get("basic", {});
            fn: str = str(basic.get("first_name", ""));
            ln: str = str(basic.get("last_name", ""));
            org: str = str(basic.get("organization_name", ""));

            name: str = "";
            if fn != "" or ln != "" {
                name = f"Dr. {fn} {ln}".strip();
            }
            if name == "" or name == "Dr." {
                name = org if org != "" else "Unknown Provider";
            }

            # Prefer LOCATION address over MAILING
            addrs: list[any] = r.get("addresses", []);
            addr: dict[str, any] = {};
            for a in addrs {
                if str(a.get("address_purpose", "")) == "LOCATION" {
                    addr = a;
                    break;
                }
            }
            if len(addr) == 0 and len(addrs) > 0 {
                addr = addrs[0];
            }

            phone: str = str(addr.get("telephone_number", ""));
            addr_1: str = str(addr.get("address_1", ""));
            addr_city: str = str(addr.get("city", ""));
            addr_state: str = str(addr.get("state", ""));
            postal_raw: str = str(addr.get("postal_code", ""));
            postal: str = postal_raw[:5] if len(postal_raw) > 5 else postal_raw;
            address: str = f"{addr_1}, {addr_city}, {addr_state} {postal}";

            # Get specialty from taxonomy
            taxonomies: list[any] = r.get("taxonomies", []);
            tax_desc: str = "";
            if len(taxonomies) > 0 {
                tax_desc = str(taxonomies[0].get("desc", ""));
            }

            directions: str = f"https://www.google.com/maps/search/{quote(address)}";

            providers.append(
                ProviderInfo(
                    name=name,
                    organization=org,
                    specialty=tax_desc,
                    phone=phone,
                    address=address,
                    directions_url=directions
                )
            );
        }
    } except Exception as e {
        print(f"NPI lookup error: {e}");
    }
    return providers;
}

# ============================================================
# Triage logic
# ============================================================
"""Classify urgency from symptom text."""
def determine_urgency(text: str) -> str {
    lower: str = text.lower();
    for kw in EMERGENCY_KEYWORDS {
        if kw in lower {
            return "EMERGENCY";
        }
    }
    for kw in URGENT_KEYWORDS {
        if kw in lower {
            return "URGENT_CARE";
        }
    }
    for kw in TELEHEALTH_KEYWORDS {
        if kw in lower {
            return "TELEHEALTH";
        }
    }
    return "PRIMARY_CARE";
}

"""Match symptoms to the best specialty."""
def determine_specialty(text: str) -> str {
    lower: str = text.lower();
    best_specialty: str = "General Practice";
    best_score: int = 0;

    for spec in SPECIALTY_MAP.keys() {
        keywords: list[str] = SPECIALTY_MAP[spec];
        score: int = 0;
        for kw in keywords {
            if kw in lower {
                score += 1;
            }
        }
        if score > best_score {
            best_score = score;
            best_specialty = spec;
        }
    }
    return best_specialty;
}

# ============================================================
# Prep instructions generator
# ============================================================
"""Generate pre-visit preparation instructions."""
def generate_prep(urgency: str, specialty: str, language: str) -> str {
    prep_map: dict[str, str] = {
        "EMERGENCY": "Call 911 immediately or go to the nearest emergency room. Do not drive yourself. If experiencing chest pain, chew an aspirin if not allergic.",
        "URGENT_CARE": "Bring your ID, insurance card, medication list, and any recent test results. Seek emergency care immediately if symptoms worsen, you develop severe chest pain, fainting, blue lips, or trouble breathing at rest.",
        "PRIMARY_CARE": "Schedule an appointment with your primary care physician. Bring your insurance card, a list of current medications, and notes about your symptoms including when they started.",
        "SPECIALIST": "Request a referral from your PCP if required by your insurance. Bring all relevant medical records, imaging results, and a complete medication list.",
        "TELEHEALTH": "Find a quiet, well-lit space with good internet. Have your insurance card and medication list ready. Write down your symptoms before the call."
    };
    return str(prep_map.get(urgency, prep_map["PRIMARY_CARE"]));
}

# ============================================================
# Summary generator
# ============================================================
"""Generate a clinical summary of the assessment."""
def generate_summary(text: str, urgency: str, specialty: str) -> str {
    urgency_desc: dict[str, str] = {
        "EMERGENCY": "requires immediate emergency medical attention",
        "URGENT_CARE": "suggests prompt evaluation with same-day assessment recommended",
        "PRIMARY_CARE": "can be evaluated during a standard medical appointment",
        "SPECIALIST": "warrants specialist consultation",
        "TELEHEALTH": "is appropriate for a telehealth visit"
    };
    desc: str = str(urgency_desc.get(urgency, "requires medical evaluation"));
    return f"Based on the reported symptoms, the presentation {desc}, with {specialty} as the best specialty match.";
}

# ============================================================
# Main API Endpoint
# ============================================================
"""
Main Traverse Health endpoint.
Analyzes symptoms, determines urgency + specialty, finds providers, generates prep.
"""
def:pub run_traverse(
    raw_input: str,
    language: str = "English",
    location: str = "Ann Arbor, Michigan"
) -> SessionResult {
    urgency: str = determine_urgency(raw_input);
    specialty: str = determine_specialty(raw_input);

    if urgency == "EMERGENCY" {
        return SessionResult(
            urgency="EMERGENCY",
            specialty="Emergency Medicine",
            summary="Your symptoms indicate a potentially life-threatening condition. Call 911 immediately or go to the nearest emergency room.",
            prep="Call 911 immediately. Do not drive yourself. If experiencing chest pain, chew an aspirin if not allergic. Unlock your door for paramedics.",
            providers=[
                ProviderInfo(
                    name="Call 911 — Nearest Emergency Room",
                    specialty="Emergency Medicine",
                    phone="911",
                    address="Nearest ER",
                    directions_url="https://www.google.com/maps/search/emergency+room+near+me"
                )
            ],
            language=language
        );
    }

    # Parse city/state from location
    parts: list[str] = location.split(",");
    city: str = "Ann Arbor";
    if len(parts) > 0 {
        city = parts[0].strip();
    }
    state: str = "Michigan";
    if len(parts) > 1 {
        state = parts[1].strip();
    }

    providers: list[ProviderInfo] = lookup_npi_providers(city, state);
    providers = providers[:3];

    summary: str = generate_summary(raw_input, urgency, specialty);
    prep: str = generate_prep(urgency, specialty, language);

    return SessionResult(
        urgency=urgency,
        specialty=specialty,
        summary=summary,
        prep=prep,
        providers=providers,
        language=language
    );
}

# ============================================================
# Conversational Triage — LLM-driven multi-turn chat
# ============================================================
obj ChatResponse {
    has message: str = "";
    has is_complete: bool = False;
    has result: SessionResult = SessionResult();
}

glob triage_chat_sem: str = """
RESPOND WITH ONLY VALID JSON. NO OTHER TEXT.

You are a medical triage assistant. Respond with EXACTLY one of these two JSON objects and nothing else:

1. If you need more information:
{"action": "question", "question": "your single follow-up question"}

2. If confident about triage:
{"action": "complete", "urgency": "EMERGENCY|URGENT_CARE|PRIMARY_CARE|SPECIALIST|TELEHEALTH", "specialty": "specialty name", "summary": "one sentence summary", "prep": "brief pre-visit instructions"}

Classification rules:
- EMERGENCY: life-threatening (chest pain, can't breathe, unconscious, stroke, severe bleeding)
- URGENT_CARE: same-day (high fever, broken bone, severe pain)
- TELEHEALTH: minor (cold, sore throat, rash)
- SPECIALIST: clear specialist need
- PRIMARY_CARE: default

Good questions: severity, duration, associated symptoms, triggers, medical history, medications.
""";

def assess_triage_conversation(conversation: str) -> str {
    payload: dict = {
        "model": "llama3:latest",
        "messages": [
            {"role": "system", "content": triage_chat_sem},
            {"role": "user", "content": conversation}
        ],
        "stream": False,
        "options": {"temperature": 0.7}
    };
    body: bytes = json_dumps(payload).encode("utf-8");
    req: Request = Request(
        "http://localhost:11434/api/chat",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST"
    );
    resp_handle: any = urlopen(req, timeout=60);
    raw_bytes: bytes = resp_handle.read();
    resp_handle.close();
    raw: dict[str, any] = json_loads(raw_bytes.decode("utf-8"));
    return str(raw["message"]["content"]);
}

"""
Conversational triage endpoint.
Accepts conversation history as [{role, content}] plus patient profile and doc flags.
Returns either the next clinical question or a completed SessionResult.
"""
def:pub triage_chat(messages: list[dict[str, str]], profile: dict[str, str], docs: dict[str, bool]) -> dict {
    # Build a readable context string for the LLM
    name_v: str = str(profile.get("name", "Patient"));
    age_v: str = str(profile.get("age", ""));
    sex_v: str = str(profile.get("sex", ""));
    city_v: str = str(profile.get("city", ""));
    state_v: str = str(profile.get("state", ""));

    profile_str: str = f"Patient: {name_v}";
    if age_v != "" {
        profile_str = profile_str + f", {age_v} years old";
    }
    if sex_v != "" {
        profile_str = profile_str + f", {sex_v}";
    }
    if city_v != "" {
        profile_str = profile_str + f", located in {city_v}";
    }
    if state_v != "" {
        profile_str = profile_str + f", {state_v}";
    }
    profile_str = profile_str + ".";

    doc_str: str = "";
    if docs.get("insurance", False) {
        doc_str = doc_str + " Insurance card on file.";
    }
    if docs.get("medications", False) {
        doc_str = doc_str + " Medication list provided.";
    }
    if docs.get("testResults", False) {
        doc_str = doc_str + " Recent test results available.";
    }

    conv_lines: str = "";
    for msg in messages {
        role: str = str(msg.get("role", "user"));
        content: str = str(msg.get("content", ""));
        if role == "assistant" {
            conv_lines = conv_lines + f"\nAssistant: {content}";
        } else {
            conv_lines = conv_lines + f"\nPatient: {content}";
        }
    }

    conversation: str = f"{profile_str}{doc_str}\n\nConversation so far:{conv_lines}";

    try {
        llm_text: str = assess_triage_conversation(conversation);
        print(f"LLM raw response: {llm_text}");

        # Extract the JSON object from the response — local models often add
        # surrounding explanation text before/after the JSON.
        start_idx: int = llm_text.find("{");
        end_idx: int = llm_text.rfind("}");
        print(f"DEBUG start_idx={start_idx} end_idx={end_idx}");
        llm_result: dict = {};
        if start_idx >= 0 and end_idx > start_idx {
            json_str: str = llm_text[start_idx:end_idx + 1];
            print(f"DEBUG json_str={json_str}");
            try {
                llm_result = json_loads(json_str);
                print(f"DEBUG llm_result={llm_result}");
            } except Exception as parse_err {
                print(f"JSON parse error: {parse_err} — raw: {json_str}");
            }
        } else {
            print("DEBUG: no JSON braces found in llm_text");
        }

        action: str = str(llm_result.get("action", "question"));
        # If no JSON was parsed, treat the raw LLM text as the question
        raw_question: str = "";
        if len(llm_result) == 0 and len(llm_text.strip()) > 0 {
            action = "question";
            raw_question = llm_text.strip();
        }
        print(f"DEBUG action={action}");

        if action == "complete" {
            urgency: str = str(llm_result.get("urgency", "PRIMARY_CARE"));
            specialty: str = str(llm_result.get("specialty", ""));
            if specialty == "" {
                specialty = "General Practice";
            }
            summary: str = str(llm_result.get("summary", ""));
            prep_text: str = str(llm_result.get("prep", ""));

            # Build location string from profile
            location: str = "Ann Arbor, Michigan";
            if city_v != "" {
                location = f"{city_v}, {state_v}";
            }

            providers: list[ProviderInfo] = [];

            if urgency == "EMERGENCY" {
                providers = [
                    ProviderInfo(
                        name="Call 911 — Nearest Emergency Room",
                        specialty="Emergency Medicine",
                        phone="911",
                        address="Nearest ER",
                        directions_url="https://www.google.com/maps/search/emergency+room+near+me"
                    )
                ];
            } else {
                npi_city: str = city_v if city_v != "" else "Ann Arbor";
                npi_state: str = state_v if state_v != "" else "Michigan";
                providers = lookup_npi_providers(npi_city, npi_state);
                providers = providers[:3];
            }

            return {
                "message": "",
                "is_complete": True,
                "result": {
                    "urgency": urgency,
                    "specialty": specialty,
                    "summary": summary,
                    "prep": prep_text,
                    "providers": [
                        {
                            "name": p.name,
                            "organization": p.organization,
                            "specialty": p.specialty,
                            "phone": p.phone,
                            "address": p.address,
                            "directions_url": p.directions_url
                        }
                        for p in providers
                    ],
                    "language": "English"
                }
            };
        } else {
            question: str = raw_question if raw_question != "" else str(
                llm_result.get(
                    "question", "Can you describe your symptoms in more detail?"
                )
            );
            print(f"DEBUG returning question: {question}");
            return {"message": question, "is_complete": False, "result": {}};
        }
    } except Exception as e {
        print(f"triage_chat error: {e}");
        return {"message": "Can you tell me more about what you're experiencing?", "is_complete": False, "result": {}};
    }
}
