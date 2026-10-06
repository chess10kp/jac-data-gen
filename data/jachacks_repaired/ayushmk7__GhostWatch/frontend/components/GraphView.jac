import "@xyflow/react/dist/style.css";
import from "@xyflow/react" { ReactFlow, Background }

def riskColor(score: any) -> str {
    s: any = score if score else 0;
    s_int: int = int(s);
    if s_int >= 14 {
        return "rgba(239,68,68,0.18)";
    }
    if s_int >= 7 {
        return "rgba(251,191,36,0.15)";
    }
    return "rgba(125,211,255,0.18)";
}

def riskBorder(score: any) -> str {
    s: any = score if score else 0;
    s_int: int = int(s);
    if s_int >= 14 {
        return "1.5px solid rgba(239,68,68,0.7)";
    }
    if s_int >= 7 {
        return "2px solid rgba(251,191,36,0.55)";
    }
    return "1.5px solid rgba(125,211,255,0.4)";
}

def:pub GraphView(
    nodes_data: list[dict],
    edges_data: list[dict],
    animatingPath: list,
    analysisLoading: bool,
    scanResult: bool
) -> JsxElement {

    has hoveredNode: any | None = None;

    # Build path-index lookup for O(1) animation delay calc
    path_index: dict = {};
    i: int = 0;
    for jid_val in animatingPath {
        path_index[jid_val] = i;
        i += 1;
    }
    path_len: int = len(animatingPath);

    total: any = len(nodes_data);
    PI2: any = 6.28318530718;
    cx_r: int = 380;
    cy_r: int = 260;
    # Keep the constellation compact enough that fitView does not zoom it into dust.
    ring_caps: list = [1, 6, 12, 18, 24, 30, 36, 42];
    ring_radii: list = [0, 86, 150, 214, 278, 342, 406, 470];
    ring_start: list = [0, 1, 7, 19, 37, 61, 91, 127];

    # Build ReactFlow node objects
    xf_nodes: list = [];
    idx: int = 0;
    for n in nodes_data {
        node_style: any = {
            "background": riskColor(n["risk_score"]),
            "border": riskBorder(n["risk_score"]),
            "borderRadius": "50%",
            "width": "68px",
            "height": "68px",
            "display": "flex",
            "alignItems": "center",
            "justifyContent": "center",
            "color": "rgba(220,239,255,0.88)",
            "fontSize": "9px",
            "fontWeight": "500",
            "letterSpacing": "0.03em",
            "textAlign": "center",
            "cursor": "default",
            "backdropFilter": "blur(6px)",
            "WebkitBackdropFilter": "blur(6px)"
        };

        if analysisLoading {
            node_style["animationName"] = "gw-node-pulse";
            node_style["animationDuration"] = "1.5s";
            node_style["animationIterationCount"] = "infinite";
            node_style["animationTimingFunction"] = "ease-in-out";
        } elif path_len > 0 and n["id"] in path_index {
            node_style["animationName"] = "gw-node-scan";
            node_style["animationDuration"] = f"{path_len * 600}ms";
            delay_ms: any = path_index[n["id"]] * 600;
            node_style["animationDelay"] = f"{delay_ms}ms";
            node_style["animationIterationCount"] = "infinite";
            node_style["animationTimingFunction"] = "ease-in-out";
        } elif scanResult and path_len == 0 {
            node_style["animationName"] = "gw-node-pulse";
            node_style["animationDuration"] = "2s";
            delay_ms2: any = idx * 120;
            node_style["animationDelay"] = f"{delay_ms2}ms";
            node_style["animationIterationCount"] = "3";
            node_style["animationTimingFunction"] = "ease-in-out";
            node_style["animationFillMode"] = "forwards";
        }

        node_path: any = n["path"];
        path_parts: any = node_path.split("/"); # jac:ignore[E1032]
        label: any = path_parts[len(path_parts) - 1] if len(path_parts) > 0 else node_path;

        # Multi-ring layout: find which ring this node belongs to
        ring: int = 0;
        ri: int = len(ring_caps) - 1;
        while ri >= 0 {
            if idx >= ring_start[ri] {
                ring = ri;
                break;
            }
            ri -= 1;
        }
        ring_idx: any = idx - ring_start[ring];
        ring_total: any = ring_caps[ring];
        radius: any = ring_radii[ring];
        angle: any = (ring_idx * PI2) / ring_total if ring_total > 1 else 0;
        x_pos: any = cx_r + radius * Math.cos(angle); # jac:ignore[E1032]
        y_pos: any = cy_r + radius * Math.sin(angle); # jac:ignore[E1032]

        xf_nodes.append({
            "id": n["id"],
            "position": {"x": x_pos, "y": y_pos},
            "data": {
                "label": label,
                "path": node_path,
                "risk_score": n["risk_score"],
                "language": n["language"]
            },
            "style": node_style
        });
        idx += 1;
    }

    # Build ReactFlow edge objects
    xf_edges: any = [
        {
            "id": f"{e['source']}-{e['target']}",
            "source": e["source"],
            "target": e["target"],
            "animated": True,
            "style": {"stroke": "rgba(125,211,255,0.4)", "strokeWidth": 1.5}
        }
        for e in edges_data
    ];

    # Resolve hovered node's full data for tooltip
    hovered_data: any | None = None;
    if hoveredNode {
        hov_id: any = hoveredNode["id"]; # jac:ignore[E1001]
        for nd in nodes_data {
            if nd["id"] == hov_id {
                hovered_data = nd;
                break;
            }
        }
    }

    risk_label: str = "Low";
    tooltip_risk_class: str = "gw-node-tooltip-value";
    tooltip_lang: str = "—";
    tooltip_score: str = "0";
    tooltip_path: str = "";
    if hovered_data {
        rs: any = int(hovered_data["risk_score"] or 0);
        if rs >= 14 {
            risk_label = "High";
            tooltip_risk_class = "gw-node-tooltip-value gw-node-tooltip-value--high";
        } elif rs >= 7 {
            risk_label = "Medium";
            tooltip_risk_class = "gw-node-tooltip-value gw-node-tooltip-value--med";
        }
        tooltip_lang = hovered_data["language"] or "—";
        tooltip_score = str(hovered_data["risk_score"] or 0);
        tooltip_path = hovered_data["path"];
    }

    return
        <div className="gw-graph-canvas" style={{"position": "relative"}}>
            <ReactFlow
                nodes={xf_nodes}
                edges={xf_edges}
                fitView={True}
                fitViewOptions={{"padding": 0.12, "minZoom": 0.38, "maxZoom": 1.2}}
                nodesDraggable={False}
                nodesConnectable={False}
                elementsSelectable={False}
                proOptions={{"hideAttribution": True}}
                onNodeMouseEnter={lambda (event: any, `node: any) {
                    hoveredNode = `node; # jac:ignore[E1001]
                }}
                onNodeMouseLeave={lambda (event: any, `node: any) {
                    hoveredNode = None; # jac:ignore[E1001]
                }}
            >
                <Background color="rgba(125,211,255,0.06)" gap={28} size={1}/>
            </ReactFlow>
            {hovered_data and
                <div className="gw-node-tooltip">
                    <div className="gw-node-tooltip-path">
                        {tooltip_path}
                    </div>
                    <div className="gw-node-tooltip-row">
                        <span className="gw-node-tooltip-label">
                            Risk
                        </span>
                        <span className={tooltip_risk_class}>
                            {risk_label + " (" + tooltip_score + ")"}
                        </span>
                    </div>
                    <div className="gw-node-tooltip-row">
                        <span className="gw-node-tooltip-label">
                            Lang
                        </span>
                        <span className="gw-node-tooltip-value">
                            {tooltip_lang}
                        </span>
                    </div>
                </div>}
        </div>;
}
