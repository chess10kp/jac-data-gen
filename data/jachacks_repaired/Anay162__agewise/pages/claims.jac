"""Claims & Disputes page — open disputes with appeal progress tracker."""

import from ..client.mock_data { USE_MOCK, MOCK_DISPUTES }
import from ..components.status_badge { StatusBadge }

import from ..graph.walkers.disputes.dispute_creator { DisputeCreator }

import from "lucide-react" { AlertCircle, DollarSign, ChevronRight, Loader2 }

glob APPEAL_LEVELS: list = [
         "Redetermination",
         "QIC Reconsideration",
         "ALJ Hearing",
         "Medicare Appeals Council",
         "Federal Court"
     ];

glob ERROR_TYPE_LABELS: dict = {
         "FEE_SCHEDULE_EXCESS": "Overbilling (Fee Schedule)",
         "NCCI_PTP_VIOLATION": "Bundling Violation (NCCI)",
         "NCCI_MUE_VIOLATION": "Units Exceeded (MUE)",
         "DUPLICATE_CLAIM": "Duplicate Claim",
         "COVERAGE_DENIED": "Coverage Denied"
     };

def:pub Claims() -> JsxElement {
    has disputes: list = [];
    has loading: bool = True;

    async can with entry {
        if USE_MOCK {
            disputes = MOCK_DISPUTES;
        } else {
            result = root spawn DisputeCreator();
            if result.reports and len(result.reports) > 0 {
                disputes = result.reports[0].get("disputes", []);
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

    total_disputed = sum(d["amount_disputed"] for d in disputes);
    s_suffix = "" if len(disputes) == 1 else "s";

    return
        <div className="max-w-4xl mx-auto space-y-6">
            <div className="flex items-center justify-between flex-wrap gap-2">
                <h1>Claims & Disputes</h1>
                {<div className="text-sm text-warm-600">
                    <span className="font-semibold text-warm-900">
                        {len(disputes)}
                    </span>{" "}
                    open dispute
                    {s_suffix}{" "}
                    ·{" "}
                    <span className="font-semibold text-orange-600">
                        ${f"{total_disputed:.2f}"}
                    </span>{" "}
                    disputed
                </div>
                    if len(disputes) > 0
                    else <span></span>}
            </div>
            {<div className="card text-center py-12">
                <AlertCircle className="w-8 h-8 text-warm-300 mx-auto mb-3"/>
                <p className="text-warm-500">
                    No open disputes. All billing looks clean.
                </p>
            </div>
                if len(disputes) == 0
                else <div className="space-y-4">
                    {[
                        <div key={d["dispute_id"]} className="card">
                            <div
                                className="flex items-start justify-between gap-4 mb-4"
                            >
                                <div>
                                    <div className="flex items-center gap-2 flex-wrap">
                                        <span className="font-semibold text-warm-900">
                                            {ERROR_TYPE_LABELS.get(
                                                d["error_type"], d["error_type"]
                                            )}
                                        </span>
                                        <StatusBadge status={d["severity"]}/>
                                        <StatusBadge status={d["status"]}/>
                                    </div>
                                    <div className="text-sm text-warm-500 mt-1">
                                        Claim {d["claim_number"]} · CPT {d["cpt_code"]}
                                    </div>
                                </div>
                                <div
                                    className="flex items-center gap-1 text-orange-600 font-bold text-lg flex-shrink-0"
                                >
                                    <DollarSign className="w-4 h-4"/>
                                    {f"{d['amount_disputed']:.2f}"}
                                </div>
                            </div>
                            <p className="text-sm text-warm-700 mb-4">
                                {d["description"]}
                            </p>
                            <div className="mb-3">
                                <div className="text-xs text-warm-500 mb-2">
                                    Appeal Progress
                                </div>
                                <div className="flex items-center gap-1">
                                    {[
                                        <div
                                            key={lv[0]}
                                            className="flex items-center gap-1 flex-1"
                                        >
                                            <div
                                                className={f"flex-1 h-2 rounded-full {'bg-primary-500'
                                                    if lv[0] < d['appeal_level']
                                                    else 'bg-warm-200'}"}
                                            />
                                            {<ChevronRight
                                                className="w-3 h-3 text-warm-300 flex-shrink-0"
                                            />
                                                if lv[0] < len(APPEAL_LEVELS) - 1
                                                else <span></span>}
                                        </div> for lv in enumerate(APPEAL_LEVELS)
                                    ]}
                                </div>
                                <div className="text-xs text-warm-500 mt-1">
                                    Level {d["appeal_level"]}: {APPEAL_LEVELS[
                                        d["appeal_level"] - 1
                                    ]}{f" · Deadline: {new(Date, 
                                        d['deadline'] + 'T00:00:00'
                                    ).toLocaleDateString(
                                        'en-US',
                                        {
                                            'month': 'short',
                                            'day': 'numeric',
                                            'year': 'numeric'
                                        }
                                    )}"
                                        if d.get("deadline")
                                        else ""}
                                </div>
                            </div>
                        </div> for d in disputes
                    ]}
                </div>}
        </div>;
}
