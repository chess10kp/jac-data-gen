"""JacCareRoute Jac backend.

Run from this directory with:
    jac run main.jac
    jac start main.jac

Public walkers become REST endpoints under /walker/<WalkerName> when served
with jac-scale. The FastAPI adapter in app.py exposes the app's /api/* routes
and reuses the same deterministic care engine.
"""

import from services.care_engine {
    build_call_script,
    clinic_scores,
    eligible_services,
    generate_plan,
    graph_data,
    load_dataset,
    normalize_intake,
    pharmacy_options,
    safety_check,
    translate_text
}


node UserProfile {
    has user_id: str,
        zip_code: str,
        insurance_status: str,
        budget: int,
        language: str,
        transport_mode: str,
        care_need: str,
        urgency: str,
        household: str;
}

node Clinic {
    has resource_id: str,
        name: str,
        address: str,
        zip_code: str,
        services: list[str],
        accepts_uninsured: bool,
        accepts_medicaid: bool,
        sliding_scale: bool,
        estimated_min_cost: int,
        estimated_max_cost: int,
        languages: list[str],
        open_days: list[str],
        phone: str,
        website: str;
}

node Pharmacy {
    has resource_id: str,
        name: str,
        address: str,
        zip_code: str,
        discount_available: bool,
        generic_support: bool,
        languages: list[str],
        phone: str,
        website: str;
}

node CityService {
    has resource_id: str,
        name: str,
        category: str,
        description: str,
        eligibility: str,
        documents_required: list[str],
        languages: list[str],
        phone: str,
        website: str;
}

node TransportRoute {
    has resource_id: str,
        name: str,
        mode: str,
        route_type: str,
        clinic_ids: list[str],
        estimated_time: str,
        estimated_cost: float,
        accessibility: str,
        route_summary: str;
}

node EligibilityRule {
    has program_name: str,
        income_required: str,
        insurance_required: str,
        household_required: str,
        documents_required: list[str];
}

node CostOption {
    has resource_name: str,
        cost_type: str,
        estimated_min: int,
        estimated_max: int,
        discount_available: bool,
        payment_plan_available: bool;
}

edge Nearby {}
edge EligibleFor {}
edge ReachableBy {}
edge BudgetMatch {}
edge Offers {}


def explain_with_llm(plan: dict) -> str by llm();
def translate_with_llm(text: str, language: str) -> str by llm();


walker:pub SeedGraphWalker {
    """Load demo city resources as Jac nodes connected to root."""
    can seed with Root entry {
        clinics = [-->][?:Clinic];
        if len(clinics) > 0 {
            report {"status": "already_seeded", "clinics": len(clinics)};
            disengage;
        }

        data = load_dataset();
        for clinic in data["clinics"] {
            here +>:Nearby():+> Clinic(
                resource_id=clinic["id"],
                name=clinic["name"],
                address=clinic["address"],
                zip_code=clinic["zip_code"],
                services=clinic["services"],
                accepts_uninsured=clinic["accepts_uninsured"],
                accepts_medicaid=clinic["accepts_medicaid"],
                sliding_scale=clinic["sliding_scale"],
                estimated_min_cost=clinic["estimated_min_cost"],
                estimated_max_cost=clinic["estimated_max_cost"],
                languages=clinic["languages"],
                open_days=clinic["open_days"],
                phone=clinic["phone"],
                website=clinic["website"]
            );
        }
        for pharmacy in data["pharmacies"] {
            here +>:Offers():+> Pharmacy(
                resource_id=pharmacy["id"],
                name=pharmacy["name"],
                address=pharmacy["address"],
                zip_code=pharmacy["zip_code"],
                discount_available=pharmacy["discount_available"],
                generic_support=pharmacy["generic_support"],
                languages=pharmacy["languages"],
                phone=pharmacy["phone"],
                website=pharmacy["website"]
            );
        }
        for service in data["city_services"] {
            here +>:EligibleFor():+> CityService(
                resource_id=service["id"],
                name=service["name"],
                category=service["category"],
                description=service["description"],
                eligibility=service["eligibility"],
                documents_required=service["documents_required"],
                languages=service["languages"],
                phone=service["phone"],
                website=service["website"]
            );
        }
        for route in data["transport_routes"] {
            here +>:ReachableBy():+> TransportRoute(
                resource_id=route["id"],
                name=route["name"],
                mode=route["mode"],
                route_type=route["type"],
                clinic_ids=route["clinic_ids"],
                estimated_time=route["estimated_time"],
                estimated_cost=route["estimated_cost"],
                accessibility=route["accessibility"],
                route_summary=route["route_summary"]
            );
        }
        for rule in data["eligibility_rules"] {
            here +>:EligibleFor():+> EligibilityRule(
                program_name=rule["program_name"],
                income_required=rule["income_required"],
                insurance_required=rule["insurance_required"],
                household_required=rule["household_required"],
                documents_required=rule["documents_required"]
            );
        }
        for option in data["cost_options"] {
            here +>:BudgetMatch():+> CostOption(
                resource_name=option["resource_name"],
                cost_type=option["cost_type"],
                estimated_min=option["estimated_min"],
                estimated_max=option["estimated_max"],
                discount_available=option["discount_available"],
                payment_plan_available=option["payment_plan_available"]
            );
        }
        report {
            "status": "seeded",
            "clinics": len(data["clinics"]),
            "pharmacies": len(data["pharmacies"]),
            "city_services": len(data["city_services"]),
            "transport_routes": len(data["transport_routes"]),
            "eligibility_rules": len(data["eligibility_rules"]),
            "cost_options": len(data["cost_options"])
        };
    }
}

