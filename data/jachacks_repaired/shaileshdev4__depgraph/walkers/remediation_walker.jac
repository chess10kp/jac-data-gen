"""Loop primitive — propose remediation for vulnerable packages."""

import from ..graph.nodes { Package, CVE }

def version_gte(candidate: str, minimum: str) -> bool {
    a_parts = str(candidate).split(".");
    b_parts = str(minimum).split(".");
    idx = 0;
    while idx < len(a_parts) and idx < len(b_parts) {
        a_num = 0;
        b_num = 0;
        try {
            a_num = int(a_parts[idx]);
        } except Exception {
            a_num = 0;
        }
        try {
            b_num = int(b_parts[idx]);
        } except Exception {
            b_num = 0;
        }
        if a_num > b_num {
            return True;
        }
        if a_num < b_num {
            return False;
        }
        idx += 1;
    }
    return len(a_parts) >= len(b_parts);
}

walker RemediationWalker {
    has max_attempts: int = 3;
    has plans: list[dict] = [];

    can remediate with Package entry {
        cve_nodes = [here-->][?:CVE];
        if not cve_nodes {
            disengage;
        }
        fixed = "";
        for cve_node in cve_nodes {
            if cve_node.fixed_version and not fixed {
                fixed = str(cve_node.fixed_version);
            }
        }
        if not fixed {
            disengage;
        }

        attempt = 0;
        chosen = fixed;
        breaking: list[str] = [];
        confidence = 0.9;
        status = "proposed";
        while attempt < self.max_attempts {
            attempt += 1;
            if version_gte(chosen, fixed) {
                status = "validated";
                confidence = 0.9;
                break;
            }
            chosen = fixed;
            confidence = 0.5;
            status = "proposed";
        }

        plan = {
            "event": "remediation_plan",
            "package": here.name,
            "from": here.version,
            "to": chosen,
            "breaking_changes": breaking,
            "confidence": confidence,
            "status": status
        };
        self.plans.append(plan);
        report plan;
        disengage;
    }
}
