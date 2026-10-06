"""Sidebar navigation layout wrapping all pages."""

import from "react-router-dom" { NavLink, useLocation }
import from "lucide-react" {
    LayoutDashboard, Calendar, Pill, FileText, AlertCircle,
    DollarSign, Settings, Menu, X, Heart, ChevronRight
}

glob NAV_ITEMS: list = [
    {"to": "/",             "icon": LayoutDashboard, "label": "Dashboard"},
    {"to": "/appointments", "icon": Calendar,        "label": "Appointments"},
    {"to": "/medications",  "icon": Pill,            "label": "Medications"},
    {"to": "/documents",    "icon": FileText,        "label": "Documents"},
    {"to": "/claims",       "icon": AlertCircle,     "label": "Claims & Disputes"},
    {"to": "/finances",     "icon": DollarSign,      "label": "Finances"},
    {"to": "/settings",     "icon": Settings,        "label": "Settings"}
];

def NavItem(props: dict) -> JsxElement {
    item = props["item"];
    Icon = item["icon"];
    return <NavLink
        key={item["to"]}
        to={item["to"]}
        end={item["to"] == "/"}
        className={lambda (a: any) { f"flex items-center gap-3 px-3 py-2.5 rounded-xl mb-1 text-sm font-medium transition-all {'bg-white text-primary-600 shadow-sm' if a['isActive'] else 'text-primary-100 hover:bg-primary-400 hover:text-white'}" }}
        onClick={props["on_close"]}
    >
        <Icon className="w-4 h-4 flex-shrink-0" />
        {item["label"]}
    </NavLink>;
}

def:pub Layout(props: dict) -> JsxElement {
    has sidebar_open: bool = False;
    patient_name = props.get("patientName", "Margaret Johnson");

    location     = useLocation();
    current_page = (
        next((n["label"] for n in NAV_ITEMS if n["to"] == location.pathname), "AgeWise")
    );

    return <div className="flex h-screen bg-warm-100 overflow-hidden">

        {#* Sidebar *#}
        <aside className={f"fixed inset-y-0 left-0 z-40 w-64 bg-primary-500 flex flex-col transform transition-transform duration-200 lg:relative lg:translate-x-0 {'translate-x-0' if sidebar_open else '-translate-x-full'}"}>

            {#* Logo *#}
            <div className="flex items-center gap-3 px-6 py-5 border-b border-primary-400">
                <div className="w-9 h-9 bg-white rounded-xl flex items-center justify-center">
                    <Heart className="w-5 h-5 text-primary-500" />
                </div>
                <div>
                    <div className="text-white font-bold text-lg leading-tight">AgeWise</div>
                    <div className="text-primary-200 text-xs">Care Management</div>
                </div>
                <button className="ml-auto lg:hidden text-primary-200 hover:text-white"
                        onClick={lambda (e: MouseEvent) { sidebar_open = False; }}>
                    <X className="w-5 h-5" />
                </button>
            </div>

            {#* Patient info *#}
            <div className="px-6 py-4 bg-primary-600 border-b border-primary-400">
                <div className="text-primary-200 text-xs uppercase tracking-wide mb-1">Caring for</div>
                <div className="text-white font-semibold">{patient_name}</div>
            </div>

            {#* Nav *#}
            <nav className="flex-1 px-3 py-4 overflow-y-auto">
                {[<NavItem item={item} on_close={lambda (e: MouseEvent) { sidebar_open = False; }}/> for item in NAV_ITEMS]}
            </nav>

            <div className="px-6 py-4 border-t border-primary-400">
                <div className="text-primary-200 text-xs">AgeWise v0.1 · Hackathon Demo</div>
            </div>
        </aside>

        {#* Mobile overlay *#}
        {<div className="fixed inset-0 z-30 bg-black/30 lg:hidden"
              onClick={lambda (e: MouseEvent) { sidebar_open = False; }} /> if sidebar_open else <span></span>}

        {#* Main content *#}
        <div className="flex-1 flex flex-col overflow-hidden">
            <header className="bg-white border-b border-warm-200 px-6 py-4 flex items-center gap-4 flex-shrink-0">
                <button className="lg:hidden text-warm-600 hover:text-warm-900"
                        onClick={lambda (e: MouseEvent) { sidebar_open = True; }}>
                    <Menu className="w-5 h-5" />
                </button>
                <div className="flex items-center gap-2 text-warm-500 text-sm">
                    <span>AgeWise</span>
                    <ChevronRight className="w-3 h-3" />
                    <span className="text-warm-900 font-medium">{current_page}</span>
                </div>
            </header>
            <main className="flex-1 overflow-y-auto px-6 py-6">
                {props.get("children")}
            </main>
        </div>
    </div>;
}
