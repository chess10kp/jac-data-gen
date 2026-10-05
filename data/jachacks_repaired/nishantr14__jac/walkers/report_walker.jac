import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }
import from ..llm.functions { ExtractedDrugs, parse_prescription, generate_risk_summary }
import from data_loader { get_interaction, get_all_interactions, get_all_conditions }
import from datetime { datetime }

walker report_walker {
    has raw_text: str = "";

    can run with Root entry {
        if not self.raw_text {
            report {"error": "raw_text is required"};
            disengage;
        }

        extracted: ExtractedDrugs = parse_prescription(self.raw_text);

        profiles = [-->[?MedProfile]];
        if len(profiles) > 0 {
            profile = profiles[0];
        } else {
            profile = MedProfile(user_id="default", drug_names=[], conditions=[]);
            here ++> profile;
        }

        old_drug_links = [profile-->[?Drug]];
        for old_drug in old_drug_links {
            profile del--> old_drug;
        }

        all_drugs = [-->[?Drug]];
        drug_name_map: dict = {};
        drug_generic_map: dict = {};
        for d in all_drugs {
            drug_name_map[d.name.lower()] = d;
            drug_generic_map[d.generic_name.lower()] = d;
        }

        matched_drugs: list[str] = [];
        unrecognised_drugs: list[str] = [];

        for extracted_name in extracted.drug_names {
            name_lower = extracted_name.lower().strip();
            drug_node: Drug | None = None;
            if name_lower in drug_name_map {
                drug_node = drug_name_map[name_lower];
            } elif name_lower in drug_generic_map {
                drug_node = drug_generic_map[name_lower];
            }
            if drug_node is not None {
                profile ++> drug_node;
                matched_drugs.append(drug_node.name);
            } else {
                unrecognised_drugs.append(extracted_name);
            }
        }

        profile.drug_names = matched_drugs;
        profile.conditions = extracted.conditions_mentioned;

        user_drug_names = [n.lower() for n in matched_drugs];
        seen_pairs: list = [];
        flagged_pairs: list = [];
        traversal_log: list = [];

        for inter in get_all_interactions() {
            da_lower = inter["drug_a"].lower();
            db_lower = inter["drug_b"].lower();
            if da_lower in user_drug_names and db_lower in user_drug_names {
                pair = sorted([da_lower, db_lower]);
                pair_key = pair[0] + "|" + pair[1];
                if pair_key not in seen_pairs {
                    seen_pairs.append(pair_key);
                    is_flagged = inter["severity"] >= 2;
                    traversal_log.append({
                        "drug_a": pair[0],
                        "drug_b": pair[1],
                        "severity": inter["severity"],
                        "mechanism": inter["mechanism"],
                        "clinical_effect": inter["clinical_effect"],
                        "flagged": is_flagged
                    });
                    if is_flagged {
                        flagged_pairs.append({
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

        user_condition_names = [c.lower() for c in extracted.conditions_mentioned];
        all_conditions = [-->[?Condition]];
        contraindications: list = [];

        for cond in all_conditions {
            if cond.name.lower() in user_condition_names {
                for contra_drug in cond.contraindicated_drugs {
                    if contra_drug.lower() in user_drug_names {
                        contraindications.append({
                            "condition": cond.name,
                            "drug": contra_drug,
                            "icd_code": cond.icd_code,
                            "reason": contra_drug + " is contraindicated in patients with " + cond.name
                        });
                    }
                }
            }
        }

        severity_max = 0;
        for pair in flagged_pairs {
            if pair["severity"] > severity_max {
                severity_max = pair["severity"];
            }
        }

        summary = generate_risk_summary(flagged_pairs, contraindications, matched_drugs);

        generated_at = datetime.utcnow().isoformat();
        report_node = RiskReport(
            flagged_pairs=flagged_pairs,
            severity_max=severity_max,
            summary=summary,
            generated_at=generated_at
        );
        profile ++> report_node;

        report {
            "flagged_pairs": flagged_pairs,
            "traversal_log": traversal_log,
            "contraindications": contraindications,
            "severity_max": severity_max,
            "matched_drugs": matched_drugs,
            "unrecognised_drugs": unrecognised_drugs,
            "summary": summary,
            "generated_at": generated_at
        };
        disengage;
    }

    class __specs__ {
        has auth: bool = False;
    }
}
