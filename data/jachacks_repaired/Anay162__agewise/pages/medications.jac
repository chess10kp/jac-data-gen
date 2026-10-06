"""Medications page — active meds table, interaction warnings, refill alerts."""

import from ..client.mock_data { USE_MOCK, MOCK_MEDICATIONS, MOCK_INTERACTIONS }
import from ..components.medication_row { MedicationRow }

import from ..graph.walkers.prescriptions.medication_list_builder {
    MedicationListBuilder
}
import from ..graph.walkers.prescriptions.drug_interaction_checker {
    DrugInteractionChecker
}

import from "lucide-react" { AlertTriangle, Pill, Loader2 }

def:pub Medications() -> JsxElement {
    has medications: list = [];
    has interactions: list = [];
    has loading: bool = True;

    async can with entry {
        if USE_MOCK {
            medications = [
                m
                for m in MOCK_MEDICATIONS
                if m["active"]
            ];
            interactions = MOCK_INTERACTIONS;
        } else {
            meds_result: any = root spawn MedicationListBuilder();
            ix_result: any = root spawn DrugInteractionChecker();
            if meds_result.reports and len(meds_result.reports) > 0 {
                medications = meds_result.reports[0].get("medications", []);
            }
            if ix_result.reports and len(ix_result.reports) > 0 {
                interactions = ix_result.reports[0].get("interactions", []);
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

    interacting_drugs = set(
        [d.lower() for ix in interactions for d in [ix["drug_a"], ix["drug_b"]]]
    );
    overdue = [
        m
        for m in medications
        if m["days_until_refill"] < 0
    ];
    due_soon = [
        m
        for m in medications
        if m["days_until_refill"] >= 0 and m["days_until_refill"] <= 7
    ];

    return
        <div className="max-w-5xl mx-auto space-y-6">
            <h1>Medications</h1>
            {<div
                className="bg-orange-50 border border-orange-200 rounded-2xl p-4 space-y-3"
            >
                <div className="flex items-center gap-2 font-semibold text-orange-900">
                    <AlertTriangle className="w-5 h-5 text-orange-500"/>
                    Drug Interaction Warning (
                    {len(interactions)}
                    )
                </div>
                {[
                    <div
                        key={ix_p[0]}
                        className="bg-white rounded-xl p-3 border border-orange-200"
                    >
                        <div className="font-medium text-orange-900 text-sm">
                            {ix_p[1]["drug_a"]}{" "}
                            +{" "}
                            {ix_p[1]["drug_b"]}
                            <span className="ml-2 badge bg-orange-100 text-orange-700">
                                {ix_p[1]["severity"]}
                            </span>
                        </div>
                        <p className="text-sm text-warm-700 mt-1">
                            {ix_p[1]["clinical_effect"]}
                        </p>
                        <p className="text-sm text-primary-600 mt-1 font-medium">
                            {ix_p[1]["recommendation"]}
                        </p>
                    </div> for ix_p in enumerate(interactions)
                ]}
            </div>
                if len(interactions) > 0
                else <span></span>}
            {<div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {[
                    <div
                        key={m["medication_id"]}
                        className="bg-red-50 border border-red-200 rounded-xl p-3 flex items-center gap-2"
                    >
                        <Pill className="w-4 h-4 text-red-500 flex-shrink-0"/>
                        <div className="text-sm">
                            <span className="font-medium text-red-900">
                                {m["drug_name"]}
                            </span>
                            <span className="text-red-600">
                                 — refill overdue by {abs(m["days_until_refill"])} days
                            </span>
                        </div>
                    </div> for m in overdue
                ]}{[
                    <div
                        key={m["medication_id"]}
                        className="bg-yellow-50 border border-yellow-200 rounded-xl p-3 flex items-center gap-2"
                    >
                        <Pill className="w-4 h-4 text-yellow-500 flex-shrink-0"/>
                        <div className="text-sm">
                            <span className="font-medium text-yellow-900">
                                {m["drug_name"]}
                            </span>
                            <span className="text-yellow-700">
                                 — refill due in {m["days_until_refill"]} days
                            </span>
                        </div>
                    </div> for m in due_soon
                ]}
            </div>
                if (len(overdue) > 0 or len(due_soon) > 0)
                else <span></span>}
            <div className="card p-0 overflow-hidden">
                <div className="px-6 py-4 border-b border-warm-200">
                    <h2 className="font-semibold flex items-center gap-2">
                        <Pill className="w-4 h-4 text-primary-500"/>
                        Active Medications (
                        {len(medications)}
                        )
                    </h2>
                </div>
                <div className="overflow-x-auto">
                    <table className="w-full">
                        <thead>
                            <tr
                                className="bg-warm-50 text-left text-xs font-medium text-warm-500 uppercase tracking-wide"
                            >
                                <th className="py-3 px-4">Medication</th>
                                <th className="py-3 px-4">Class</th>
                                <th className="py-3 px-4">Prescriber</th>
                                <th className="py-3 px-4">Pharmacy</th>
                                <th className="py-3 px-4">Refills</th>
                                <th className="py-3 px-4 min-w-[160px]">
                                    Refill Status
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            {[
                                <MedicationRow
                                    key={m["medication_id"]}
                                    med={m}
                                    hasInteraction={m["drug_name"].lower()
                                        in interacting_drugs}
                                /> for m in medications
                            ]}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>;
}
