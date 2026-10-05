"""Spawned when a critical CVE is found — transitive OSV follow-up."""

import from ..graph.nodes { Package, CVE }
import from ..tools.cve_lookup { lookup_package_cves }

walker DeepDiveWalker {
    has target_name: str;
    has target_version: str;
    has cve_id: str;
    has cvss_score: float = 0.0;
    has ecosystem: str = "npm";
    has max_visits: int = 10;
    has max_depth: int = 3;
    has visit_count: int = 0;
    has findings: list[dict] = [];
    has transitive_findings: list[dict] = [];
    has reported_start: bool = False;

    can analyze with Package entry {
        if here.depth > self.max_depth {
            disengage;
        }
        if self.visit_count >= self.max_visits {
            report {
                "event": "deep_dive_complete",
                "root_package": self.target_name,
                "root_version": self.target_version,
                "cve_id": self.cve_id,
                "packages_checked": self.visit_count,
                "findings": self.findings
            };
            disengage;
        }
        self.visit_count += 1;

        if not self.reported_start {
            self.reported_start = True;
            report {
                "event": "deep_dive",
                "package": self.target_name,
                "version": self.target_version,
                "cve_id": self.cve_id,
                "cvss_score": self.cvss_score,
                "depth": here.depth,
                "message": "Investigating transitive deps of critical finding"
            };
        }

        if here.name != self.target_name {
            cves = lookup_package_cves(here.name, here.version, self.ecosystem);
            max_cvss = 0.0;
            top_cve = "";
            for cve_data in cves {
                cve_node = CVE(
                    cve_id=cve_data["cve_id"],
                    cvss_score=cve_data["cvss_score"],
                    severity=cve_data["severity"],
                    description=cve_data["description"],
                    fixed_version=cve_data["fixed_version"]
                );
                here ++> cve_node;
                if cve_data["cvss_score"] > max_cvss {
                    max_cvss = cve_data["cvss_score"];
                    top_cve = str(cve_data["cve_id"]);
                }
            }
            if cves {
                self.findings.append(
                    {
                        "package": here.name,
                        "version": here.version,
                        "cve_count": len(cves),
                        "max_cvss": max_cvss,
                        "top_cve": top_cve,
                        "depth": here.depth
                    }
                );
                self.transitive_findings.append(
                    {
                        "package": here.name,
                        "version": here.version,
                        "cvss": max_cvss,
                        "cve_id": top_cve
                    }
                );
                report {
                    "event": "deep_dive_finding",
                    "package": here.name,
                    "version": here.version,
                    "cve_count": len(cves),
                    "max_cvss": max_cvss,
                    "top_cve": top_cve,
                    "depth": here.depth
                };
            }
        }

        visit [here ->:DependsOn:->][?:Package];
    }
}
