import json;
import sys;

def decide_agent(agent: dict[str, any], world: dict[str, any]) -> dict[str, any] {
    nearby_disaster = agent.get("nearby_disaster", None);
    hunger = int(agent.get("hunger", 0));
    inventory: dict[str, any] = agent.get("inventory", {});
    has_food = int(inventory.get("food", 0)) > 0;
    hungry_ally = agent.get("nearby_hungry_ally", False);
    nearest_food = agent.get("nearest_food", None);

    if nearby_disaster {
        return {
            "agent_id": agent["id"],
            "goal": "avoid_disaster",
            "reason": "Jac walker: nearby disaster has priority over economy.",
        };
    } elif hunger > 80 and nearest_food {
        return {
            "agent_id": agent["id"],
            "goal": "find_food",
            "reason": "Jac walker: hunger exceeded 80, seek nearest food.",
        };
    } elif hungry_ally and has_food {
        return {
            "agent_id": agent["id"],
            "goal": "support_ally",
            "reason": "Jac walker: trusted nearby ally is starving, share food.",
        };
    }

    trait = agent.get("civ_trait", "");
    if trait == "tech-focused" {
        goal = "invent";
    } elif trait == "militaristic" {
        goal = "patrol";
    } elif trait == "diplomatic" {
        goal = "trade";
    } elif trait == "adaptive migrants" {
        goal = "explore";
    } elif trait == "religion-driven" {
        goal = "evolve_culture";
    } else {
        goal = "explore";
    }

    return {
        "agent_id": agent["id"],
        "goal": goal,
        "reason": "Jac walker: faction trait selected the default behavior.",
    };
}

def decide_strategy(civ: dict[str, any], event: dict[str, any]) -> dict[str, any] {
    trait = civ.get("trait", "");
    event_type = event.get("type", "");

    if event_type == "plague" {
        if trait == "tech-focused" {
            strategy = "invent_vaccine";
        } elif trait == "militaristic" {
            strategy = "invade_for_medicine";
        } elif trait == "diplomatic" {
            strategy = "negotiate_aid";
        } elif trait == "adaptive migrants" {
            strategy = "migrate";
        } else {
            strategy = "quarantine";
        }
    } elif event_type == "meteor" {
        strategy = "migrate" if trait == "adaptive migrants" else "secure_crater" if trait == "militaristic" else "rebuild";
    } elif event_type == "war" {
        strategy = "invade" if trait == "militaristic" else "negotiate_ceasefire" if trait == "diplomatic" else "fortify";
    } elif event_type == "resource_boom" {
        strategy = "expand_trade";
    } elif event_type == "religion" {
        strategy = "declare_divine_sign" if trait == "religion-driven" else "contain_ideology";
    } elif event_type in ["ai_uprising", "alien_contact", "technological_revolution"] {
        strategy = "invent" if trait == "tech-focused" else "evolve_culture";
    } else {
        strategy = "adapt";
    }

    return {
        "civ_id": civ["id"],
        "walker": "decide_strategy",
        "civilization": civ.get("name", civ["id"]),
        "decision": strategy.upper(),
        "action": strategy,
        "strategy": strategy,
        "inputs": {
            "event": event_type,
            "population": civ.get("population", 0),
            "stability": civ.get("stability", 0),
            "trait": trait,
        },
        "reason": "Jac walker: event type, civilization memory, and trait selected this response.",
    };
}

