import json;

node ComputeNode {
    has name: str;
}

node DatabaseNode {
    has name: str;
}

node SecurityGroupNode {
    has name: str;
    has open_ports: list[int] = [];
    has is_compromised: bool = False;
}

node SandboxRoot {
}

edge DependencyEdge: ComputeNode --> DatabaseNode {
    has criticality: int;
    has financial_exposure: int;
}

edge NetworkRouteEdge: ComputeNode --> SecurityGroupNode {
}

# Walker to initialize the graph from the mock JSON file
walker InitGraph {
    can init with Root entry {
        # Load JSON data (mock_cloud_state.json) located in the same directory
        raw = open("mock_cloud_state.json").read();
        data = json.loads(raw);
        # Expect data to be an array of objects with type and name
        for item in data {
            if item["type"] == "ComputeNode" {
                cn = here ++> ComputeNode(name=item["name"] as str);
            } elif item["type"] == "DatabaseNode" {
                db = here ++> DatabaseNode(name=item["name"] as str);
            } elif item["type"] == "SecurityGroupNode" {
                sg = here ++> SecurityGroupNode(
                    name=item["name"] as str,
                    open_ports=item["open_ports"] as list[int]
                );
            }
        }
        # Manually create a few edges for the prototype
        # Assume we have one compute node "PaymentGateway" and one DB "LedgerDB"
        compute = here ++> ComputeNode(name="PaymentGateway");
        db = here ++> DatabaseNode(name="LedgerDB");
        sg = here ++> SecurityGroupNode(name="PublicFacingGroup", open_ports=[22, 443]);
        # Dependency from compute to DB
        compute +>:DependencyEdge(criticality=9, financial_exposure=1000000):+> db;
        # Network route from compute to security group
        compute +>:NetworkRouteEdge:+> sg;
        print("[INIT] Graph initialized with mock cloud state");
    }
}
