import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }
import from ..graph.edges { Interaction }
import from data_loader { get_all_drugs, get_all_interactions, get_all_conditions }

walker seed_graph {
    has force_reseed: bool = False;

    can seed with Root entry {
        existing_drugs = [-->[?Drug]];
        if len(existing_drugs) > 0 and not self.force_reseed {
            report {"status": "already_seeded", "drug_count": len(existing_drugs)};
            disengage;
        }

        drug_nodes: dict = {};

        for d in get_all_drugs() {
            dn = Drug(
                name=d["name"],
                generic_name=d["generic_name"],
                drug_class=d["drug_class"],
                cyp_pathway=d["cyp_pathway"],
                half_life_hours=d["half_life_hours"]
            );
            here ++> dn;
            drug_nodes[d["name"]] = dn;
        }

        for c in get_all_conditions() {
            cn = Condition(
                name=c["name"],
                icd_code=c["icd_code"],
                contraindicated_drugs=c["contraindicated_drugs"]
            );
            here ++> cn;
        }

        edge_count = 0;
        for inter in get_all_interactions() {
            da_name = inter["drug_a"];
            db_name = inter["drug_b"];
            if da_name in drug_nodes and db_name in drug_nodes {
                da = drug_nodes[da_name];
                db = drug_nodes[db_name];
                da ++> db;
                db ++> da;
                edge_count += 1;
            }
        }

        report {
            "status": "seeded",
            "drug_count": len(drug_nodes),
            "edge_count": edge_count,
            "condition_count": len(get_all_conditions())
        };
    }

    class __specs__ {
        has auth: bool = False;
    }
}
