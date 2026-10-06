"""Dashboard — weekly digest, action items, and stat cards."""

import from ..client.mock_data {
    USE_MOCK,
    MOCK_DIGEST,
    MOCK_APPOINTMENTS,
    MOCK_MEDICATIONS,
    MOCK_BENEFITS
}
import from ..components.action_item { ActionItem }

import from ..graph.walkers.intake.digest_generator { DigestGenerator }
import from ..graph.walkers.appointments.care_gap_detector { CareGapDetector }
import from ..graph.walkers.prescriptions.refill_monitor { RefillMonitor }
import from ..graph.walkers.bills.benefits_screener { BenefitsScreener }

import from "lucide-react" {
    Calendar,
    Pill,
    DollarSign,
    AlertCircle,
    TrendingUp,
    Loader2
}

def StatCard(props: dict) -> JsxElement {
    Icon = props.get("icon");
    label = props.get("label", "");
    value = props.get("value", 0);
    sublabel = props.get("sublabel", "");
    color = props.get("color", "bg-primary-500");

    return
        <div className="card flex items-center gap-4">
            <div
                className={f"w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 {color}"}
            >
                <Icon className="w-6 h-6 text-white"/>
            </div>
            <div>
                <div className="text-2xl font-bold text-warm-900">{value}</div>
                <div className="text-sm text-warm-500">{label}</div>
                {<div className="text-xs text-warm-400 mt-0.5">{sublabel}</div>
                    if sublabel
                    else <span></span>}
            </div>
        </div>;
}

def:pub Dashboard() -> JsxElement {
    has digest: dict = {};
    has stats: dict = {
        "appointments": 0,
        "refillsDue": 0,
        "openDisputes": 1,
        "benefitsFound": 0
    };
    has loading: bool = True;

    async can with entry {
        if USE_MOCK {
            digest = MOCK_DIGEST;
            upcoming = [
                a
                for a in MOCK_APPOINTMENTS
                if a["status"] == "SCHEDULED"
            ];
            refills = [
                m
                for m in MOCK_MEDICATIONS
                if m["days_until_refill"] <= 7
            ];
            eligible = [
                b
                for b in MOCK_BENEFITS
                if b["is_eligible"]
            ];
            stats = {
                "appointments": len(upcoming),
                "refillsDue": len(refills),
                "openDisputes": 1,
                "benefitsFound": len(eligible)
            };
        } else {
            result = root spawn DigestGenerator();
            if result.reports and len(result.reports) > 0 {
                digest = result.reports[0];
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

    action_items = digest.get("action_items", []);
    urgent_items = action_items[:3];
    other_items = action_items[3:];
    today_str = new(Date).toLocaleDateString(
        "en-US", {"month": "long", "day": "numeric", "year": "numeric"}
    );

    return
        <div className="max-w-5xl mx-auto space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-warm-900">Weekly Summary</h1>
                <p className="text-warm-500 mt-1">Week of {today_str}</p>
            </div>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <StatCard
                    icon={Calendar}
                    label="Upcoming appointments"
                    value={stats["appointments"]}
                    color="bg-primary-500"
                />
                <StatCard
                    icon={Pill}
                    label="Refills due soon"
                    value={stats["refillsDue"]}
                    sublabel="within 7 days"
                    color="bg-yellow-500"
                />
                <StatCard
                    icon={AlertCircle}
                    label="Open disputes"
                    value={stats["openDisputes"]}
                    sublabel="billing errors"
                    color="bg-orange-500"
                />
                <StatCard
                    icon={TrendingUp}
                    label="Benefits found"
                    value={stats["benefitsFound"]}
                    sublabel="programs eligible"
                    color="bg-accent-500"
                />
            </div>
            {<div className="card border-l-4 border-l-primary-500">
                <h2 className="text-base font-semibold text-warm-900 mb-2">
                    What's happening this week
                </h2>
                <p className="text-warm-700 leading-relaxed">
                    {digest.get("executive_summary", "")}
                </p>
            </div>
                if digest.get("executive_summary")
                else <span></span>}
            <div>
                <h2
                    className="text-lg font-semibold text-warm-900 mb-3 flex items-center gap-2"
                >
                    <AlertCircle className="w-5 h-5 text-orange-500"/>
                    Action Items
                    {<span className="badge bg-orange-100 text-orange-700">
                        {len(action_items)}
                    </span>
                        if action_items
                        else <span></span>}
                </h2>
                <div className="space-y-2">
                    {[
                        <ActionItem
                            key={ai[0]}
                            text={ai[1]}
                            index={ai[0]}
                            urgent={ai[0] < 2}
                        /> for ai in enumerate(urgent_items)
                    ]}{[
                        <ActionItem key={ai[0] + 3} text={ai[1]} index={ai[0] + 3}/>
                        for ai in enumerate(other_items)
                    ]}
                </div>
            </div>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
                {<div className="card">
                    <h3
                        className="font-medium text-warm-900 mb-2 flex items-center gap-2"
                    >
                        <DollarSign className="w-4 h-4 text-primary-500"/>
                        Claims This Week
                    </h3>
                    <p className="text-sm text-warm-600 leading-relaxed">
                        {digest.get("claims_activity", "")}
                    </p>
                </div>
                    if digest.get("claims_activity")
                    else <span></span>}{<div className="card">
                    <h3
                        className="font-medium text-warm-900 mb-2 flex items-center gap-2"
                    >
                        <TrendingUp className="w-4 h-4 text-accent-500"/>
                        Financial Summary
                    </h3>
                    <p className="text-sm text-warm-600 leading-relaxed">
                        {digest.get("financial_summary", "")}
                    </p>
                </div>
                    if digest.get("financial_summary")
                    else <span></span>}
            </div>
        </div>;
}
