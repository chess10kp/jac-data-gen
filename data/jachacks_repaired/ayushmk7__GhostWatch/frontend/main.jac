import requests;
import from os { environ }

def backend_base_url() -> str {
    return str(environ.get("GHOSTWATCH_BACKEND_URL", "http://localhost:8080")).rstrip(
        "/"
    );
}

walker:pub GraphStateProxy {
    can fetch with Root entry {
        resp: any = requests.post(
            backend_base_url() + "/walker/GraphStateWalker",
            json={"latest_pr": None, "latest_incident": None, "latest_gap": None}
        );
        body: any = resp.json();
        inner: any = body.get("data", {}).get("reports", []);
        if len(inner) > 0 {
            report inner[0];
        }
    }
}

walker:pub OrchestratorProxy {
    has pr_url: str;

    can run with Root entry {
        resp: any = requests.post(
            backend_base_url() + "/walker/OrchestratorWalker",
            json={"pr_url": self.pr_url}
        );
        body: any = resp.json();
        inner: any = body.get("data", {}).get("reports", []);
        if len(inner) > 0 {
            report inner[0];
        }
    }
}

import from "@jac/runtime" { Router, Routes, Route, Navigate }
import from .theme { APP_STYLES }
import from .pages.index { page as IndexPage }
import from .pages.start { page as StartPage }
import from .pages.gaps { page as GapsPage }
import from .components.AppShell { AppShell }
import from .components.GraphStateProvider { GraphStateProvider }
import from .components.SecurityIncidentPage { SecurityIncidentPage }


def:pub app() -> JsxElement {
    return
        <Router>
            <GraphStateProvider>
                <div className="gw-root">
                    <style>{APP_STYLES}</style>
                    <Routes>
                        <Route path="/" element={<IndexPage/>}></Route>
                        <Route
                            path="/auth"
                            element={<Navigate to="/start" replace={True}/>}
                        ></Route>
                        <Route path="/start" element={<StartPage/>}></Route>
                        <Route
                            path="/app/maintainer"
                            element={<AppShell mode="maintainer"/>}
                        ></Route>
                        <Route
                            path="/app/contributor"
                            element={<AppShell mode="contributor"/>}
                        ></Route>
                        <Route
                            path="/app"
                            element={<Navigate to="/start" replace={True}/>}
                        ></Route>
                        <Route
                            path="/security/:incident_id"
                            element={<SecurityIncidentPage/>}
                        ></Route>
                        <Route path="/gaps" element={<GapsPage/>}></Route>
                        <Route path="*" element={<Navigate to="/"/>}></Route>
                    </Routes>
                </div>
            </GraphStateProvider>
        </Router>;
}
