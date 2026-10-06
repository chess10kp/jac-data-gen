import from "@jac/runtime" {
    Link as RuntimeLink,
    useNavigate as runtimeUseNavigate,
    useParams as runtimeUseParams,
}
import from ..services.models { AuditRunView, ExportReport, PageSnapshot, VisualSnapshot, InteractionStep }
import from ..hooks.useAuditRun { useAuditRun }
import from ..components.AppShell { AppShell }
import from ..components.ui.Button { Button }
import from ..components.ui.Card { Card, CardContent, CardDescription, CardHeader, CardTitle }
import from ..components.ui.Progress { Progress }
import from ..components.ui.Badge { Badge }
import from ..components.ui.Table { Table, TableBody, TableCell, TableHead, TableHeader, TableRow }
import from ..components.ui.Tabs { Tabs, TabButton, TabList }
import from ..components.ui.Dialog { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle }
import from ..components.ui.Alert { Alert }

async def:pub AuditDetailPage() -> JsxElement {
    has showExport: bool = False;
    has exported: ExportReport | None = None;
    params = runtimeUseParams();
    audit_id: str = str(params["id"]);
    navigate = runtimeUseNavigate();
    auditState = await useAuditRun(audit_id);
    view: AuditRunView | None = auditState.view;
    project_name: str = "Audit run";
    target_url: str = "Loading...";
    has_run: bool = False;
    retention_score: int = 0;
    visual_score: int = 0;
    interaction_score: int = 0;
    onboarding_activation_score: int = 0;
    habit_loop_strength_score: int = 0;
    reward_design_feedback_score: int = 0;
    social_retention_mechanics_score: int = 0;
    attention_capture_session_depth_score: int = 0;
    personalization_adaptation_score: int = 0;
    friction_reduction_score: int = 0;
    progression_investment_score: int = 0;
    reentry_notification_systems_score: int = 0;
    trust_emotional_safety_score: int = 0;
    dark_pattern_risk_score: int = 0;
    run_status: str = "";
    completed_at: str = "";
    crawl_summary: str = "";
    visual_summary: str = "";
    legal_filter_summary: str = "";
    export_markdown: str = "";
    snapshots_count: int = 0;
    visual_count: int = 0;
    interaction_count: int = 0;
    recommendations_count: int = 0;
    snapshots: list[PageSnapshot] = [];
    visual_snapshots: list[VisualSnapshot] = [];
    interaction_steps: list[InteractionStep] = [];
    rubric_strengths: list[str] = [];
    rubric_weaknesses: list[str] = [];
    rubric_risks: list[str] = [];
    rubric_improvements: list[str] = [];
    dark_pattern_risk_reasons: list[str] = [];
    if view is not None and view.project is not None {
        project_name = view.project.name;
    }
    if view is not None and view.run is not None {
        has_run = True;
        target_url = view.run.target_url;
        retention_score = view.run.retention_score;
        visual_score = view.run.visual_score;
        interaction_score = view.run.interaction_score;
        onboarding_activation_score = view.run.onboarding_activation_score;
        habit_loop_strength_score = view.run.habit_loop_strength_score;
        reward_design_feedback_score = view.run.reward_design_feedback_score;
        social_retention_mechanics_score = view.run.social_retention_mechanics_score;
        attention_capture_session_depth_score = view.run.attention_capture_session_depth_score;
        personalization_adaptation_score = view.run.personalization_adaptation_score;
        friction_reduction_score = view.run.friction_reduction_score;
        progression_investment_score = view.run.progression_investment_score;
        reentry_notification_systems_score = view.run.reentry_notification_systems_score;
        trust_emotional_safety_score = view.run.trust_emotional_safety_score;
        dark_pattern_risk_score = view.run.dark_pattern_risk_score;
        rubric_strengths = view.run.rubric_strengths;
        rubric_weaknesses = view.run.rubric_weaknesses;
        rubric_risks = view.run.rubric_retention_risks;
        rubric_improvements = view.run.rubric_highest_leverage_improvements;
        dark_pattern_risk_reasons = view.run.dark_pattern_risk_reasons;
        run_status = view.run.status;
        completed_at = view.run.completed_at;
        crawl_summary = view.run.crawl_summary;
        visual_summary = view.run.visual_summary;
        legal_filter_summary = view.run.legal_filter_summary;
    }
    if view is not None {
        snapshots = view.snapshots;
        visual_snapshots = view.visual_snapshots;
        interaction_steps = view.interaction_steps;
        snapshots_count = len(view.snapshots);
        visual_count = len(view.visual_snapshots);
        interaction_count = len(view.interaction_steps);
        recommendations_count = len(view.recommendations);
    }
    if auditState.exported is not None {
        export_markdown = auditState.exported.markdown;
    } elif exported is not None {
        export_markdown = exported.markdown;
    }

    async def handleExport() -> None {
        export_result: ExportReport | None = None;
        export_result = await auditState.exportReport(); # jac:ignore[E1001]
        exported = export_result;
        if export_result is not None and export_result.ok {
            showExport = True;
        }
    }

    def goOverview() -> None {
        navigate("/audits/" + audit_id);
    }

    def goRetention() -> None {
        navigate("/audits/" + audit_id + "/retention");
    }

    def closeExport() -> None {
        showExport = False;
    }

    return <AppShell auditId={audit_id}>
        <header className="page-header">
            <div>
                <p className="eyebrow">Audit detail</p>
                <h1>{project_name}</h1>
                <p className="page-subtitle">{target_url}</p>
            </div>
            <Button variant="secondary" onClick={handleExport}>Export report</Button>
        </header>

        {auditState.error != "" and <Alert tone="danger">{auditState.error}</Alert>}
        {auditState.loading and <p className="empty-state">Loading audit...</p>}

        <Tabs>
            <TabList>
                <TabButton active={True} onClick={goOverview}>Overview</TabButton>
                <TabButton onClick={goRetention}>Loop findings</TabButton>
            </TabList>
        </Tabs>

        {has_run and <div className="score-grid">
            <Card>
                <CardHeader>
                    <CardTitle>Retention loop score</CardTitle>
                    <CardDescription>Cues, actions, rewards, learning loops, attention safety, and user control.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Progress value={retention_score} label="Retention loop score" />
                    <RuntimeLink className="table-link" to={"/audits/" + audit_id + "/retention"}>Open loop findings</RuntimeLink>
                </CardContent>
            </Card>
            <Card>
                <CardHeader>
                    <CardTitle>Visual UX score</CardTitle>
                    <CardDescription>Screenshot-ranked hierarchy, choice density, contrast, and processing fluency.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Progress value={visual_score} label="Visual UX score" />
                </CardContent>
            </Card>
            <Card>
                <CardHeader>
                    <CardTitle>Interaction score</CardTitle>
                    <CardDescription>Agentic click-through clarity, feedback, next-step affordance, and friction.</CardDescription>
                </CardHeader>
                <CardContent>
                    <Progress value={interaction_score} label="Interaction score" />
                </CardContent>
            </Card>
        </div>}

        {has_run and <Card>
            <CardHeader>
                <CardTitle>Closed reinforcement loop</CardTitle>
                <CardDescription>How high-retention apps turn useful sessions into repeat behavior.</CardDescription>
            </CardHeader>
            <CardContent>
                <div className="loop-strip">
                    <div><strong>1. Cue</strong><span>Reminder, streak, unfinished task, or saved state.</span></div>
                    <div><strong>2. Action</strong><span>Open, continue, scroll, swipe, save, or complete.</span></div>
                    <div><strong>3. Reward</strong><span>Novelty, progress, feedback, status, or social validation.</span></div>
                    <div><strong>4. Learning</strong><span>The app learns what keeps the user engaged.</span></div>
                    <div><strong>5. Optimization</strong><span>Future cues and content adapt over time.</span></div>
                </div>
            </CardContent>
        </Card>}

        {has_run and <Card>
            <CardHeader>
                <CardTitle>B2C retention rubric</CardTitle>
                <CardDescription>Observable retention architecture scored separately from aesthetics.</CardDescription>
            </CardHeader>
            <CardContent>
                <div className="rubric-score-grid">
                    <div><span>Onboarding activation</span><strong>{str(onboarding_activation_score) + "/10"}</strong></div>
                    <div><span>Habit loop strength</span><strong>{str(habit_loop_strength_score) + "/10"}</strong></div>
                    <div><span>Reward feedback</span><strong>{str(reward_design_feedback_score) + "/10"}</strong></div>
                    <div><span>Social retention</span><strong>{str(social_retention_mechanics_score) + "/10"}</strong></div>
                    <div><span>Session depth</span><strong>{str(attention_capture_session_depth_score) + "/10"}</strong></div>
                    <div><span>Personalization</span><strong>{str(personalization_adaptation_score) + "/10"}</strong></div>
                    <div><span>Friction reduction</span><strong>{str(friction_reduction_score) + "/10"}</strong></div>
                    <div><span>Progression investment</span><strong>{str(progression_investment_score) + "/10"}</strong></div>
                    <div><span>Re-entry systems</span><strong>{str(reentry_notification_systems_score) + "/10"}</strong></div>
                    <div><span>Trust and safety</span><strong>{str(trust_emotional_safety_score) + "/10"}</strong></div>
                    <div><span>Dark-pattern risk</span><strong>{str(dark_pattern_risk_score) + "/10"}</strong></div>
                </div>
                <div className="rubric-lists">
                    <div>
                        <h3>Strengths</h3>
                        {len(rubric_strengths) == 0 and <p className="empty-state">No specific strengths recorded.</p>}
                        {len(rubric_strengths) > 0 and <ul>{[<li key={str(i)}>{rubric_strengths[i]}</li> for i in range(len(rubric_strengths))]}</ul>}
                    </div>
                    <div>
                        <h3>Weaknesses</h3>
                        {len(rubric_weaknesses) == 0 and <p className="empty-state">No specific weaknesses recorded.</p>}
                        {len(rubric_weaknesses) > 0 and <ul>{[<li key={str(i)}>{rubric_weaknesses[i]}</li> for i in range(len(rubric_weaknesses))]}</ul>}
                    </div>
                    <div>
                        <h3>Retention risks</h3>
                        {len(rubric_risks) == 0 and <p className="empty-state">No specific risks recorded.</p>}
                        {len(rubric_risks) > 0 and <ul>{[<li key={str(i)}>{rubric_risks[i]}</li> for i in range(len(rubric_risks))]}</ul>}
                    </div>
                    <div>
                        <h3>Highest leverage</h3>
                        {len(rubric_improvements) == 0 and <p className="empty-state">No specific improvements recorded.</p>}
                        {len(rubric_improvements) > 0 and <ul>{[<li key={str(i)}>{rubric_improvements[i]}</li> for i in range(len(rubric_improvements))]}</ul>}
                    </div>
                    <div>
                        <h3>Dark-pattern reasons</h3>
                        {len(dark_pattern_risk_reasons) == 0 and <p className="empty-state">No material dark-pattern risk observed.</p>}
                        {len(dark_pattern_risk_reasons) > 0 and <ul>{[<li key={str(i)}>{dark_pattern_risk_reasons[i]}</li> for i in range(len(dark_pattern_risk_reasons))]}</ul>}
                    </div>
                </div>
            </CardContent>
        </Card>}

        {has_run and <Card>
            <CardHeader>
                <CardTitle>Run summary</CardTitle>
                <CardDescription>{run_status} / {completed_at}</CardDescription>
            </CardHeader>
            <CardContent>
                <p>{crawl_summary}</p>
                <p>{visual_summary}</p>
                <p>{legal_filter_summary}</p>
                <div className="action-row">
                    <RuntimeLink className="table-link" to={"/audits/" + audit_id + "/retention"}>Open loop findings</RuntimeLink>
                    <Badge tone="neutral">{snapshots_count} snapshots</Badge>
                    <Badge tone="neutral">{visual_count} screenshots</Badge>
                    <Badge tone="neutral">{interaction_count} clicks</Badge>
                    <Badge tone="neutral">{recommendations_count} recommendations</Badge>
                </div>
            </CardContent>
        </Card>}

        {visual_count > 0 and <Card>
            <CardHeader>
                <CardTitle>Screenshot UX evidence</CardTitle>
                <CardDescription>Browser-captured states ranked with psychology-based visual heuristics.</CardDescription>
            </CardHeader>
            <CardContent>
                <div className="visual-grid">
                    {[<article className="visual-evidence" key={shot.uid}>
                        <img className="visual-shot" src={shot.screenshot_data_url} alt={shot.action_label} />
                        <div className="visual-meta">
                            <div className="finding-topline">
                                <Badge tone={"success" if shot.psychology_rank == "strong" else "warning" if shot.psychology_rank == "mixed" else "danger"}>{shot.psychology_rank}</Badge>
                                <Badge tone="neutral">{str(shot.psychology_score) + "/100"}</Badge>
                                <Badge tone="neutral">{str(shot.clickable_count) + " clickables"}</Badge>
                            </div>
                            <h3>{shot.action_label}</h3>
                            <p className="mono-url">{shot.page_url}</p>
                            <p className="evidence-text">{shot.visual_notes}</p>
                        </div>
                    </article> for shot in visual_snapshots]}
                </div>
            </CardContent>
        </Card>}

        {interaction_count > 0 and <Card>
            <CardHeader>
                <CardTitle>Agentic click-through evidence</CardTitle>
                <CardDescription>Safe same-origin components the browser agent clicked and ranked after interaction.</CardDescription>
            </CardHeader>
            <CardContent>
                <Table>
                    <TableHead>
                        <TableRow>
                            <TableHeader>Component</TableHeader>
                            <TableHeader>Result</TableHeader>
                            <TableHeader>Rank</TableHeader>
                            <TableHeader>Evidence</TableHeader>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {[<TableRow key={step.uid}>
                            <TableCell>{step.element_label}</TableCell>
                            <TableCell>{step.result}</TableCell>
                            <TableCell>{step.psychology_rank} / {str(step.psychology_score) + "/100"} / friction {str(step.friction_score) + "/100"}</TableCell>
                            <TableCell>{step.visual_notes}</TableCell>
                        </TableRow> for step in interaction_steps]}
                    </TableBody>
                </Table>
            </CardContent>
        </Card>}

        {snapshots_count > 0 and <Card>
            <CardHeader>
                <CardTitle>Captured evidence</CardTitle>
                <CardDescription>Sanitized snapshots; raw form values and scripts are not stored.</CardDescription>
            </CardHeader>
            <CardContent>
                <Table>
                    <TableHead>
                        <TableRow>
                            <TableHeader>Page</TableHeader>
                            <TableHeader>Signals</TableHeader>
                            <TableHeader>Excerpt</TableHeader>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {[<TableRow key={snapshot.uid}>
                            <TableCell><span className="mono-url">{snapshot.page_url}</span></TableCell>
                            <TableCell>{snapshot.form_count} forms / {snapshot.input_count} inputs / {len(snapshot.ctas)} CTAs</TableCell>
                            <TableCell>{snapshot.text_excerpt}</TableCell>
                        </TableRow> for snapshot in snapshots]}
                    </TableBody>
                </Table>
            </CardContent>
        </Card>}

        <Dialog open={showExport}>
            <DialogHeader>
                <DialogTitle>Exported markdown</DialogTitle>
            </DialogHeader>
            <DialogContent>
                <pre className="report-export">{export_markdown}</pre>
            </DialogContent>
            <DialogFooter>
                <Button onClick={closeExport}>Close</Button>
            </DialogFooter>
        </Dialog>
    </AppShell>;
}
