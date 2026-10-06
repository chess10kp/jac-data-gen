"""Finances page — benefits eligibility screening and subscription review."""

import from ..client.mock_data { USE_MOCK, MOCK_BENEFITS, MOCK_SUBSCRIPTIONS }
import from ..components.status_badge { StatusBadge }

import from ..graph.walkers.bills.benefits_screener { BenefitsScreener }
import from ..graph.walkers.bills.subscription_reviewer { SubscriptionReviewer }

import from "lucide-react" {
    DollarSign,
    ExternalLink,
    CheckCircle2,
    XCircle,
    Loader2,
    AlertTriangle
}

def:pub Finances() -> JsxElement {
    has benefits: list = [];
    has subscriptions: list = [];
    has loading: bool = True;

    async can with entry {
        if USE_MOCK {
            benefits = MOCK_BENEFITS;
            subscriptions = MOCK_SUBSCRIPTIONS;
        } else {
            ben_result: any = root spawn BenefitsScreener();
            sub_result: any = root spawn SubscriptionReviewer();
            if ben_result.reports and len(ben_result.reports) > 0 {
                benefits = ben_result.reports[0].get("benefits", []);
            }
            if sub_result.reports and len(sub_result.reports) > 0 {
                subscriptions = sub_result.reports[0].get("subscriptions", []);
            }
        }
        loading = False;
    }

    if loading {
        return
            <div className="flex items-center justify-center h-64">
                <Loader2 className="w-8 h-8 text-primary-400 animate-spin"/>
            </div>;
    }

    eligible_benefits = [
        b
        for b in benefits
        if b["is_eligible"]
    ];
    total_monthly_savings = sum(
        b["estimated_savings_monthly"] for b in eligible_benefits
    );
    wasteful_subs = [
        s
        for s in subscriptions
        if s["classification"] in ["wasteful", "suspicious"]
    ];
    wasteful_cost = sum(s["monthly_cost"] for s in wasteful_subs);
    annual_savings = (total_monthly_savings + wasteful_cost) * 12;

    return
        <div className="max-w-4xl mx-auto space-y-6">
            <h1>Finances</h1>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="card text-center">
                    <div className="text-3xl font-bold text-accent-600">
                        ${f"{total_monthly_savings:.0f}"}/mo
                    </div>
                    <div className="text-sm text-warm-500 mt-1">
                        Potential benefits savings
                    </div>
                </div>
                <div className="card text-center">
                    <div className="text-3xl font-bold text-orange-500">
                        ${f"{wasteful_cost:.2f}"}/mo
                    </div>
                    <div className="text-sm text-warm-500 mt-1">
                        Wasteful subscriptions
                    </div>
                </div>
                <div className="card text-center">
                    <div className="text-3xl font-bold text-primary-600">
                        ${f"{annual_savings:.0f}"}/yr
                    </div>
                    <div className="text-sm text-warm-500 mt-1">
                        Total potential annual savings
                    </div>
                </div>
            </div>
            <div>
                <h2
                    className="text-base font-semibold text-warm-900 mb-3 flex items-center gap-2"
                >
                    <DollarSign className="w-4 h-4 text-accent-500"/>
                    Government Benefits Screening
                </h2>
                <div className="space-y-3">
                    {[
                        <div
                            key={b["eligibility_id"]}
                            className={f"card flex items-start gap-4 {'border-accent-200 bg-accent-50/30'
                                if b['is_eligible']
                                else ''}"}
                        >
                            <div className="mt-0.5 flex-shrink-0">
                                {<CheckCircle2 className="w-5 h-5 text-accent-500"/>
                                    if b["is_eligible"]
                                    else <XCircle className="w-5 h-5 text-warm-300"/>}
                            </div>
                            <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-2 flex-wrap">
                                    <span className="font-medium text-warm-900">
                                        {b["program_name"]}
                                    </span>
                                    <StatusBadge
                                        status={"ELIGIBLE"
                                            if b["is_eligible"]
                                            else "INELIGIBLE"}
                                    />
                                    {<span
                                        className="badge bg-accent-100 text-accent-700"
                                    >
                                        ~${b['estimated_savings_monthly']}/mo
                                    </span>
                                        if (
                                            b["is_eligible"]
                                            and b["estimated_savings_monthly"] > 0
                                        )
                                        else <span></span>}
                                </div>
                                <p className="text-sm text-warm-600 mt-1">
                                    {b["eligibility_reason"]}
                                </p>
                                {<div className="flex flex-wrap gap-3 mt-2">
                                    {<a
                                        href={b["application_url"]}
                                        target="_blank"
                                        rel="noreferrer"
                                        className="text-sm text-primary-600 hover:text-primary-800 flex items-center gap-1 font-medium"
                                    >
                                        Apply online{" "}
                                        <ExternalLink className="w-3 h-3"/>
                                    </a>
                                        if b.get("application_url")
                                        else <span></span>}{<span
                                        className="text-sm text-warm-600"
                                    >
                                        or call {b["application_phone"]}
                                    </span>
                                        if b.get("application_phone")
                                        else <span></span>}
                                </div>
                                    if b["is_eligible"]
                                    else <span></span>}
                            </div>
                        </div> for b in benefits
                    ]}
                </div>
            </div>
            {<div>
                <h2
                    className="text-base font-semibold text-warm-900 mb-3 flex items-center gap-2"
                >
                    <AlertTriangle className="w-4 h-4 text-orange-500"/>
                    Recurring Charges Review
                </h2>
                <div className="card p-0 overflow-hidden">
                    <table className="w-full">
                        <thead>
                            <tr
                                className="bg-warm-50 text-left text-xs font-medium text-warm-500 uppercase tracking-wide"
                            >
                                <th className="py-3 px-4">Service</th>
                                <th className="py-3 px-4">Monthly Cost</th>
                                <th className="py-3 px-4">Classification</th>
                                <th className="py-3 px-4">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                <tr
                                    key={sub["subscription_id"]}
                                    className={f"border-b border-warm-100 hover:bg-warm-50 {'bg-red-50/50'
                                        if sub['classification'] == 'suspicious'
                                        else (
                                            'bg-orange-50/30'
                                                if sub['classification'] == 'wasteful'
                                                else ''
                                        )}"}
                                >
                                    <td className="py-3 px-4 font-medium text-warm-900">
                                        {sub["service_name"]}
                                    </td>
                                    <td className="py-3 px-4 text-warm-700">
                                        ${f"{sub['monthly_cost']:.2f}"}
                                    </td>
                                    <td className="py-3 px-4">
                                        <StatusBadge status={sub["classification"]}/>
                                    </td>
                                    <td className="py-3 px-4">
                                        {<span
                                            className="text-sm text-red-600 font-medium"
                                        >
                                            {"Investigate + Cancel"
                                                if sub["classification"] == "suspicious"
                                                else "Consider cancelling"}
                                        </span>
                                            if sub["cancel_recommendation"]
                                            else <span></span>}
                                    </td>
                                </tr> for sub in subscriptions
                            ]}
                        </tbody>
                    </table>
                </div>
            </div>
                if len(subscriptions) > 0
                else <span></span>}
        </div>;
}
