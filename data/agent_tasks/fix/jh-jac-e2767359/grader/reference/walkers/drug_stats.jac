import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }
import from data_loader { get_all_interactions }

walker drug_stats {
    can fetch with Root entry {
        all_drugs = [-->[?Drug]];
        all_interactions = get_all_interactions();

        degree: dict = {};
        for d in all_drugs {
            degree[d.name] = 0;
        }

        for inter in all_interactions {
            da = inter["drug_a"];
            db = inter["drug_b"];
            if da in degree {
                degree[da] = degree[da] + 1;
            }
            if db in degree {
                degree[db] = degree[db] + 1;
            }
        }

        top_drugs: list = [];
        for drug_name in degree {
            top_drugs.append({"name": drug_name, "interaction_count": degree[drug_name]});
        }

        high_risk: list = [];
        for ent in top_drugs {
            if ent["interaction_count"] >= 3 {
                high_risk.append(ent);
            }
        }

        report {
            "total_drugs": len(all_drugs),
            "total_interactions": len(all_interactions),
            "high_risk_drugs": high_risk,
            "degree_map": degree
        };
    }

    class __specs__ {
        has auth: bool = False;
    }
}
