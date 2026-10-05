"""Trace — Trainable Personal Operating Model. Main server entry point."""

import from models.memory { MemoryNode }
import from models.persona { PersonaCore, PersonaState, ContextType, ToneParams }
import from models.preference { PreferenceComparison, RewardWeights, RewardModel }
import from models.behavior { BehaviorProfile, EnergyLevel }
import from models.decision { DecisionProfile, RiskTolerance }
import from models.user { UserProfile, CorrectionRecord }
import from models.agency { AgencyPolicy, PendingAction, AutonomyLevel }
import from walkers.ingest { IngestText, IngestConversation }
import from walkers.recall { RecallMemories }
import from walkers.generate { GenerateResponse, GenerateCandidates }
import from walkers.train { TrainPreference }
import from walkers.analyze { AnalyzePatterns, ComputePersonalizationScore }

import from datetime { datetime }
import from uuid { uuid4 }
import from hashlib { sha256 }
import from services.raw_store {
    insert_document,
    get_document,
    find_document_by_hash,
    list_documents,
    delete_document,
    count_documents
}

# ─── Initialization Walker ────────────────────────────────────────────

walker InitGraph {
    has user_name: str = "User";
    has user_email: str = "";

    can with entry {
        existing = [-->][?:UserProfile];
        if len(existing) > 0 {
            report {"status": "already_initialized"};
            disengage;
        }

        profile = UserProfile(
            user_id=str(uuid4()),
            display_name=self.user_name,
            email=self.user_email,
            created_at=str(datetime.now()),
            onboarding_complete=False,
            personalization_score=0.0
        );
        here ++> profile;

        core = PersonaCore(
            base_style_description="A thoughtful communicator who values clarity.",
            emotional_range="moderate",
            communication_values=["clarity", "honesty", "empathy"],
            active_context=ContextType.CASUAL
        );
        here ++> core;

        for ctx in [
            ContextType.WORK,
            ContextType.CASUAL,
            ContextType.FORMAL,
            ContextType.FRIENDS,
            ContextType.FAMILY
        ] {
            state = PersonaState(
                context=ctx,
                tone_params=ToneParams(
                    directness=0.5,
                    warmth=0.5,
                    formality=0.5,
                    humor=0.3,
                    verbosity=0.5
                ),
                confidence=0.1,
                training_examples=0
            );
            core ++> state;
        }

        reward = RewardModel(
            weights=RewardWeights(
                style_weight=0.35,
                utility_weight=0.35,
                timing_weight=0.15,
                decision_weight=0.15
            ),
            total_comparisons=0,
            last_updated=str(datetime.now())
        );
        here ++> reward;

        behavior = BehaviorProfile(
            productivity_hours=[
                0.1, 0.05, 0.05, 0.05, 0.05, 0.1,
                0.3, 0.5, 0.7, 0.9, 0.95, 0.85,
                0.6, 0.7, 0.8, 0.9, 0.85, 0.7,
                0.5, 0.4, 0.3, 0.2, 0.15, 0.1
            ],
            current_energy=EnergyLevel.MODERATE,
            wake_time="07:00",
            sleep_time="23:00"
        );
        here ++> behavior;

        decision_profile = DecisionProfile(
            risk_tolerance=RiskTolerance.MODERATE,
            values_hierarchy=["growth", "security", "connection", "freedom"],
            avg_decision_speed=60.0
        );
        here ++> decision_profile;

        for domain in ["email", "calendar", "messaging"] {
            policy = AgencyPolicy(
                domain=domain,
                autonomy_level=AutonomyLevel.SUGGEST
            );
            here ++> policy;
        }

        report {"status": "initialized", "user_id": profile.user_id};
    }
}

# ─── Public API Functions ─────────────────────────────────────────────

def init_user(name: str = "User", email: str = "") -> dict {
    root spawn InitGraph(user_name=name, user_email=email);
    profiles = [root-->][?:UserProfile];
    if profiles {
        return {"status": "initialized", "user_id": profiles[0].user_id};
    }
    return {"status": "error"};
}

