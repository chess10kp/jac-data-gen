with entry {
    print("GhostNet Jac Graph Engine v2.0");
    print("Nodes: Zone, Hospital, RescueTeam, Shelter, Incident");
    print("Walkers: BuildGraph, QueryGraph, AddIncident, ResolveIncident, GraphStats");
}

node Zone {
    has id: str = "";
    has name: str = "";
    has flood_severity: float = 0.0;
    has status: str = "monitoring";
}

node Hospital {
    has id: str = "";
    has name: str = "";
    has zone_id: str = "";
    has capacity: int = 100;
    has occupied: int = 0;
    has status: str = "available";
}

node RescueTeam {
    has id: str = "";
    has name: str = "";
    has status: str = "available";
    has assigned_to: str = "";
    has zone_id: str = "";
}

node Shelter {
    has id: str = "";
    has name: str = "";
    has zone_id: str = "";
    has capacity: int = 200;
    has occupied: int = 0;
    has status: str = "available";
}

node Incident {
    has id: str = "";
    has `report: str = "";
    has severity: int = 0;
    has zone_id: str = "";
    has zone_name: str = "";
    has lat: float = 13.0950;
    has lng: float = 80.2900;
    has status: str = "active";
    has source: str = "operator";
    has timestamp: str = "";
}

node GhostNetRoot {
    has version: str = "2.0.0";
    has total_incidents: int = 0;
}

edge Located {}
edge Assigned {}
edge Serves {}
edge Affects {}

walker BuildGraph {
    has node_count: int = 0;

    can build with GhostNetRoot entry {
        self.node_count += 1;
        report self.node_count;
    }
}

walker QueryGraph {
    can query with GhostNetRoot entry {
        report {"status": "active", "engine": "Jac Graph v2.0"};
    }
}

walker AddIncident {
    has incident_id: str = "";
    has severity: int = 0;

    can add with GhostNetRoot entry {
        inc = Incident(id=self.incident_id, severity=self.severity);
        here ++> inc;
        report self.incident_id;
    }
}

walker ResolveIncident {
    has incident_id: str = "";

    can resolve with GhostNetRoot entry {
        report [];
    }
}

walker GraphStats {
    can get_stats with GhostNetRoot entry {
        report {
            "total_nodes": 1,
            "engine": "Jac Graph v2.0",
            "status": "active"
        };
    }
}