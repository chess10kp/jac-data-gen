node Location {
    has name: str;
    has risk: int = 0;
    has lat: float = 0.0;
    has lon: float = 0.0;
    has brightness: float = 0.0;
    has is_safe_zone: bool = False;
}

edge EvacuationRoute {
    has distance: float = 0.0;
    has estimated_time_minutes: float = 0.0;
}

walker EvacuationBrain {
    has fire_level: int = 0;
    has cycle: int = 0;
    has decisions: list = [];
    has memory: list = [];  # agent remembers past cycles

    def assess_threat(risk: int) -> str {
        if risk > 30 {
            return "CRITICAL";
        } elif risk > 20 {
            return "HIGH";
        } elif risk > 10 {
            return "MODERATE";
        } else {
            return "LOW";
        }
    }

    def plan_evacuation(fire_lat: float, fire_lon: float) -> dict {
        # multi-step reasoning: agent calculates safe direction
        safe_lat = fire_lat + 0.5;
        safe_lon = fire_lon + 0.5;
        distance = 0.5 * 111.0;  # approx km per degree

        return {
            "safe_lat": safe_lat,
            "safe_lon": safe_lon,
            "distance_km": distance,
            "eta_minutes": distance / 60.0 * 60.0
        };
    }

    can decide with Location entry {
        self.cycle += 1;

        # STEP 1 — assess threat level
        threat = self.assess_threat(here.risk);

        # STEP 2 — remember this assessment (memory)
        self.memory.append({
            "cycle": self.cycle,
            "node": here.name,
            "threat": threat,
            "risk": here.risk
        });

        # STEP 3 — plan based on threat (planning)
        if threat == "CRITICAL" or threat == "HIGH" {
            plan = self.plan_evacuation(here.lat, here.lon);
            self.decisions.append("EVACUATE " + here.name +
                " → safe zone at " + str(plan["safe_lat"]) +
                ", " + str(plan["safe_lon"]) +
                " | ETA: " + str(plan["eta_minutes"]) + " min");
            report {
                "status": "EVACUATE",
                "node": here.name,
                "threat": threat,
                "risk": here.risk,
                "plan": plan,
                "memory_depth": len(self.memory)
            };

        } elif threat == "MODERATE" {
            self.decisions.append("MONITOR " + here.name);
            report {
                "status": "MONITOR",
                "node": here.name,
                "threat": threat,
                "risk": here.risk,
                "memory_depth": len(self.memory)
            };

        } else {
            report {
                "status": "NORMAL",
                "node": here.name,
                "threat": threat,
                "risk": here.risk,
                "memory_depth": len(self.memory)
            };
        }

        # STEP 4 — if memory shows 3 consecutive HIGH threats, escalate
        if len(self.memory) >= 3 {
            last3 = self.memory[-3:];
            all_high = True;
            for m in last3 {
                if m["threat"] == "LOW" or m["threat"] == "MODERATE" {
                    all_high = False;
                }
            }
            if all_high {
                report {
                    "status": "ESCALATION",
                    "message": "3 consecutive high-threat cycles — mass evacuation required",
                    "node": here.name
                };
            }
        }
    }
}

with entry {
    # build a graph of locations
    root_node = root;

    fire_zone   = Location(name="Fire Zone",    risk=35, lat=-19.30, lon=16.31, brightness=332.0);
    buffer_zone = Location(name="Buffer Zone",  risk=15, lat=-18.90, lon=16.70);
    safe_zone   = Location(name="Safe Zone",    risk=2,  lat=-18.50, lon=17.10, is_safe_zone=True);

    root_node ++> fire_zone;
    fire_zone   +>:EvacuationRoute(distance=50.0, estimated_time_minutes=45.0):+> buffer_zone;
    buffer_zone +>:EvacuationRoute(distance=50.0, estimated_time_minutes=45.0):+> safe_zone;

    # spawn the agent walker
    brain = EvacuationBrain(fire_level=35, cycle=0);
    root_node spawn brain;
}