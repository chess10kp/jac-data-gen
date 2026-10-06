"""BenefitsScreeningPipeline — full flow: build financial profile → screen programs → generate report → pre-fill apps."""

import from graph.nodes.patient { Patient }
import from graph.walkers.benefits.financial_profile_builder { FinancialProfileBuilder }
import from graph.walkers.benefits.eligibility_screener { EligibilityScreener }
import from graph.walkers.benefits.benefits_report_generator { BenefitsReportGenerator }
import from graph.walkers.benefits.benefits_application_filler { BenefitsApplicationFiller }

walker BenefitsScreeningPipeline {
    can run with Patient entry {
        here spawn FinancialProfileBuilder();
        here spawn EligibilityScreener(monthly_income=0.0, total_assets=0.0);
        here spawn BenefitsReportGenerator();
        here spawn BenefitsApplicationFiller();
        report {"pipeline": "benefits_screening", "status": "complete"};
    }
}
