"""Documents page — ingested documents with plain-English summaries."""

import from "lucide-react" { FileText, Tag }

glob MOCK_DOCS: list = [
    {
        "id": "d1",
        "type": "MSN_PART_B",
        "source": "Mail",
        "ingested_at": "2026-03-28",
        "summary": "Medicare Part B Summary Notice for November 2025. Total billed: $350. Medicare paid: $140. You owe: $35. One item has been flagged for review.",
        "status": "PROCESSED"
    },
    {
        "id": "d2",
        "type": "APPOINTMENT_CONFIRMATION",
        "source": "Email",
        "ingested_at": "2026-03-25",
        "summary": "Appointment confirmation from Springfield Dental Group. Dr. Susan Chen on April 12, 2026 at 10:30 AM for routine cleaning.",
        "status": "PROCESSED"
    },
    {
        "id": "d3",
        "type": "EOB",
        "source": "Mail",
        "ingested_at": "2026-03-20",
        "summary": "Explanation of Benefits from Medicare for cardiology visit on February 15, 2026. Billed: $285, allowed: $197.50. Potential overbilling detected.",
        "status": "NEEDS_REVIEW"
    }
];

glob TYPE_LABELS: dict = {
    "MSN_PART_B":               "Medicare Summary",
    "EOB":                      "Explanation of Benefits",
    "APPOINTMENT_CONFIRMATION": "Appointment",
    "INSURANCE_NOTICE":         "Insurance Notice",
    "MEDICAL_BILL":             "Medical Bill"
};

glob STATUS_COLORS: dict = {
    "PROCESSED":     "bg-accent-100 text-accent-700",
    "NEEDS_REVIEW":  "bg-orange-100 text-orange-700",
    "DISPUTE_FILED": "bg-purple-100 text-purple-700"
};

def:pub Documents() -> JsxElement {
    return <div className="max-w-4xl mx-auto space-y-6">
        <div className="flex items-center justify-between">
            <h1>Documents</h1>
            <span className="badge bg-warm-200 text-warm-600">{len(MOCK_DOCS)} documents</span>
        </div>
        <div className="space-y-4">
            {[<div key={doc["id"]} className="card hover:shadow-md transition-shadow">
                <div className="flex items-start gap-4">
                    <div className="w-10 h-10 rounded-xl bg-primary-50 flex items-center justify-center flex-shrink-0">
                        <FileText className="w-5 h-5 text-primary-500" />
                    </div>
                    <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 flex-wrap mb-1">
                            <span className="font-medium text-warm-900">
                                {TYPE_LABELS.get(doc["type"], doc["type"].replace("_", " "))}
                            </span>
                            <span className={f"badge {STATUS_COLORS.get(doc['status'], 'bg-warm-200 text-warm-600')}"}>{doc["status"].replace("_", " ")}</span>
                            <span className="flex items-center gap-1 text-xs text-warm-400">
                                <Tag className="w-3 h-3" /> {doc["source"]}
                            </span>
                        </div>
                        <p className="text-sm text-warm-600 leading-relaxed">{doc["summary"]}</p>
                        <div className="text-xs text-warm-400 mt-2">
                            Received {new(Date, f"{doc['ingested_at']}T00:00:00").toLocaleDateString("en-US", {"month": "long", "day": "numeric", "year": "numeric"})}
                        </div>
                    </div>
                </div>
            </div> for doc in MOCK_DOCS]}
        </div>
    </div>;
}
