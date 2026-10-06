import from "@jac/runtime" { Link, useParams }
import from .GraphStateProvider { useGraphState }
import from .AmbientBackground { AmbientBackground }

def _pick(d: object, key: str, fallback: str) -> str {
    if not d {
        return fallback;
    }
    if key in d {
        v = d[key];
        if v {
            return str(v);
        }
    }
    return fallback;
}

def _pre_str(d: object, key: str) -> str {
    if not d or not (key in d) {
        return "";
    }
    return str(d[key]);
}

def:pub SecurityIncidentPage() -> JsxElement {
    params = useParams();
    incident_id = "";
    if params and ("incident_id" in params) {
        incident_id = str(params["incident_id"]);
    }
    gs: any = useGraphState();
    graphPayload: any = None;
    if gs and ("report" in gs) {
        graphPayload = gs["report"];
    }
    loading: any = True;
    if gs and ("loading" in gs) {
        loading = gs["loading"];
    }
    err: any = None;
    if gs and ("error" in gs) {
        err = gs["error"];
    }
    latest: any = None;
    if graphPayload and ("latest_incident" in graphPayload) {
        latest = graphPayload["latest_incident"];
    }
    lid = "";
    if latest and ("id" in latest) {
        lid = str(latest["id"]);
    }
    incidentMatches = False;
    if latest and lid == incident_id {
        incidentMatches = True;
    }
    fixUrl = "";
    if latest {
        fixUrl = _pre_str(latest, "fix_pr_url");
    }

    return
        <div className="gw-page">
            <AmbientBackground screen="app"/>
            <div className="gw-page-inner gw-page-inner--app">
                <div
                    className="gw-repo-connect gw-glass-panel gw-fade-up gw-stagger-2"
                    style={{"maxWidth": "720px", "margin": "48px auto"}}
                >
                    <h1 className="gw-repo-connect-title">Security Incident</h1>
                    {loading and <p className="gw-repo-connect-lede">Loading…</p>}
                    {not loading
                        and err
                        and <p className="gw-repo-connect-lede">
                            Graph state unavailable.
                        </p>}
                    {not loading
                        and not err
                        and not incidentMatches
                        and <p className="gw-repo-connect-lede">
                            No matching incident in the current snapshot.
                        </p>}
                    {not loading
                        and not err
                        and incidentMatches
                        and latest
                        and <div
                            className="gw-settings-column"
                            style={{"textAlign": "left", "gap": "16px"}}
                        >
                            <p>
                                <strong>Status</strong>{" "}
                                {_pick(latest, "status", "—")}
                            </p>
                            <p>
                                <strong>Risk</strong>{" "}
                                {_pick(latest, "risk_level", "—")}
                            </p>
                            <p>
                                <strong>Repository</strong>{" "}
                                {_pick(latest, "repo_full_name", "—")}
                            </p>
                            <p>
                                <strong>Commit</strong>{" "}
                                {_pick(latest, "commit_sha", "—")}
                            </p>
                            <p>
                                <strong>Dependency</strong>{" "}
                                {_pick(latest, "dependency_name", "—")}{" "}
                                {_pick(latest, "dependency_version", "")}
                            </p>
                            <p>
                                <strong>Manifest</strong>{" "}
                                {_pick(latest, "manifest_path", "—")}
                            </p>
                            <p><strong>Fix PR</strong> {fixUrl}</p>
                            <pre
                                className="gw-repo-connect-code"
                                style={{"whiteSpace": "pre-wrap", "fontSize": "12px"}}
                            >
                                {_pre_str(latest, "rule_codes")}
                            </pre>
                            <pre
                                className="gw-repo-connect-code"
                                style={{"whiteSpace": "pre-wrap", "fontSize": "11px"}}
                            >
                                {_pre_str(latest, "sandbox_result")}
                            </pre>
                            <pre
                                className="gw-repo-connect-code"
                                style={{"whiteSpace": "pre-wrap", "fontSize": "11px"}}
                            >
                                {_pre_str(latest, "behavioral_trace")}
                            </pre>
                        </div>}
                    <p style={{"marginTop": "24px"}}>
                        <Link to="/start" className="gw-role-back">Back</Link>
                    </p>
                </div>
            </div>
        </div>;
}