def ingest(content: str, source_type: str = "text", source_name: str = "") -> dict {
    # Persist the raw text in the NoSQL document store first so we have
    # an auditable, re-runnable source of truth before the walker derives
    # MemoryNodes. The store is idempotent on content hash.
    doc = insert_document(
        content=content,
        source_type=source_type,
        source_name=source_name
    );
    hash_val = doc["content_hash"];

    w = root spawn IngestText(
        content=content,
        source_type=source_type,
        source_hash=hash_val
    );
    return {
        "memories_created": w.memories_created,
        "source_hash": hash_val,
        "raw_document_id": doc["_id"]
    };
}

def ingest_conversation(messages: list[dict], source_name: str = "") -> dict {
    full = str(messages);
    doc = insert_document(
        content=full,
        source_type="conversation",
        source_name=source_name,
        metadata={"message_count": len(messages)}
    );
    hash_val = doc["content_hash"];

    w = root spawn IngestConversation(
        messages=messages,
        source_hash=hash_val
    );
    return {
        "memories_created": w.memories_created,
        "relationships_found": w.relationships_found,
        "raw_document_id": doc["_id"]
    };
}

# ─── Raw document store endpoints ─────────────────────────────────────

def get_raw_document(doc_id: str) -> dict {
    doc = get_document(doc_id);
    if not doc {
        return {"error": "not_found"};
    }
    return doc;
}

def get_raw_by_hash(content_hash: str) -> dict {
    doc = find_document_by_hash(content_hash);
    if not doc {
        return {"error": "not_found"};
    }
    return doc;
}

def list_raw_documents(limit: int = 50, offset: int = 0, source_type: str = "") -> dict {
    docs = list_documents(limit=limit, offset=offset, source_type=source_type);
    # Strip bulky content field for list views — callers fetch individually.
    summaries = [];
    for d in docs {
        summaries.append({
            "_id": d["_id"],
            "content_hash": d["content_hash"],
            "source_type": d["source_type"],
            "source_name": d["source_name"],
            "ingested_at": d["ingested_at"],
            "byte_length": d["byte_length"],
            "preview": d["content"][:200],
            "metadata": d["metadata"]
        });
    }
    return {"documents": summaries, "total": count_documents()};
}

def delete_raw_document(doc_id: str) -> dict {
    ok = delete_document(doc_id);
    return {"status": "deleted" if ok else "not_found", "id": doc_id};
}

def get_memories(query: str = "", memory_type: str = "", limit: int = 50) -> dict {
    memories: list = [];
    if query {
        w = root spawn RecallMemories(query=query, max_results=limit);
        memories = w.recalled;
    } else {
        all_mem = [root-->][?:MemoryNode];
        if memory_type {
            memories = [m for m in all_mem if m.memory_type == memory_type.lower()];
        } else {
            memories = all_mem;
        }
        memories = memories[:limit];
    }

    result = [];
    for m in memories {
        result.append({
            "id": str(id(m)),
            "content": m.content,
            "memory_type": m.memory_type,
            "timestamp": m.timestamp,
            "confidence": m.confidence,
            "importance": m.importance,
            "user_confirmed": m.user_confirmed,
            "access_count": m.access_count
        });
    }
    return {"memories": result};
}

def confirm_memory(memory_id: str) -> dict {
    for m in [root-->][?:MemoryNode] {
        if str(id(m)) == memory_id {
            m.user_confirmed = True;
            m.confidence = min(1.0, m.confidence + 0.2);
            return {"status": "confirmed", "id": memory_id};
        }
    }
    return {"status": "not_found"};
}

