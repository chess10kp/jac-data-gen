"""Drug multi-select dropdown component."""

import from react { useRef, useEffect }

def:pub DrugSelector(drugs: list, selected: list, customDrugs: list = [], onToggle: any = None, onAddCustom: any = None, card_bg: str = "#1c1c1e") -> any {
    has search: str = "";
    has is_open: bool = False;
    input_ref = useRef(None);

    filtered = [d for d in drugs if d.lower().includes(search.lower())];
    search_trimmed = search.strip();
    # Show "Add custom" if search doesn't exactly match any known drug (case-insensitive)
    has_exact_match = False;
    if search_trimmed {
        for d in drugs {
            if d.lower() == search_trimmed.lower() {
                has_exact_match = True;
            }
        }
    }
    show_add_custom = onAddCustom and len(search_trimmed) >= 2 and not has_exact_match;

    useEffect(lambda () {
        def handle_click(e: any) {
            if input_ref.current and not input_ref.current.closest("[data-ds]").contains(e.target) {
                is_open = False;
            }
        }
        document.addEventListener("mousedown", handle_click);
        return lambda () { document.removeEventListener("mousedown", handle_click); };
    }, []);

    return <div style={{"position": "relative", "width": "100%"}} data-ds="true">
        <div
            style={{
                "display": "flex",
                "flexWrap": "wrap",
                "gap": "6px",
                "padding": "10px 12px",
                "border": "1px solid " + ("rgba(0,122,255,0.4)" if is_open else "rgba(128,128,128,0.15)"),
                "borderRadius": "12px",
                "minHeight": "44px",
                "backgroundColor": "inherit",
                "transition": "border-color 0.2s, box-shadow 0.2s",
                "alignItems": "center",
                "cursor": "text",
                "boxShadow": "0 0 0 3px rgba(0,122,255,0.15)" if is_open else "none"
            }}
            onClick={lambda () {
                is_open = True;
                if input_ref.current { input_ref.current.focus(); }
            }}
        >
            {[
                <span
                    key={drug}
                    style={{
                        "backgroundColor": "rgba(0,122,255,0.12)" if drug in customDrugs else "rgba(128,128,128,0.1)",
                        "color": "#007aff" if drug in customDrugs else "inherit",
                        "padding": "4px 10px",
                        "borderRadius": "8px",
                        "fontSize": "13px",
                        "fontWeight": "500",
                        "display": "inline-flex",
                        "alignItems": "center",
                        "gap": "6px",
                        "whiteSpace": "nowrap",
                        "letterSpacing": "-0.01em"
                    }}
                >
                    {drug}
                    <span
                        onClick={lambda (e: any) {
                            e.stopPropagation();
                            onToggle(drug);
                        }}
                        style={{
                            "cursor": "pointer",
                            "fontSize": "11px",
                            "color": "#86868b",
                            "width": "16px",
                            "height": "16px",
                            "display": "inline-flex",
                            "alignItems": "center",
                            "justifyContent": "center",
                            "borderRadius": "50%",
                            "backgroundColor": "rgba(128,128,128,0.15)"
                        }}
                    >{"x"}</span>
                </span>
                for drug in selected
            ]}
            <input
                ref={input_ref}
                type="text"
                placeholder={"Search medications..." if len(selected) == 0 else "Add more..."}
                value={search}
                onChange={lambda (e: any) { search = e.target.value; }}
                onKeyDown={lambda (e: any) {
                    if e.key == "Backspace" and search == "" and len(selected) > 0 {
                        onToggle(selected[len(selected) - 1]);
                    }
                }}
                onFocus={lambda () { is_open = True; }}
                style={{
                    "border": "none",
                    "outline": "none",
                    "fontSize": "15px",
                    "flex": "1",
                    "minWidth": "120px",
                    "padding": "2px 4px",
                    "backgroundColor": "transparent",
                    "color": "inherit",
                    "letterSpacing": "-0.01em"
                }}
            />
        </div>
        {<div style={{
            "position": "absolute",
            "top": "100%",
            "left": "0",
            "right": "0",
            "marginTop": "6px",
            "backgroundColor": card_bg,
            "border": "1px solid rgba(128,128,128,0.15)",
            "borderRadius": "12px",
            "maxHeight": "240px",
            "overflowY": "auto",
            "zIndex": "50",
            "boxShadow": "0 8px 30px rgba(0,0,0,0.4)",
            "padding": "4px"
        }}>
            {[
                <div
                    key={drug}
                    onClick={lambda (e: any) {
                        e.stopPropagation();
                        onToggle(drug);
                        search = "";
                        if input_ref.current { input_ref.current.focus(); }
                    }}
                    style={{
                        "padding": "8px 12px",
                        "cursor": "pointer",
                        "backgroundColor": "rgba(0,122,255,0.12)" if drug in selected else "transparent",
                        "borderRadius": "8px",
                        "fontSize": "14px",
                        "color": "#007aff" if drug in selected else "inherit",
                        "fontWeight": "500" if drug in selected else "400",
                        "transition": "background-color 0.1s",
                        "display": "flex",
                        "justifyContent": "space-between",
                        "alignItems": "center"
                    }}
                >
                    <span>{drug}</span>
                    {<span style={{"color": "#007aff", "fontSize": "12px", "fontWeight": "500"}}>{"added"}</span> if drug in selected else <span></span>}
                </div>
                for drug in filtered
            ]}
            {<div
                onClick={lambda (e: any) {
                    e.stopPropagation();
                    # Capitalize first letter of each word
                    words = search_trimmed.split(" ");
                    capitalized = [w[0].upper() + w[1:] if len(w) > 0 else w for w in words];
                    drug_name = " ".join(capitalized);
                    onAddCustom(drug_name);
                    search = "";
                    if input_ref.current { input_ref.current.focus(); }
                }}
                style={{
                    "padding": "10px 12px",
                    "cursor": "pointer",
                    "borderRadius": "8px",
                    "fontSize": "14px",
                    "color": "#007aff",
                    "fontWeight": "500",
                    "display": "flex",
                    "alignItems": "center",
                    "gap": "6px",
                    "transition": "background-color 0.1s",
                    "borderTop": "1px solid rgba(128,128,128,0.1)" if len(filtered) > 0 else "none",
                    "marginTop": "2px" if len(filtered) > 0 else "0"
                }}
            >
                <span style={{"fontSize": "16px", "fontWeight": "600"}}>{"+"}</span>
{"Add " + String.fromCharCode(8220) + search_trimmed + String.fromCharCode(8221) + " as custom drug"}
            </div> if show_add_custom else <span></span>}
            {<div style={{
                "padding": "16px",
                "color": "#86868b",
                "fontSize": "14px",
                "textAlign": "center"
            }}>{"No results"}</div> if len(filtered) == 0 and not show_add_custom else <span></span>}
        </div> if is_open else <span></span>}
    </div>;
}