walker:pub IntakeWalker {
    has profile: dict;

    can create with Root entry {
        normalized = normalize_intake(self.profile);
        user = UserProfile(
            user_id=normalized["user_id"],
            zip_code=normalized["zip_code"],
            insurance_status=normalized["insurance_status"],
            budget=normalized["budget"],
            language=normalized["language"],
            transport_mode=normalized["transport_mode"],
            care_need=normalized["care_need"],
            urgency=normalized["urgency"],
            household=normalized["household"]
        );
        here ++> user;
        report {"user_id": user.user_id, "status": "created", "profile": normalized};
    }
}

walker:pub SafetyWalker {
    has profile: dict;

    can check with Root entry {
        report safety_check(self.profile);
    }
}

walker:pub CareMatchWalker {
    has profile: dict;
    has visited_clinics: list[str] = [];

    can match with Root entry {
        here spawn SeedGraphWalker();
        visit [-->][?:Clinic];
        normalized = normalize_intake(self.profile);
        report {"visited_clinics": self.visited_clinics, "top_options": clinic_scores(normalized)[:5]};
    }

    can scan with Clinic entry {
        self.visited_clinics.append(here.name);
    }
}

walker:pub EligibilityWalker {
    has profile: dict;
    has visited_services: list[str] = [];

    can match with Root entry {
        here spawn SeedGraphWalker();
        visit [-->][?:CityService];
        normalized = normalize_intake(self.profile);
        report {"visited_services": self.visited_services, "city_services": eligible_services(normalized)};
    }

    can scan with CityService entry {
        self.visited_services.append(here.name);
    }
}

walker:pub TransportWalker {
    has profile: dict;
    has visited_routes: list[str] = [];

    can match with Root entry {
        here spawn SeedGraphWalker();
        visit [-->][?:TransportRoute];
        report {"visited_routes": self.visited_routes, "graph": graph_data(self.profile)};
    }

    can scan with TransportRoute entry {
        self.visited_routes.append(here.name);
    }
}

walker:pub CostRankWalker {
    has profile: dict;

    can rank with Root entry {
        normalized = normalize_intake(self.profile);
        ranked = clinic_scores(normalized);
        report {
            "ranking_algorithm": {
                "cost_fit": 30,
                "insurance_or_sliding_scale": 20,
                "distance": 15,
                "transportation": 10,
                "language": 10,
                "care_need": 10,
                "document_simplicity": 5
            },
            "top_options": ranked[:5]
        };
    }
}

walker:pub PlanExplainWalker {
    has profile: dict;

    can explain with Root entry {
        plan = generate_plan(self.profile);
        ai_summary = plan["summary"];
        try {
            ai_summary = explain_with_llm(plan);
        } except Exception {
            ai_summary = plan["summary"];
        }
        report {**plan, "ai_summary": ai_summary};
    }
}

walker:pub CallScriptWalker {
    has profile: dict;
    has language: str = "";

    can generate with Root entry {
        normalized = normalize_intake(self.profile);
        ranked = clinic_scores(normalized);
        clinic = ranked[0] if len(ranked) > 0 else None;
        target_language = self.language if self.language else normalized["language"];
        script = build_call_script(normalized, clinic, target_language);
        try {
            if target_language != "English" {
                script = translate_with_llm(script, target_language);
            }
        } except Exception {
            script = build_call_script(normalized, clinic, target_language);
        }
        report {"language": target_language, "script": script};
    }
}

walker:pub FullCareRouteWalker {
    """End-to-end Jac walker for the complete demo flow."""
    has profile: dict;

    can run with Root entry {
        here spawn SeedGraphWalker();
        normalized = normalize_intake(self.profile);
        intake_result = here spawn IntakeWalker(profile=normalized);
        safety_result = safety_check(normalized);
        plan = generate_plan(normalized);
        graph = graph_data(normalized);
        report {
            "intake": intake_result.reports,
            "safety": safety_result,
            "plan": plan,
            "graph": graph,
            "jac_walkers": [
                "IntakeWalker",
                "SafetyWalker",
                "CareMatchWalker",
                "EligibilityWalker",
                "TransportWalker",
                "CostRankWalker",
                "PlanExplainWalker",
                "CallScriptWalker"
            ]
        };
    }
}

def:pub default_payload -> dict {
    return {
        "zip_code": "",
        "insurance_status": "uninsured",
        "budget": 50,
        "language": "English",
        "transport_mode": "public_transit",
        "care_need": "",
        "urgency": "today",
        "household": ""
    };
}

def:pub graph_snapshot -> dict {
    return graph_data(default_payload());
}

with entry {
    result = root spawn FullCareRouteWalker(profile=default_payload());
    final = result.reports[len(result.reports) - 1];
    print(final["plan"]["summary"]);
}
