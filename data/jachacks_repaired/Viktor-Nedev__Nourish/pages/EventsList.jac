import from "@jac/runtime" { Link, jacIsLoggedIn }
import from "lucide-react" { Calendar, MapPin, Users, Clock, Plus }
import from ..components.Navbar { Navbar }
import from ..data.mockData { get_mock_events }

def:pub EventsList() -> JsxElement {
    has events: list[any] = [];

    async can with entry {
        events = get_mock_events();
    }

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-7xl mx-auto px-6 py-8">
                <div className="flex items-center justify-between mb-6">
                    <div>
                        <h1 className="page-title">{"Community Events"}</h1>
                        <p className="page-subtitle">{"Food distribution events and community gatherings"}</p>
                    </div>
                    {jacIsLoggedIn() and
                        <Link to="/events/new" className="btn btn-primary flex items-center gap-2">
                            <Plus size={16} />
                            {"Create Event"}
                        </Link>
                    }
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                    {[<div key={events[i]["id"]} className="event-card">
                        <div className="h-32 bg-gradient-to-br from-blue-50 to-blue-100 rounded-t-xl flex items-center justify-center">
                            <Calendar size={40} className="text-blue-400" />
                        </div>
                        <div className="p-5">
                            <div className="flex items-start justify-between gap-2 mb-2">
                                <h3 className="text-base font-bold text-foreground">{events[i]["title"]}</h3>
                                <span className="badge badge-blue">{"Upcoming"}</span>
                            </div>
                            <p className="text-sm text-muted-foreground mb-3">{events[i]["description"]}</p>
                            <div className="flex flex-col gap-1.5 mb-4">
                                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Clock size={12} />
                                    {events[i]["event_date"] + " · " + events[i]["event_time"]}
                                </div>
                                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <MapPin size={12} />
                                    {events[i]["address"]}
                                </div>
                                <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Users size={12} />
                                    {str(events[i]["registered"]) + " / " + str(events[i]["capacity"]) + " registered"}
                                </div>
                            </div>
                            <div className="mb-3">
                                <div className="progress-bar">
                                    <div className="progress-fill" style={{"width": str(int(events[i]["registered"] / events[i]["capacity"] * 100)) + "%", "background": "#2563EB"}} />
                                </div>
                            </div>
                            <div className="text-xs text-muted-foreground mb-3">{"By " + events[i]["organizer"]}</div>
                            <div className="flex gap-2">
                                <Link to={"/events/" + events[i]["id"]} className="btn btn-primary btn-sm flex-1 text-center">{"View Details"}</Link>
                                <Link to="/map" className="btn btn-sm flex items-center gap-1">
                                    <MapPin size={12} />
                                    {"Map"}
                                </Link>
                            </div>
                        </div>
                    </div>
                    for i in range(len(events))]}
                </div>
            </div>
        </div>
    );
}
