"""Result card component for flagged interaction chains."""

def:pub ResultCard(chain: any, onSuggestReplacement: any = None, replacementData: any = None, replacementLoading: bool = False) -> any {
    risk = chain["risk"];
    path = chain["path"];
    mechanisms = chain["mechanisms"];
    depth = chain["depth"];

    severity_label = "Critical";
    color = "#ff3b30";
    tint = "rgba(255,59,48,0.08)";
    if risk < 0.6 {
        severity_label = "Low";
        color = "#34c759";
        tint = "rgba(52,199,89,0.08)";
    } elif risk < 0.7 {
        severity_label = "Moderate";
        color = "#ff9500";
        tint = "rgba(255,149,0,0.08)";
    } elif risk < 0.9 {
        severity_label = "High";
        color = "#ff6b35";
        tint = "rgba(255,107,53,0.08)";
    }

    score = Math.min(Math.round(risk * 10 * 10) / 10, 10.0);
    bar_pct = str(Math.min(Math.round(score * 10), 100)) + "%";

    return <div style={{
        "borderRadius": "16px",
        "marginBottom": "10px",
        "overflow": "hidden"
    }}>
        <div style={{
            "display": "flex",
            "justifyContent": "space-between",
            "alignItems": "center",
            "padding": "14px 20px",
            "backgroundColor": tint
        }}>
            <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                <span style={{
                    "width": "8px",
                    "height": "8px",
                    "borderRadius": "50%",
                    "backgroundColor": color,
                    "flexShrink": "0"
                }}></span>
                <span style={{
                    "fontSize": "13px",
                    "fontWeight": "600",
                    "color": color
                }}>{severity_label}</span>
            </div>
            <div style={{"display": "flex", "alignItems": "center", "gap": "10px"}}>
                <div style={{
                    "width": "48px",
                    "height": "4px",
                    "backgroundColor": "rgba(128,128,128,0.15)",
                    "borderRadius": "2px",
                    "overflow": "hidden"
                }}>
                    <div style={{"width": bar_pct, "height": "100%", "backgroundColor": color, "borderRadius": "2px"}}></div>
                </div>
                <span style={{
                    "fontSize": "20px",
                    "fontWeight": "700",
                    "color": "inherit",
                    "letterSpacing": "-0.02em"
                }}>{str(score)}</span>
            </div>
        </div>

        <div style={{"padding": "16px 20px"}}>
            <div style={{
                "display": "flex",
                "alignItems": "center",
                "gap": "6px",
                "marginBottom": "14px",
                "flexWrap": "wrap"
            }}>
                {[
                    <span key={str(idx)} style={{"display": "flex", "alignItems": "center", "gap": "6px"}}>
                        <span style={{
                            "backgroundColor": "rgba(128,128,128,0.1)",
                            "padding": "5px 12px",
                            "borderRadius": "8px",
                            "fontWeight": "500",
                            "fontSize": "13px",
                            "color": "inherit"
                        }}>{path[idx]}</span>
                        {<span style={{"color": "rgba(128,128,128,0.6)", "fontSize": "13px"}}>{" " + String.fromCharCode(8594) + " "}</span> if idx < len(path) - 1 else <span></span>}
                    </span>
                    for idx in range(len(path))
                ]}
            </div>

            {[
                <div key={str(idx)} style={{
                    "padding": "10px 0",
                    "borderTop": "1px solid rgba(128,128,128,0.1)" if idx > 0 else "none",
                    "fontSize": "13px",
                    "color": "rgba(128,128,128,0.75)",
                    "lineHeight": "1.5",
                    "display": "flex",
                    "gap": "8px"
                }}>
                    <span style={{
                        "color": "rgba(128,128,128,0.75)",
                        "fontSize": "12px",
                        "fontWeight": "600",
                        "minWidth": "16px",
                        "flexShrink": "0"
                    }}>{str(idx + 1)}</span>
                    <span>{mechanisms[idx]}</span>
                </div>
                for idx in range(len(mechanisms))
            ]}

            {<div style={{"marginTop": "14px"}}>
                {<div style={{
                    "backgroundColor": "rgba(128,128,128,0.06)",
                    "borderRadius": "12px",
                    "padding": "16px"
                }}>
                    {<div style={{"color": "rgba(128,128,128,0.6)", "fontSize": "14px", "textAlign": "center"}}>{"No safer alternative found for this chain."}</div>
                    if not replacementData["suggestion"] else
                    <div>
                        <div style={{"fontSize": "12px", "fontWeight": "600", "color": "rgba(128,128,128,0.5)", "letterSpacing": "0.02em", "marginBottom": "10px"}}>{"SUGGESTED REPLACEMENT"}</div>
                        <div style={{
                            "display": "flex",
                            "alignItems": "center",
                            "gap": "8px",
                            "marginBottom": "12px",
                            "flexWrap": "wrap"
                        }}>
                            <span style={{
                                "backgroundColor": "rgba(255,59,48,0.12)",
                                "color": "#ff3b30",
                                "padding": "5px 12px",
                                "borderRadius": "8px",
                                "fontWeight": "500",
                                "fontSize": "13px",
                                "textDecoration": "line-through"
                            }}>{replacementData["suggestion"]["drug_to_replace"]}</span>
                            <span style={{"color": "rgba(128,128,128,0.6)", "fontSize": "13px"}}>{String.fromCharCode(8594)}</span>
                            <span style={{
                                "backgroundColor": "rgba(52,199,89,0.12)",
                                "color": "#34c759",
                                "padding": "5px 12px",
                                "borderRadius": "8px",
                                "fontWeight": "500",
                                "fontSize": "13px"
                            }}>{replacementData["suggestion"]["replacement_drug"]}</span>
                            <span style={{
                                "fontSize": "11px",
                                "color": "rgba(128,128,128,0.5)",
                                "fontWeight": "500"
                            }}>{replacementData["suggestion"]["therapeutic_class"]}</span>
                        </div>
                        <div style={{
                            "fontSize": "13px",
                            "color": "rgba(128,128,128,0.75)",
                            "lineHeight": "1.5",
                            "marginBottom": "10px"
                        }}>{replacementData["suggestion"]["reasoning"]}</div>
                        <div style={{"display": "flex", "alignItems": "center", "gap": "8px", "flexWrap": "wrap"}}>
                            {<span style={{
                                "fontSize": "12px",
                                "fontWeight": "600",
                                "padding": "3px 10px",
                                "borderRadius": "6px",
                                "backgroundColor": "rgba(52,199,89,0.12)" if replacementData["suggestion"]["is_actually_safer"] else "rgba(255,59,48,0.12)",
                                "color": "#34c759" if replacementData["suggestion"]["is_actually_safer"] else "#ff3b30"
                            }}>{("Verified Safer (" + str(Math.round(replacementData["suggestion"]["original_risk"] * 100) / 10) + " " + String.fromCharCode(8594) + " " + str(Math.round(replacementData["suggestion"]["new_max_risk"] * 100) / 10) + ")") if replacementData["suggestion"]["is_actually_safer"] else "Warning: May Not Be Safer"}</span> if replacementData["suggestion"]["verified"] else <span style={{
                                "fontSize": "12px",
                                "fontWeight": "600",
                                "padding": "3px 10px",
                                "borderRadius": "6px",
                                "backgroundColor": "rgba(255,149,0,0.12)",
                                "color": "#ff9500"
                            }}>{"Could Not Verify"}</span>}
                            <span style={{
                                "fontSize": "11px",
                                "fontWeight": "500",
                                "color": "rgba(128,128,128,0.5)"
                            }}>{"Confidence: " + replacementData["suggestion"]["confidence"]}</span>
                        </div>
                    </div>}
                </div> if replacementData else
                <button
                    onClick={lambda () { onSuggestReplacement(chain); }}
                    disabled={replacementLoading}
                    style={{
                        "width": "100%",
                        "padding": "12px",
                        "backgroundColor": "rgba(128,128,128,0.06)",
                        "border": "none",
                        "borderRadius": "10px",
                        "fontSize": "14px",
                        "fontWeight": "500",
                        "cursor": "pointer" if not replacementLoading else "wait",
                        "color": "#007aff" if not replacementLoading else "rgba(128,128,128,0.5)",
                        "transition": "background-color 0.15s"
                    }}
                >{("Finding alternative..." if replacementLoading else "Suggest Safer Alternative")}</button>}
            </div> if onSuggestReplacement else <span></span>}
        </div>
    </div>;
}
