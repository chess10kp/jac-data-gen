"""BenefitsReportGenerator walker — generates a "benefits you may be missing" report."""

import from graph.nodes.patient { Patient }
import from graph.nodes.benefits_eligibility { BenefitsEligibility }
import from graph.nodes.benefits_report { BenefitsReport }
import from abilities.llm_abilities { generate_benefits_summary }
import from datetime { datetime }
import from uuid { uuid4 }

walker BenefitsReportGenerator {
    can generate with Patient entry {
        eligibilities = [n for n in [here-->] if isinstance(n, BenefitsEligibility)];
        eligible = [e for e in eligibilities if e.is_eligible];

        total_monthly = sum(e.estimated_savings_monthly for e in eligible);
        programs_eligible = [e.program_name for e in eligible];
        programs_screened = [e.program_name for e in eligibilities];

        summary = generate_benefits_summary(
            patient_name=here.name,
            eligible_programs=programs_eligible,
            total_monthly_savings=total_monthly
        );

        report_node = BenefitsReport(
            report_id=str(uuid4()),
            report_date=datetime.utcnow().isoformat()[:10],
            programs_screened=programs_screened,
            programs_eligible=programs_eligible,
            total_potential_monthly_value=total_monthly,
            total_potential_annual_value=total_monthly * 12,
            summary_text=summary.get("text", ""),
            created_at=datetime.utcnow().isoformat()
        );
        here ++> report_node;

        report {
            "patient": here.name,
            "programs_eligible": len(programs_eligible),
            "total_potential_annual_value": total_monthly * 12
        };
    }
}
