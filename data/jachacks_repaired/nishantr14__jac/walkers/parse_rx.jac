import from ..graph.nodes { Drug, Condition, MedProfile, RiskReport }
import from ..llm.functions { ExtractedDrugs, parse_prescription, generate_risk_summary }

walker parse_rx {
    has raw_text: str = "";
    has matched: list[str] = [];
    has unrecognised: list[str] = [];

    can parse with Root entry {
        if not self.raw_text {
            report {"error": "raw_text is required", "matched": [], "unrecognised": []};
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

        matched_names: list[str] = [];
        unrecognised_names: list[str] = [];

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
                matched_names.append(drug_node.name);
            } else {
                unrecognised_names.append(extracted_name);
            }
        }

        profile.drug_names = matched_names;
        profile.conditions = extracted.conditions_mentioned;

        self.matched = matched_names;
        self.unrecognised = unrecognised_names;

        report {
            "matched": self.matched,
            "unrecognised": self.unrecognised,
            "conditions_found": extracted.conditions_mentioned
        };
        disengage;
    }

    class __specs__ {
        has auth: bool = False;
    }
}
