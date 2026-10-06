"""Settings page — notifications, connected accounts, family access."""

import  from "lucide-react" { Bell, Link, Users }

glob NOTIFICATION_ITEMS: list = [
    ["Weekly digest email", True],
    ["Appointment reminders (3 days before)", True],
    ["Medication refill reminders", True],
    ["New billing dispute detected", True],
    ["Scam/fraud alerts", True]
];

glob CONNECTED_ACCOUNTS: list = [
    ["Medicare Blue Button", "Connected", "text-accent-600"],
    ["Plaid (Bank Accounts)", "Connected", "text-accent-600"],
    ["Email (IMAP)", "Connected", "text-accent-600"],
    ["MyChart Health Portal", "Not connected", "text-warm-400"]
];

def:pub Settings() -> JsxElement {
    return <div className="max-w-2xl mx-auto space-y-6">
        <h1>Settings</h1>

        {#* Notifications *#}
        <div className="card space-y-4">
            <div className="flex items-center gap-3 pb-3 border-b border-warm-100">
                <Bell className="w-5 h-5 text-primary-500" />
                <h2 className="text-base">Notifications</h2>
            </div>
            {[<div key={label} className="flex items-center justify-between py-1">
                <span className="text-warm-700">{label}</span>
                <div className={f"w-10 h-6 rounded-full flex items-center px-1 {'bg-primary-500' if enabled else 'bg-warm-300'}"}>
                    <div className={f"w-4 h-4 bg-white rounded-full shadow transition-transform {'translate-x-4' if enabled else ''}"} />
                </div>
            </div> for (label, enabled) in NOTIFICATION_ITEMS]}
        </div>

        {#* Connected accounts *#}
        <div className="card space-y-4">
            <div className="flex items-center gap-3 pb-3 border-b border-warm-100">
                <Link className="w-5 h-5 text-primary-500" />
                <h2 className="text-base">Connected Accounts</h2>
            </div>
            {[<div key={service} className="flex items-center justify-between py-1">
                <span className="text-warm-700">{service}</span>
                <span className={f"text-sm font-medium {color}"}>{status}</span>
            </div> for (service, status, color) in CONNECTED_ACCOUNTS]}
        </div>

        {#* Family access *#}
        <div className="card space-y-4">
            <div className="flex items-center gap-3 pb-3 border-b border-warm-100">
                <Users className="w-5 h-5 text-primary-500" />
                <h2 className="text-base">Family Access</h2>
            </div>
            <div className="flex items-center justify-between py-1">
                <div>
                    <div className="text-warm-900 font-medium">Robert Johnson</div>
                    <div className="text-sm text-warm-500">robert.johnson@example.com · Adult Child</div>
                </div>
                <span className="badge bg-primary-100 text-primary-700">Full Access</span>
            </div>
            <button className="btn-ghost text-sm w-full">+ Add family member</button>
        </div>
    </div>;
}