def generate(prompt: str, mode: str = "speak_to_me", target_audience: str = "", context_type: str = "") -> dict {
    recall_w = root spawn RecallMemories(query=prompt, max_results=5);
    memory_strs = [m["content"] if isinstance(m, dict) else str(m) for m in recall_w.recalled];

    # Fetch recent corrections to include as learning context
    recent_corrections = [root-->][?:CorrectionRecord];
    correction_strs = [];
    for c in recent_corrections[-10:] {
        correction_strs.append(
            "CORRECTION (" + c.correction_type + "): The user changed \""
            + c.original + "\" to \"" + c.corrected + "\""
            + (" [context: " + c.context + "]" if c.context else "")
        );
    }

    # Combine memories with correction signals
    full_context = memory_strs + correction_strs;

    gen_w = root spawn GenerateResponse(
        prompt=prompt,
        target_audience=target_audience,
        mode=mode,
        recalled_memories=full_context
    );

    text = gen_w.generated_text if gen_w.generated_text else "I'm still learning about you. Could you share more?";
    return {
        "text": text,
        "confidence": gen_w.confidence,
        "active_context": gen_w.active_context if gen_w.active_context else "casual",
        "relevant_memories": memory_strs,
        "corrections_applied": len(correction_strs)
    };
}

def get_arena_candidates(prompt: str, context: str = "general") -> dict {
    w = root spawn GenerateCandidates(
        prompt=prompt,
        context=context
    );
    return {
        "prompt": prompt,
        "generation_a": w.candidate_a,
        "generation_b": w.candidate_b,
        "arena_session_id": str(uuid4())
    };
}

def submit_arena_judgment(
    arena_session_id: str,
    prompt: str,
    generation_a: str,
    generation_b: str,
    sounds_like_me: str,
    would_actually_send: str,
    more_useful: str,
    user_edit: str = "",
    tone_slider: float = 0.0,
    directness_slider: float = 0.0,
    warmth_slider: float = 0.0,
    formality_slider: float = 0.0
) -> dict {
    style_rating = 0.0;
    utility_rating = 0.0;

    if sounds_like_me == "a" {
        style_rating = 1.0;
    } elif sounds_like_me == "b" {
        style_rating = 0.0;
    } else {
        style_rating = 0.5;
    }

    if more_useful == "a" {
        utility_rating = 1.0;
    } elif more_useful == "b" {
        utility_rating = 0.0;
    } else {
        utility_rating = 0.5;
    }

    comp = PreferenceComparison(
        prompt=prompt,
        generation_a=generation_a,
        generation_b=generation_b,
        user_choice=would_actually_send,
        user_edit=user_edit,
        style_rating=style_rating,
        utility_rating=utility_rating,
        timestamp=str(datetime.now()),
        context=arena_session_id
    );
    root ++> comp;

    w = root spawn TrainPreference(
        prompt=prompt,
        generation_a=generation_a,
        generation_b=generation_b,
        user_choice=would_actually_send,
        user_edit=user_edit
    );

    return w.result if w.result else {"status": "trained"};
}

def get_persona() -> dict {
    cores = [root-->][?:PersonaCore];
    if not cores {
        return {"error": "not_initialized"};
    }
    core = cores[0];
    states = [core-->][?:PersonaState];
    state_list = [];
    for s in states {
        state_list.append({
            "id": str(id(s)),
            "context": str(s.context),
            "tone_params": {
                "directness": s.tone_params.directness,
                "warmth": s.tone_params.warmth,
                "formality": s.tone_params.formality,
                "humor": s.tone_params.humor,
                "verbosity": s.tone_params.verbosity
            },
            "confidence": s.confidence,
            "training_examples": s.training_examples,
            "vocabulary_profile": s.vocabulary_profile,
            "boundary_rules": s.boundary_rules
        });
    }

    return {
        "id": str(id(core)),
        "base_style_description": core.base_style_description,
        "emotional_range": core.emotional_range,
        "communication_values": core.communication_values,
        "active_context": str(core.active_context),
        "states": state_list
    };
}