def decide_civilization(civ: dict[str, any], world: dict[str, any]) -> dict[str, any] {
    trait = civ.get("trait", "");
    name: str = civ.get("name", civ["id"]) as str;
    population = int(civ.get("population", 0));
    stability = int(civ.get("stability", 0));
    technology = int(civ.get("technology", 0));
    deaths = int(civ.get("deaths", 0));
    recent_deaths = int(civ.get("recent_deaths", 0));
    threat = int(civ.get("threat_level", 0));
    nearby_enemy: str = civ.get("nearby_enemy", "") as str;
    enemy_stability = int(civ.get("enemy_stability", 100));
    trade_routes = int(civ.get("trade_routes", 0));
    active_event = civ.get("active_event", "");

    if population <= 0 {
        action = "collapse";
        reason = name + " is no longer viable, so Jac marks the civilization collapsed.";
    } elif active_event in ["plague", "meteor", "nuclear_strike", "climate_collapse"] and recent_deaths > 0 {
        if trait == "adaptive migrants" {
            action = "migrate";
            reason = name + " chose MIGRATE because recent disaster losses make staying dangerous.";
        } elif trait == "tech-focused" and active_event == "plague" {
            action = "research";
            reason = name + " chose RESEARCH because plague losses demand a technical cure.";
        } else {
            action = "recover";
            reason = name + " chose RECOVER because recent deaths and disaster pressure are high.";
        }
    } elif nearby_enemy and threat >= 70 and stability < 58 {
        action = "fortify";
        reason = name + " chose FORTIFY because stability is low and " + nearby_enemy + " is hostile nearby.";
    } elif nearby_enemy and trait == "militaristic" and enemy_stability < 70 {
        action = "attack";
        reason = name + " chose ATTACK because enemy stability is weak and military aggression is high.";
    } elif trait == "diplomatic" and threat >= 35 {
        action = "ally";
        reason = name + " chose ALLY because threat is rising and diplomacy is its strongest doctrine.";
    } elif trait == "tech-focused" and technology < 88 {
        action = "research";
        reason = name + " chose RESEARCH because its technological doctrine sees an opening to advance.";
    } elif trade_routes > 0 or trait == "diplomatic" {
        action = "trade";
        reason = name + " chose TRADE because active routes can stabilize the region.";
    } elif stability < 46 {
        action = "recover";
        reason = name + " chose RECOVER because internal stability is weak.";
    } elif threat > 80 and trait != "militaristic" {
        action = "declare_ceasefire";
        reason = name + " chose DECLARE CEASEFIRE because conflict risk exceeds its doctrine.";
    } else {
        action = "adapt";
        reason = name + " chose ADAPT because no single crisis dominates the current world state.";
    }

    return {
        "civ_id": civ["id"],
        "walker": "decide_strategy",
        "civilization": name,
        "decision": action.upper(),
        "action": action,
        "inputs": {
            "population": population,
            "stability": stability,
            "deaths": deaths,
            "recent_deaths": recent_deaths,
            "nearby_enemy": nearby_enemy,
            "threat_level": threat,
            "active_event": active_event,
            "trade_routes": trade_routes,
        },
        "reason": reason,
    };
}

with entry {
    payload = json.loads(open(sys.argv[1]).read());
    mode = payload.get("mode", "agents");

    if mode == "agents" {
        decisions = [];
        agents: list[dict[str, any]] = payload.get("agents", []);
        world: dict[str, any] = payload.get("world", {});
        for agent in agents {
            decisions.append(decide_agent(agent, world));
        }
        print(json.dumps({"source": "jac", "decisions": decisions}));
    } elif mode == "event" {
        strategies = [];
        civilizations: list[dict[str, any]] = payload.get("civilizations", []);
        event: dict[str, any] = payload.get("event", {});
        for civ in civilizations {
            strategies.append(decide_strategy(civ, event));
        }
        print(json.dumps({"source": "jac", "strategies": strategies}));
    } elif mode == "civilizations" {
        decisions = [];
        civilizations: list[dict[str, any]] = payload.get("civilizations", []);
        world: dict[str, any] = payload.get("world", {});
        for civ in civilizations {
            decisions.append(decide_civilization(civ, world));
        }
        print(json.dumps({"source": "jac", "decisions": decisions}));
    } else {
        print(json.dumps({"source": "jac", "error": "unknown mode"}));
    }
}
