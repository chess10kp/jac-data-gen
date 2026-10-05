import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }
import from data_loader { get_interaction }

walker interaction_walk {
    has flagged_pairs: list = [];
    has traversal_log: list = [];

    can walk with MedProfile entry {
        user_drugs = [-->[?Drug]];
        user_drug_names = [d.name.lower() for d in user_drugs];

        if len(user_drugs) == 0 {
            report {"flagged_pairs": [], "traversal_log": []};
            disengage;
        }

        for i in range(len(user_drugs)) {
            for j in range(i + 1, len(user_drugs)) {
                drug = user_drugs[i];
                neighbor = user_drugs[j];
                pair = sorted([drug.name.lower(), neighbor.name.lower()]);
                pair_key = pair[0] + "|" + pair[1];

                inter = get_interaction(drug.name, neighbor.name);
                if inter {
                    is_flagged = inter["severity"] >= 2;

                    self.traversal_log.append({
                        "drug_a": pair[0],
                        "drug_b": pair[1],
                        "severity": inter["severity"],
                        "mechanism": inter["mechanism"],
                        "clinical_effect": inter["clinical_effect"],
                        "flagged": is_flagged
                    });

                    if is_flagged {
                        self.flagged_pairs.append({
                            "drug_a": pair[0],
                            "drug_b": pair[1],
                            "severity": inter["severity"],
                            "mechanism": inter["mechanism"],
                            "clinical_effect": inter["clinical_effect"],
                            "evidence_level": inter["evidence_level"]
                        });
                    }
                }
            }
        }

        report {
            "flagged_pairs": self.flagged_pairs,
            "traversal_log": self.traversal_log
        };
        disengage;
    }

    can enter_root with Root entry {
        profiles = [-->[?MedProfile]];
        if len(profiles) > 0 {
            visit profiles[0];
        } else {
            report {"flagged_pairs": [], "traversal_log": []};
            disengage;
        }
    }

    class __specs__ {
        has auth: bool = False;
    }
}
