import from "@jac/runtime" {
    Link as RuntimeLink,
    useNavigate as runtimeUseNavigate,
    useParams as runtimeUseParams,
}
import from ..services.audits { start_audit }
import from ..services.models { AuditMutationResult, Project }
import from ..hooks.useProjects { useProjects }
import from ..components.AppShell { AppShell }
import from ..components.ui.Button { Button }
import from ..components.ui.Card { Card, CardContent, CardDescription, CardHeader, CardTitle }
import from ..components.ui.Input { Input, Label }
import from ..components.ui.Badge { Badge }
import from ..components.ui.Alert { Alert }

def findProject(projects: list[Project], project_id: str) -> Project | None {
    for project in projects {
        if project.uid == project_id {
            return project;
        }
    }
    return None;
}

async def:pub ProjectDetailPage() -> JsxElement {
    has auditUrl: str = "";
    has running: bool = False;
    has startError: str = "";
    params = runtimeUseParams();
    project_id: str = str(params["id"]);
    navigate = runtimeUseNavigate();
    projectState = await useProjects();
    project: Project | None = findProject(projectState.projects, project_id);
    project_name: str = "Project";
    project_url: str = "Loading project...";
    latest_audit_id: str = "";
    if project is not None {
        project_name = project.name;
        project_url = project.live_url;
        latest_audit_id = project.last_audit_id;
    }

    async def handleStartAudit() -> None {
        if project is None {
            return;
        }
        running = True;
        startError = "";
        response: AuditMutationResult | None = None;
        try {
            response = await start_audit(project.uid, auditUrl);
        } except Exception as e {
            startError = "Could not start audit: " + str(e);
        }
        running = False;
        if response is not None and response.ok and response.run is not None {
            run_uid: str = response.run.uid;
            navigate("/audits/" + run_uid);
        } elif response is not None {
            startError = response.message;
        }
    }

    def handleAuditUrlChange(e: ChangeEvent) -> None {
        auditUrl = e.target.value;
    }

    return <AppShell>
        <header className="page-header">
            <div>
                <p className="eyebrow">Project detail</p>
                <h1>{project_name}</h1>
                <p className="page-subtitle">{project_url}</p>
            </div>
            <RuntimeLink className="table-link" to="/projects">Back to projects</RuntimeLink>
        </header>

        {projectState.error != "" and <Alert tone="danger">{projectState.error}</Alert>}
        {startError != "" and <Alert tone="danger">{startError}</Alert>}

        {project is None and not projectState.loading and <Alert tone="danger">Project not found for this account.</Alert>}
        {project is not None and <div className="two-column">
            <Card>
                <CardHeader>
                    <CardTitle>Start audit</CardTitle>  
                    <CardDescription>Crawler budget is capped and unsafe URLs are rejected before fetching.</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="stack">
                        <div>
                            <Label htmlFor="audit-url">URL to audit</Label>
                            <Input id="audit-url" value={auditUrl} placeholder={project_url} onChange={handleAuditUrlChange} />
                            <p className="helper-text">Leave blank to use the project URL.</p>
                        </div>
                        <Button onClick={handleStartAudit} disabled={running}>{"Auditing..." if running else "Start audit"}</Button>
                    </div>
                </CardContent>
            </Card>

            <Card>
                <CardHeader>
                    <CardTitle>Latest run</CardTitle>
                    <CardDescription>Latest retention-loop audit with screenshot and click-through evidence.</CardDescription>
                </CardHeader>
                <CardContent>
                    {latest_audit_id == "" and <p className="empty-state">No completed audit yet.</p>}
                    {latest_audit_id != "" and <div className="stack">
                        <Badge tone="success">audit available</Badge>
                        <p className="mono-url">{latest_audit_id}</p>
                        <RuntimeLink className="table-link" to={"/audits/" + latest_audit_id}>Open latest audit</RuntimeLink>
                    </div>}
                </CardContent>
            </Card>
        </div>}
    </AppShell>;
}
