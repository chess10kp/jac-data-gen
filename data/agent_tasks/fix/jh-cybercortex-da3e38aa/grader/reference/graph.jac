node SecurityTarget {
    has ip_address: str;
    has status: str = "pending";
    has vulnerabilities: list = [];
}

node ThreatIntel {
    has threat_level: str = "unknown";
    has active_threats: list = [];
}

edge Analyzes {}
edge Monitors {}

obj CyberGraph {
    has start_node: SecurityTarget = SecurityTarget(ip_address="192.168.1.100");

    def init {
        intel = ThreatIntel(threat_level="high", active_threats=["CVE-2024-1234"]);

        self.start_node ++> intel;
    }
}
