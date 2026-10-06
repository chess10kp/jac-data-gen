"""ModifierValidator walker — validates CPT modifier usage against CMS guidelines."""

import from graph.nodes.patient { Patient }
import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.dispute { Dispute }

import from datetime { datetime }
import from uuid { uuid4 }

# Modifiers that commonly cause billing errors
glob MODIFIER_RULES = {
    "25": "Significant, Separately Identifiable E/M on Same Day — requires distinct service documentation",
    "59": "Distinct Procedural Service — use X{EPSU} modifiers when possible",
    "22": "Increased Procedural Services — requires documentation of unusual circumstances",
    "52": "Reduced Services — charge should be reduced proportionally",
    "53": "Discontinued Procedure — charge should reflect work performed",
    "GA": "Waiver of Liability — ABN must be on file"
};
walker ModifierValidator {

    can start with Patient entry {
        visit [-->];
    }

    can check_claim with Claim entry {
        visit [-->];
    }

    can validate with LineItem entry {
        modifiers = [m for m in [here.modifier_1, here.modifier_2, here.modifier_3] if m != ""];
        if len(modifiers) == 0 {
            disengage;
        }

        for mod in modifiers {
            if mod in MODIFIER_RULES {
                rule_note = MODIFIER_RULES[mod];
                # For now, just flag modifier 25 on low-level E/M as potentially inappropriate
                if mod == "25" and here.cpt_code in ["99211", "99212"] {
                    dispute = Dispute(
                        dispute_id=str(uuid4()),
                        error_type="WRONG_MODIFIER",
                        description=(
                            f"Modifier 25 on {here.cpt_code} may be inappropriate. "
                            f"Level 1-2 E/M visits rarely warrant a separate significant E/M. "
                            f"Note: {rule_note}"
                        ),
                        amount_disputed=here.charge_amount,
                        status="OPEN",
                        flagged_date=datetime.utcnow().isoformat(),
                        confidence_score=0.65,
                        severity="LOW",
                        citations=["CMS Modifier Guidelines — Modifier 25"]
                    );
                    here ++> dispute;
                    here.has_errors = True;
                    here.error_count += 1;
                    print(f"[ModifierValidator] Modifier flag: {mod} on {here.cpt_code}");
                }
            }
        }
    }
}
