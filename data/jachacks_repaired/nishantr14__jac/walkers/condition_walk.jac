import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }

walker condition_walk {
    has contraindications: list = [];

    can walk with MedProfile entry {
        user_drug_names = [d.lower() for d in here.drug_names];
        user_condition_names = [c.lower() for c in here.conditions];

        all_conditions = [root-->[?Condition]];

        for cond in all_conditions {
            if cond.name.lower() in user_condition_names {
                for contra_drug in cond.contraindicated_drugs {
                    if contra_drug.lower() in user_drug_names {
                        self.contraindications.append({
                            "condition": cond.name,
                            "drug": contra_drug,
                            "icd_code": cond.icd_code,
                            "reason": contra_drug + " is contraindicated in patients with " + cond.name
                        });
                    }
                }
            }
        }

        report {"contraindications": self.contraindications};
        disengage;
    }

    can enter_root with Root entry {
        profiles = [-->[?MedProfile]];
        if len(profiles) > 0 {
            visit profiles[0];
        } else {
            report {"contraindications": []};
            disengage;
        }
    }

    class __specs__ {
        has auth: bool = False;
    }
}
