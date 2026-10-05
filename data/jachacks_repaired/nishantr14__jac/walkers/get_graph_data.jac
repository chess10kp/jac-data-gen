import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }
import from data_loader { get_interaction, get_all_interactions }

walker get_graph_data {
    can fetch with Root entry {
        nodes: list = [];
        links: list = [];
        seen_pairs: list = [];

        all_drugs = [-->[?Drug]];

        for drug in all_drugs {
            nodes.append({
                "id": drug.name,
                "name": drug.name,
                "generic_name": drug.generic_name,
                "drug_class": drug.drug_class,
                "cyp_pathway": drug.cyp_pathway,
                "half_life_hours": drug.half_life_hours
            });
        }

        for inter in get_all_interactions() {
            da_name = inter["drug_a"];
            db_name = inter["drug_b"];
            pair_key = "|".join(sorted([da_name, db_name]));
            if pair_key not in seen_pairs {
                seen_pairs.append(pair_key);
                links.append({
                    "source": da_name,
                    "target": db_name,
                    "severity": inter["severity"],
                    "mechanism": inter["mechanism"],
                    "clinical_effect": inter["clinical_effect"],
                    "evidence_level": inter["evidence_level"]
                });
            }
        }

        report {"nodes": nodes, "links": links};
    }

    class __specs__ {
        has auth: bool = False;
    }
}
