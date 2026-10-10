import from model.varieties { MATURE_KG, age_factor }
import from model.orchard { Block, Tree }

obj Forecast {
    has block: str;
    has total_kg: float;
    has by_variety: dict[str, float];
    has trees_counted: int;
}

def tree_kg(t: Tree) -> float {
    return MATURE_KG[t.variety.name] * age_factor(t.age);
}

walker ForecastBlock {
    can run with Block entry {
        healthy = [t for t in [here --> --> [?:Tree]] if not t.diseased];
        per: dict[str, float] = {};
        for t in healthy {
            per[t.variety.name] = per.get(t.variety.name, 0.0) + tree_kg(t);
        }
        total = 0.0;
        for v in per.values() {
            total += v;
        }
        report Forecast(block=here.name, total_kg=total, by_variety=per, trees_counted=len(healthy));
    }
}
