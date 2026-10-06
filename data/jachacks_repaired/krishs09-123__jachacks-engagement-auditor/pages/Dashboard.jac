import from "@jac/runtime" { Link as RuntimeLink }
import from ..hooks.useProjects { useProjects }
import from ..components.AppShell { AppShell }
import from ..components.ui.Button { Button }
import from ..components.ui.Card { Card, CardContent, CardDescription, CardHeader, CardTitle }
import from ..components.ui.Input { Input, Label }
import from ..components.ui.Badge { Badge }
import from ..components.ui.Table { Table, TableBody, TableCell, TableHead, TableHeader, TableRow }
import from ..components.ui.Dialog { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle }
import from ..components.ui.Alert { Alert }

obj ProjectCreateResult {
    has ok: bool = False;
    has message: str = "";
}

async def:pub DashboardPage() -> JsxElement {
    has showDialog: bool = False;
    has newName: str = "";
    has newUrl: str = "";
    has createMessage: str = "";
    projectState = await useProjects();

    async def handleCreate() -> None {
        createMessage = "";
        response: ProjectCreateResult | None = None;
        response = await projectState.createProject(newName, newUrl); # jac:ignore[E1001]
        if response is not None and response.ok {
            newName = "";
            newUrl = "";
            showDialog = False;
        } elif response is not None {
            createMessage = str(response.message);
        }
    }

    def handleOpenDialog() -> None {
        showDialog = True;
    }

    def handleCloseDialog() -> None {
        showDialog = False;
    }

    def handleNameChange(e: ChangeEvent) -> None {
        newName = e.target.value;
    }

    def handleUrlChange(e: ChangeEvent) -> None {
        newUrl = e.target.value;
    }

    return <AppShell>
        <header className="page-header">
            <div>
                <p className="eyebrow">Projects dashboard</p>
                <h1>Retention loop audits</h1>
                <p className="page-subtitle">Audit live products for behavioral reinforcement loops, visual evidence, and manipulative engagement risk.</p>
            </div>
            <Button onClick={handleOpenDialog}>New project</Button>
        </header>

        {projectState.error != "" and <Alert tone="danger">{projectState.error}</Alert>}

        <Card>
            <CardHeader>
                <CardTitle>Projects</CardTitle>
                <CardDescription>Each project and audit is stored under your private Jac graph root.</CardDescription>
            </CardHeader>
            <CardContent>
                {projectState.loading and <p className="empty-state">Loading projects...</p>}
                {not projectState.loading and len(projectState.projects) == 0 and <p className="empty-state">No projects yet.</p>}
                {not projectState.loading and len(projectState.projects) > 0 and <Table>
                    <TableHead>
                        <TableRow>
                            <TableHeader>Name</TableHeader>
                            <TableHeader>URL</TableHeader>
                            <TableHeader>Status</TableHeader>
                            <TableHeader>Action</TableHeader>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {[<TableRow key={project.uid}>
                            <TableCell><strong>{project.name}</strong></TableCell>
                            <TableCell><span className="mono-url">{project.live_url}</span></TableCell>
                            <TableCell><Badge tone={"success" if project.last_audit_id != "" else "neutral"}>{"audited" if project.last_audit_id != "" else "new"}</Badge></TableCell>
                            <TableCell><RuntimeLink className="table-link" to={"/projects/" + project.uid}>Open</RuntimeLink></TableCell>
                        </TableRow> for project in projectState.projects]}
                    </TableBody>
                </Table>}
            </CardContent>
        </Card>

        <Dialog open={showDialog}>
            <DialogHeader>
                <DialogTitle>New project</DialogTitle>
            </DialogHeader>
            <DialogContent>
                {createMessage != "" and <Alert tone="danger">{createMessage}</Alert>}
                <div className="stack">
                    <div>
                        <Label htmlFor="project-name">Project name</Label>
                        <Input id="project-name" value={newName} placeholder="e.g. HabitFit beta" onChange={handleNameChange} />
                    </div>
                    <div>
                        <Label htmlFor="project-url">Live consumer-app URL</Label>
                        <Input id="project-url" value={newUrl} placeholder="https://example.com" onChange={handleUrlChange} />
                    </div>
                    <DialogFooter>
                        <Button variant="ghost" onClick={handleCloseDialog}>Cancel</Button>
                        <Button onClick={handleCreate}>Create</Button>
                    </DialogFooter>
                </div>
            </DialogContent>
        </Dialog>
    </AppShell>;
}
