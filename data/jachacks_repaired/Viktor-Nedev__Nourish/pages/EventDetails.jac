import from "@jac/runtime" { Link, useParams }
import from "lucide-react" { Calendar, MapPin, Users, Clock, ArrowLeft }
import from ..components.Navbar { Navbar }
import from ..data.mockData { get_mock_events }

def:pub EventDetails() -> JsxElement {
    has event: any = None;
    has events: list[any] = [];

    params: any = useParams();

    async can with entry {
        events = get_mock_events();
        eid: str = str(params["id"]) if params["id"] else "";
        for ev in events {
            if ev["id"] == eid {
                event = ev;
                break;
            }
        }
    }

    if event is None {
        return (
            <div className="min-h-screen bg-background">
                <Navbar role={"user"} />
                <div className="max-w-2xl mx-auto px-6 py-16 text-center">
                    <h1 className="text-xl font-bold text-foreground mb-2">{"Event not found"}</h1>
                    <Link to="/events" className="btn btn-primary mt-4">{"Browse Events"}</Link>
                </div>
            </div>
        );
    }

    title: str = str(event["title"]) if event else "";
    desc: str = str(event["description"]) if event else "";
    org: str = str(event["organizer"]) if event else "";
    date: str = str(event["event_date"]) if event else "";
    time: str = str(event["event_time"]) if event else "";
    addr: str = str(event["address"]) if event else "";
    food: str = str(event["food_type"]) if event else "";
    cap: str = str(event["capacity"]) if event else "";
    reg: str = str(event["registered"]) if event else "";

    return (
        <div className="min-h-screen bg-background">
            <Navbar role={"user"} />
            <div className="max-w-3xl mx-auto px-6 py-8">
                <Link to="/events" className="btn btn-ghost btn-sm flex items-center gap-1 mb-6 w-fit">
                    <ArrowLeft size={14} />
                    {"Back to Events"}
                </Link>
                <div className="card overflow-hidden">
                    <div className="h-48 bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center">
                        <Calendar size={64} className="text-blue-300" />
                    </div>
                    <div className="p-6">
                        <div className="flex items-start justify-between gap-3 mb-4">
                            <h1 className="text-2xl font-bold text-foreground">{title}</h1>
                            <span className="badge badge-blue">{"Upcoming"}</span>
                        </div>
                        <p className="text-muted-foreground mb-5">{desc}</p>
                        <div className="flex flex-col gap-2 mb-5">
                            <div className="flex items-center gap-2 text-sm"><Clock size={14} className="text-muted-foreground" />{date + " · " + time}</div>
                            <div className="flex items-center gap-2 text-sm"><MapPin size={14} className="text-muted-foreground" />{addr}</div>
                            <div className="flex items-center gap-2 text-sm"><Users size={14} className="text-muted-foreground" />{reg + " / " + cap + " registered"}</div>
                            <div className="flex items-center gap-2 text-sm"><Calendar size={14} className="text-muted-foreground" />{"By " + org}</div>
                        </div>
                        <div className="mb-5">
                            <div className="progress-bar">
                                <div className="progress-fill" style={{"background": "#2563EB", "width": "60%"}} />
                            </div>
                            <div className="text-xs text-muted-foreground mt-1">{reg + " of " + cap + " spots filled"}</div>
                        </div>
                        <button className="btn btn-primary w-full">{"Register for Event"}</button>
                    </div>
                </div>
            </div>
        </div>
    );
}