def submit_correction(
    correction_type: str,
    original: str,
    corrected: str,
    context: str = ""
) -> dict {
    rec = CorrectionRecord(
        correction_type=correction_type,
        original=original,
        corrected=corrected,
        context=context,
        timestamp=str(datetime.now())
    );
    root ++> rec;
    return {
        "id": str(id(rec)),
        "correction_type": correction_type,
        "timestamp": rec.timestamp,
        "status": "recorded"
    };
}

def get_corrections(limit: int = 20) -> dict {
    all_corrections = [root-->][?:CorrectionRecord];
    result = [];
    for c in all_corrections[-limit:] {
        result.append({
            "id": str(id(c)),
            "correction_type": c.correction_type,
            "original": c.original,
            "corrected": c.corrected,
            "context": c.context,
            "timestamp": c.timestamp
        });
    }
    return {"corrections": result};
}

def get_scores() -> dict {
    w = root spawn ComputePersonalizationScore();
    if w.result {
        return w.result;
    }
    return {
        "composite_score": 0.0,
        "dimensions": {
            "style": 0.0,
            "decisions": 0.0,
            "timing": 0.0,
            "memory": 0.0,
            "emotion": 0.0
        },
        "memory_count": 0
    };
}

def get_stats() -> dict {
    memory_count = len([root-->][?:MemoryNode]);
    correction_count = len([root-->][?:CorrectionRecord]);
    comparison_count = len([root-->][?:PreferenceComparison]);
    return {
        "memory_count": memory_count,
        "correction_count": correction_count,
        "arena_judgments": comparison_count,
        "total_training_signals": memory_count + correction_count + comparison_count
    };
}

def get_profile() -> dict {
    profiles = [root-->][?:UserProfile];
    if not profiles {
        return {"error": "not_initialized"};
    }
    p = profiles[0];
    return {
        "user_id": p.user_id,
        "display_name": p.display_name,
        "email": p.email,
        "created_at": p.created_at,
        "onboarding_complete": p.onboarding_complete,
        "personalization_score": p.personalization_score,
        "devices": [
            {
                "device_id": d.device_id,
                "device_name": d.device_name,
                "trust_level": str(d.trust_level),
                "last_active": d.last_active,
                "registered": d.registered
            }
            for d in p.devices
        ]
    };
}

def get_behavior() -> dict {
    profiles = [root-->][?:BehaviorProfile];
    if not profiles {
        return {"error": "not_initialized"};
    }
    b = profiles[0];
    return {
        "productivity_hours": b.productivity_hours,
        "procrastination_triggers": b.procrastination_triggers,
        "response_time_avg": b.response_time_avg,
        "current_energy": str(b.current_energy),
        "wake_time": b.wake_time,
        "sleep_time": b.sleep_time
    };
}

def get_decision_profile() -> dict {
    profiles = [root-->][?:DecisionProfile];
    if not profiles {
        return {"error": "not_initialized"};
    }
    d = profiles[0];
    return {
        "risk_tolerance": str(d.risk_tolerance),
        "values_hierarchy": d.values_hierarchy,
        "avg_decision_speed": d.avg_decision_speed,
        "self_defeating_patterns": d.self_defeating_patterns
    };
}

def get_agency_policies() -> dict {
    policies = [root-->][?:AgencyPolicy];
    result = [];
    for p in policies {
        result.append({
            "domain": p.domain,
            "autonomy_level": str(p.autonomy_level),
            "constraints": p.constraints,
            "total_actions": p.total_actions
        });
    }
    return {"policies": result};
}

def get_pending_actions() -> dict {
    actions = [root-->][?:PendingAction, executed == False];
    result = [];
    for a in actions {
        result.append({
            "id": str(id(a)),
            "action_type": a.action_type,
            "description": a.description,
            "confidence": a.confidence,
            "domain": a.domain,
            "created_at": a.created_at,
            "approved": a.approved,
            "executed": a.executed
        });
    }
    return {"actions": result};
}

def get_insights() -> dict {
    w = root spawn AnalyzePatterns();
    return w.result if w.result else {"insights": []};
}
