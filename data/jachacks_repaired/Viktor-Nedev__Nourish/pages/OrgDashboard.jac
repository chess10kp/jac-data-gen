import from "@jac/runtime" { Link, Navigate, jacIsLoggedIn }
import from "lucide-react" {
    Package, Users, Calendar, Brain, Bell,
    TrendingUp, AlertTriangle, Clock, CheckCircle, ArrowRight,
    Heart, MapPin, Plus, Zap
}
import from ..components.Navbar { Navbar }
import from ..components.Sidebar { Sidebar }
import from ..data.mockData { get_mock_donations, get_mock_requests, get_mock_org_stats, get_mock_ai_insights }

def:pub OrgDashboard() -> JsxElement {
    has stats: any = None;
    has donations: list[any] = [];
    has requests: list[any] = [];
    has insights: list[any] = [];

    if not jacIsLoggedIn() {
        return <Navigate to="/auth" replace={True} />;
    }

    async can with entry {
        stats = get_mock_org_stats();
        donations = get_mock_donations();
        requests = get_mock_requests();
        insights = get_mock_ai_insights();
    }

    meals: str = str(stats["meals_saved"]) if stats else "2,847";
    people: str = str(stats["people_helped"]) if stats else "1,203";
    active_don: str = str(stats["donations_active"]) if stats else "12";
    fulfilled: str = str(stats["requests_fulfilled"]) if stats else "89";
    food_kg: str = str(stats["food_rescued_kg"]) if stats else "4,200";
    avg_resp: str = str(stats["avg_response_time"]) if stats else "2.4 hrs";

    urgent_requests: list[any] = [r for r in requests if r["urgency"] == "critical" or r["urgency"] == "high"];

    return (
        <div className="min-h-screen bg-background page-enter">
            <Navbar role={"org"} />
            <div className="dashboard-layout">
                <Sidebar role={"org"} />
                <div className="dashboard-content">
                    <div className="page-header flex items-center justify-between anim-fade-in-down">
                        <div>
                            <h1 className="page-title gradient-text-red">{"Organization Dashboard"}</h1>
                            <p className="page-subtitle">{"Welcome back. Here's your impact overview."}</p>
                        </div>
                        <div className="flex gap-2">
                            <Link to="/donations/new" className="btn btn-primary btn-cinematic ripple-container flex items-center gap-2">
                                <Plus size={16} />
                                {"Add Donation"}
                            </Link>
                            <Link to="/events/new" className="btn flex items-center gap-2">
                                <Calendar size={16} />
                                {"Create Event"}
                            </Link>
                        </div>
                    </div>

                    {len(urgent_requests) > 0 and
                        <div className="alert-banner alert-banner-red mb-6">
                            <AlertTriangle size={18} className="flex-shrink-0 mt-0.5 anim-pulse-glow" />
                            <div>
                                <div className="font-semibold text-sm">{str(len(urgent_requests)) + " urgent requests need attention"}</div>
                                <div className="text-xs mt-0.5">{"Critical food needs in your area. Act now to make an impact."}</div>
                            </div>
                            <Link to="/requests" className="btn btn-sm ml-auto flex-shrink-0" style={{"background": "#991B1B", "color": "white", "borderColor": "#991B1B"}}>
                                {"View Requests"}
                            </Link>
                        </div>
                    }

                    <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
                        <div className="stat-card stat-cinematic anim-count-up delay-0">
                            <div className="flex items-center gap-2 mb-2">
                                <Heart size={16} className="text-primary" />
                                <span className="stat-label">{"Meals Saved"}</span>
                            </div>
                            <div className="stat-value text-primary">{meals}</div>
                            <div className="stat-change stat-change-up">{"↑ 12% this month"}</div>
                        </div>
                        <div className="stat-card stat-cinematic anim-count-up delay-100">
                            <div className="flex items-center gap-2 mb-2">
                                <Users size={16} className="text-blue-600" />
                                <span className="stat-label">{"People Helped"}</span>
                            </div>
                            <div className="stat-value">{people}</div>
                            <div className="stat-change stat-change-up">{"↑ 8% this month"}</div>
                        </div>
                        <div className="stat-card stat-cinematic anim-count-up delay-200">
                            <div className="flex items-center gap-2 mb-2">
                                <Package size={16} className="text-amber-600" />
                                <span className="stat-label">{"Active Donations"}</span>
                            </div>
                            <div className="stat-value">{active_don}</div>
                            <div className="stat-change">{"3 expiring soon"}</div>
                        </div>
                        <div className="stat-card stat-cinematic anim-count-up delay-300">
                            <div className="flex items-center gap-2 mb-2">
                                <CheckCircle size={16} className="text-green-600" />
                                <span className="stat-label">{"Fulfilled"}</span>
                            </div>
                            <div className="stat-value text-green-600">{fulfilled}</div>
                            <div className="stat-change stat-change-up">{"↑ 5 this week"}</div>
                        </div>
                        <div className="stat-card stat-cinematic anim-count-up delay-400">
                            <div className="flex items-center gap-2 mb-2">
                                <TrendingUp size={16} className="text-purple-600" />
                                <span className="stat-label">{"Food Rescued"}</span>
                            </div>
                            <div className="stat-value">{food_kg + "kg"}</div>
                            <div className="stat-change">{"This month"}</div>
                        </div>
                        <div className="stat-card stat-cinematic anim-count-up delay-500">
                            <div className="flex items-center gap-2 mb-2">
                                <Clock size={16} className="text-muted-foreground" />
                                <span className="stat-label">{"Avg Response"}</span>
                            </div>
                            <div className="stat-value text-sm font-bold">{avg_resp}</div>
                            <div className="stat-change stat-change-up">{"↓ 15min faster"}</div>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
                        <div className="lg:col-span-2 anim-fade-in-left delay-200">
                            <div className="card card-cinematic">
                                <div className="p-5 border-b border-border flex items-center justify-between">
                                    <h3 className="section-title mb-0">
                                        <Package size={16} className="text-amber-500" />
                                        {"Active Donations"}
                                    </h3>
                                    <Link to="/donations/feed" className="text-xs text-primary font-semibold hover:underline animated-underline">{"View all"}</Link>
                                </div>
                                <div className="divide-y divide-border">
                                    {[<div key={str(i)} className="p-4 flex items-center justify-between hover:bg-muted/50 transition-colors duration-200">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 bg-amber-50 rounded-lg flex items-center justify-center flex-shrink-0">
                                                <Package size={18} className="text-amber-500" />
                                            </div>
                                            <div>
                                                <div className="text-sm font-semibold text-foreground">{str(donations[i]["title"])}</div>
                                                <div className="text-xs text-muted-foreground">{str(donations[i]["quantity"]) + " · Expires " + str(donations[i]["expiry_date"])}</div>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-2">
                                            <span className={"badge " + ("badge-red" if donations[i]["status"] == "expiring_soon" else "badge-green")}>
                                                {str(donations[i]["status"])}
                                            </span>
                                            <Link to={"/donations/" + str(donations[i]["id"])} className="btn btn-ghost btn-sm">
                                                <ArrowRight size={14} />
                                            </Link>
                                        </div>
                                    </div>
                                    for i in range(min(4, len(donations)))]}
                                </div>
                            </div>
                        </div>

                        <div className="anim-fade-in-right delay-300">
                            <div className="card card-cinematic glow-border-red">
                                <div className="p-5 border-b border-border">
                                    <h3 className="section-title mb-0">
                                        <Brain size={16} className="text-purple-500" />
                                        {"AI Recommendations"}
                                    </h3>
                                </div>
                                <div className="p-4 flex flex-col gap-3">
                                    {[<div key={str(i)} className={"p-3 rounded-lg border card-cinematic " + ("border-red-200 bg-red-50" if insights[i]["priority"] == "critical" else ("border-amber-200 bg-amber-50" if insights[i]["priority"] == "high" else "border-border bg-muted/30"))}>
                                        <div className="text-xs font-bold text-foreground mb-1">{str(insights[i]["title"])}</div>
                                        <div className="text-xs text-muted-foreground mb-2">{str(insights[i]["description"])}</div>
                                        <Link to="/ai/insights" className="text-xs text-primary font-semibold animated-underline">{str(insights[i]["action"]) + " →"}</Link>
                                    </div>
                                    for i in range(min(3, len(insights)))]}
                                    <Link to="/ai/insights" className="btn btn-outline btn-sm w-full btn-cinematic">
                                        {"View All Insights"}
                                    </Link>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <div className="card card-cinematic anim-fade-in-up delay-400">
                            <div className="p-5 border-b border-border flex items-center justify-between">
                                <h3 className="section-title mb-0">
                                    <Users size={16} className="text-red-500" />
                                    {"Urgent Requests Nearby"}
                                </h3>
                                <Link to="/requests" className="text-xs text-primary font-semibold animated-underline">{"View all"}</Link>
                            </div>
                            <div className="divide-y divide-border">
                                {len(urgent_requests) == 0 and
                                    <div className="p-8 text-center text-sm text-muted-foreground">{"No urgent requests right now"}</div>
                                }
                                {[<div key={str(i)} className="p-4 flex items-start justify-between gap-3 hover:bg-muted/50 transition-colors">
                                    <div>
                                        <div className="text-sm font-semibold text-foreground">{str(urgent_requests[i]["title"])}</div>
                                        <div className="text-xs text-muted-foreground mt-0.5">{str(urgent_requests[i]["people_count"]) + " people · " + str(urgent_requests[i]["location_text"])}</div>
                                    </div>
                                    <span className={"urgency-" + str(urgent_requests[i]["urgency"])}>{str(urgent_requests[i]["urgency"])}</span>
                                </div>
                                for i in range(min(4, len(urgent_requests)))]}
                            </div>
                        </div>

                        <div className="card card-cinematic anim-fade-in-up delay-500">
                            <div className="p-5 border-b border-border">
                                <h3 className="section-title mb-0">
                                    <Zap size={16} className="text-amber-500" />
                                    {"Quick Actions"}
                                </h3>
                            </div>
                            <div className="p-5 grid grid-cols-2 gap-3">
                                <Link to="/donations/new" className="card card-p flex flex-col items-center gap-2 text-center card-cinematic hover:border-amber-300 hover:bg-amber-50 cursor-pointer">
                                    <Package size={24} className="text-amber-500" />
                                    <span className="text-sm font-semibold text-foreground">{"Post Donation"}</span>
                                </Link>
                                <Link to="/events/new" className="card card-p flex flex-col items-center gap-2 text-center card-cinematic hover:border-blue-300 hover:bg-blue-50 cursor-pointer">
                                    <Calendar size={24} className="text-blue-500" />
                                    <span className="text-sm font-semibold text-foreground">{"Create Event"}</span>
                                </Link>
                                <Link to="/ai/insights" className="card card-p flex flex-col items-center gap-2 text-center card-cinematic hover:border-purple-300 hover:bg-purple-50 cursor-pointer">
                                    <Brain size={24} className="text-purple-500" />
                                    <span className="text-sm font-semibold text-foreground">{"AI Insights"}</span>
                                </Link>
                                <Link to="/map" className="card card-p flex flex-col items-center gap-2 text-center card-cinematic hover:border-green-300 hover:bg-green-50 cursor-pointer">
                                    <MapPin size={24} className="text-green-500" />
                                    <span className="text-sm font-semibold text-foreground">{"View Map"}</span>
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
