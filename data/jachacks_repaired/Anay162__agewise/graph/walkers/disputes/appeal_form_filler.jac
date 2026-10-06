"""AppealFormFiller walker — populates CMS appeal forms (CMS-20027, CMS-20031) with dispute data."""

import from graph.nodes.patient { Patient }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.appeal { Appeal }
import from abilities.llm_abilities { fill_appeal_form }

import from datetime { datetime }

walker AppealFormFiller {
    has patient: any = None;

    has appeal_level: int = 1,
        form_type: str = "";  # "CMS-20027" | "CMS-20031" | "ALJ"

    can start with Patient entry {
        self.patient = here;
        visit [-->];
    }

    can fill with Dispute entry {
        if here.status not in ["OPEN", "SUBMITTED"] {
            disengage;
        }
        if here.appeal_level != self.appeal_level - 1 {
            disengage;
        }

        # Determine form type by level
        form = self.form_type;
        if form == "" {
            if self.appeal_level == 1 {
                form = "CMS-20027";
            } elif self.appeal_level == 2 {
                form = "CMS-20031";
            } else {
                form = "ALJ-HEARING-REQUEST";
            }
        }

        filled = fill_appeal_form(
            form_type=form,
            dispute_id=here.dispute_id,
            error_type=here.error_type,
            description=here.description,
            amount_disputed=here.amount_disputed,
            appeal_level=self.appeal_level,
            patient_name=self.patient.name,
            patient_dob=self.patient.dob,
            medicare_id=self.patient.medicare_id
        );

        print(f"[AppealFormFiller] Form {form} filled for dispute {here.dispute_id}");
        report {"dispute_id": here.dispute_id, "form_type": form, "form_data": filled};
    }
}
