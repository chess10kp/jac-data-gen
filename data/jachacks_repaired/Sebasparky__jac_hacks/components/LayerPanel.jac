"""Layer panel for the Jac-authored browser shell."""

"""R: Render the layer workflow controls used during migration.
M: Displays current session/workflow ids plus a short rolling log feed.
E: This panel is currently local-state only while runtime integration is ported.
"""
def:pub LayerPanel(
    session_id: str,
    workflow_id: str,
    log_lines: list[str],
    onStartTrace: any,
    onStopTrace: any,
    onCompile: any,
    onPlan: any
) -> JsxElement {
    panel_style = {
        "position": "fixed",
        "right": "16px",
        "bottom": "16px",
        "width": "288px",
        "padding": "10px",
        "borderRadius": "14px",
        "border": "1px solid #cbd6ea",
        "background": "rgba(255, 255, 255, 0.96)",
        "boxShadow": "0 12px 30px rgba(23, 43, 85, 0.18)",
        "backdropFilter": "blur(14px)",
        "zIndex": 20
    };

    title_style = {
        "fontSize": "13px",
        "fontWeight": "700",
        "color": "#24385f",
        "marginBottom": "8px"
    };

    grid_style = {
        "display": "grid",
        "gridTemplateColumns": "1fr 1fr",
        "gap": "8px",
        "marginBottom": "8px"
    };

    button_style = {
        "height": "32px",
        "borderRadius": "9px",
        "border": "1px solid #c8d6f3",
        "background": "#f3f7ff",
        "color": "#244376",
        "fontSize": "12px",
        "fontWeight": "700",
        "cursor": "pointer"
    };

    meta_style = {
        "fontSize": "11px",
        "lineHeight": "1.7",
        "color": "#566987",
        "marginBottom": "8px"
    };

    log_style = {
        "minHeight": "96px",
        "maxHeight": "176px",
        "overflow": "auto",
        "borderRadius": "10px",
        "border": "1px solid #d8e2f4",
        "background": "#f8fbff",
        "padding": "8px",
        "fontSize": "11px",
        "lineHeight": "1.45",
        "color": "#2b436d",
        "whiteSpace": "pre-wrap"
    };

    rendered_logs: list[JsxElement] = [];
    log_index: int = 0;
    for line in log_lines {
        rendered_logs.append(<div key={str(log_index)}>{line}</div>);
        log_index = log_index + 1;
    }

    return <aside style={panel_style}>
        <div style={title_style}>Layer Dev</div>
        <div style={grid_style}>
            <button style={button_style} onClick={onStartTrace}>Start Trace</button>
            <button style={button_style} onClick={onStopTrace}>Stop Trace</button>
            <button style={button_style} onClick={onCompile}>Compile</button>
            <button style={button_style} onClick={onPlan}>Plan</button>
        </div>
        <div style={meta_style}>
            <div>Session: {session_id}</div>
            <div>Workflow: {workflow_id}</div>
        </div>
        <div style={log_style}>{rendered_logs}</div>
    </aside>;
}
