"""Drug interaction graph."""

import from react { useRef, useEffect }

def:pub DrugGraph(medications: list, interactions: list, flagged_paths: list, is_dark: bool = True) -> any {
    canvas_ref = useRef(None);

    if len(interactions) == 0 {
        return <div style={{
            "borderRadius": "20px",
            "padding": "20px 24px",
            "marginBottom": "16px"
        }}>
            <div style={{"fontSize": "15px", "fontWeight": "600", "color": "#f5f5f7" if is_dark else "#1d1d1f", "marginBottom": "12px"}}>{"Interaction Graph"}</div>
            <div style={{"textAlign": "center", "padding": "40px 20px", "backgroundColor": "#2c2c2e" if is_dark else "#f5f5f7", "borderRadius": "14px"}}>
                <div style={{"fontSize": "17px", "fontWeight": "600", "color": "#f5f5f7" if is_dark else "#1d1d1f"}}>{"No known interactions"}</div>
                <div style={{"fontSize": "14px", "color": "#86868b", "marginTop": "4px"}}>{"These medications have no documented pairwise interactions in our database."}</div>
            </div>
        </div>;
    }

    useEffect(lambda () {
        canvas = canvas_ref.current;
        if not canvas { return lambda () {}; }
        ctx = canvas.getContext("2d");
        dpr = window.devicePixelRatio or 1;
        rect = canvas.getBoundingClientRect();
        w = rect.width;
        h = 480;
        canvas.width = int(w * dpr);
        canvas.height = int(h * dpr);
        canvas.style.height = str(h) + "px";
        ctx.scale(dpr, dpr);
        count = len(medications);
        cx = w / 2;
        cy = h / 2;

        # Theme
        node_fill = "#2c2c2e" if is_dark else "#ffffff";
        node_fill_hv = "#3a3a3c" if is_dark else "#f0f0f5";
        node_flag_fill = "#3a1a1a" if is_dark else "#fff5f5";
        node_flag_fill_hv = "#4a2020" if is_dark else "#ffecec";
        node_stroke = "rgba(255,255,255,0.15)" if is_dark else "rgba(0,0,0,0.1)";
        label_color = "#f5f5f7" if is_dark else "#1d1d1f";
        label_dim = "#86868b";
        label_bg = "rgba(44,44,46,0.9)" if is_dark else "rgba(245,245,247,0.9)";
        tooltip_bg = "rgba(245,245,247,0.95)" if is_dark else "rgba(29,29,31,0.92)";
        tooltip_text = "#1d1d1f" if is_dark else "#ffffff";
        edge_label_bg = "rgba(44,44,46,0.92)" if is_dark else "rgba(255,255,255,0.92)";
        edge_normal = "rgba(255,255,255," if is_dark else "rgba(0,0,0,";

        # Build data structures
        node_map = {};
        i = 0;
        while i < count {
            node_map[medications[i]] = i;
            i = i + 1;
        }

        edges = [];
        seen = {};
        ei = 0;
        while ei < len(interactions) {
            a = interactions[ei]["drug_a"];
            b = interactions[ei]["drug_b"];
            key = a + "|" + b if a < b else b + "|" + a;
            if a in node_map and b in node_map and not (key in seen) {
                seen[key] = True;
                fl = False;
                fi = 0;
                while fi < len(flagged_paths) {
                    fp = flagged_paths[fi]["path"];
                    fj = 0;
                    while fj < len(fp) - 1 {
                        if (fp[fj] == a and fp[fj + 1] == b) or (fp[fj] == b and fp[fj + 1] == a) { fl = True; }
                        fj = fj + 1;
                    }
                    fi = fi + 1;
                }
                edges.append({"s": node_map[a], "t": node_map[b], "type": interactions[ei]["type"], "fl": fl, "ci": len(edges)});
            }
            ei = ei + 1;
        }

        # Per-node edge indices for curve offsets
        node_ec = {};
        nci = 0;
        while nci < count { node_ec[nci] = 0; nci = nci + 1; }
        eci = 0;
        while eci < len(edges) {
            node_ec[edges[eci]["s"]] = node_ec[edges[eci]["s"]] + 1;
            node_ec[edges[eci]["t"]] = node_ec[edges[eci]["t"]] + 1;
            eci = eci + 1;
        }
        # Assign offsets
        node_ei = {};
        nei = 0;
        while nei < count { node_ei[nei] = 0; nei = nei + 1; }
        eoi = 0;
        while eoi < len(edges) {
            s = edges[eoi]["s"];
            total = node_ec[s];
            idx = node_ei[s];
            edges[eoi]["off"] = (idx - (total - 1) / 2.0) * 20 if total > 1 else 0;
            node_ei[s] = idx + 1;
            eoi = eoi + 1;
        }

        # Flag counts
        fc = {};
        fci = 0;
        while fci < count { fc[fci] = 0; fci = fci + 1; }
        pi = 0;
        while pi < len(flagged_paths) {
            pa = flagged_paths[pi]["path"];
            pk = 0;
            while pk < len(pa) {
                if pa[pk] in node_map { fc[node_map[pa[pk]]] = fc[node_map[pa[pk]]] + 1; }
                pk = pk + 1;
            }
            pi = pi + 1;
        }

        # Build adjacency lists for layout ordering
        adj = {};
        ai = 0;
        while ai < count { adj[ai] = []; ai = ai + 1; }
        ae = 0;
        while ae < len(edges) {
            adj[edges[ae]["s"]].append(edges[ae]["t"]);
            adj[edges[ae]["t"]].append(edges[ae]["s"]);
            ae = ae + 1;
        }

        # Greedy circular ordering: place connected nodes adjacent
        # Start with highest-degree node, then greedily pick neighbor
        order = [];
        placed = {};
        # Find start: node with most edges
        best = 0;
        bval = 0;
        bi = 0;
        while bi < count {
            if len(adj[bi]) > bval { bval = len(adj[bi]); best = bi; }
            bi = bi + 1;
        }
        order.append(best);
        placed[best] = True;
        while len(order) < count {
            last = order[len(order) - 1];
            # Try to find unplaced neighbor of last
            found = -1;
            fi2 = 0;
            while fi2 < len(adj[last]) {
                cand = adj[last][fi2];
                if not (cand in placed) { found = cand; }
                fi2 = fi2 + 1;
            }
            if found < 0 {
                # No neighbor available, pick any unplaced
                ui2 = 0;
                while ui2 < count {
                    if not (ui2 in placed) { found = ui2; }
                    ui2 = ui2 + 1;
                }
            }
            order.append(found);
            placed[found] = True;
        }

        # Place nodes in this order around circle
        spread = Math.min(w * 0.40, h * 0.38);
        nodes = [];
        ni = 0;
        while ni < count {
            nodes.append({"x": 0, "y": 0, "vx": 0, "vy": 0});
            ni = ni + 1;
        }
        oi = 0;
        while oi < count {
            angle = (2 * Math.PI * oi / count) - (Math.PI / 2);
            idx2 = order[oi];
            nodes[idx2]["x"] = cx + Math.cos(angle) * spread;
            nodes[idx2]["y"] = cy + Math.sin(angle) * spread;
            oi = oi + 1;
        }

        running = {"v": True};
        mouse = {"x": -999, "y": -999, "d": -1, "h": -1};

        # Tick
        def tick(ts: any) {
            if not running["v"] { return; }

            # Physics
            a = 0;
            while a < count {
                b = a + 1;
                while b < count {
                    dx = nodes[b]["x"] - nodes[a]["x"];
                    dy = nodes[b]["y"] - nodes[a]["y"];
                    d = Math.sqrt(dx * dx + dy * dy) + 1;
                    f = 4000 / (d * d);
                    nodes[a]["vx"] = nodes[a]["vx"] - (dx / d) * f;
                    nodes[a]["vy"] = nodes[a]["vy"] - (dy / d) * f;
                    nodes[b]["vx"] = nodes[b]["vx"] + (dx / d) * f;
                    nodes[b]["vy"] = nodes[b]["vy"] + (dy / d) * f;
                    b = b + 1;
                }
                a = a + 1;
            }
            ej = 0;
            while ej < len(edges) {
                si = edges[ej]["s"];
                ti = edges[ej]["t"];
                dx = nodes[ti]["x"] - nodes[si]["x"];
                dy = nodes[ti]["y"] - nodes[si]["y"];
                d = Math.sqrt(dx * dx + dy * dy) + 1;
                f = (d - 140) * 0.006;
                nodes[si]["vx"] = nodes[si]["vx"] + (dx / d) * f;
                nodes[si]["vy"] = nodes[si]["vy"] + (dy / d) * f;
                nodes[ti]["vx"] = nodes[ti]["vx"] - (dx / d) * f;
                nodes[ti]["vy"] = nodes[ti]["vy"] - (dy / d) * f;
                ej = ej + 1;
            }
            ui = 0;
            while ui < count {
                nodes[ui]["vx"] = (nodes[ui]["vx"] + (cx - nodes[ui]["x"]) * 0.002) * 0.8;
                nodes[ui]["vy"] = (nodes[ui]["vy"] + (cy - nodes[ui]["y"]) * 0.002) * 0.8;
                if ui != mouse["d"] {
                    nodes[ui]["x"] = nodes[ui]["x"] + nodes[ui]["vx"];
                    nodes[ui]["y"] = nodes[ui]["y"] + nodes[ui]["vy"];
                }
                nodes[ui]["x"] = Math.max(65, Math.min(w - 65, nodes[ui]["x"]));
                nodes[ui]["y"] = Math.max(50, Math.min(h - 50, nodes[ui]["y"]));
                ui = ui + 1;
            }

            # Draw
            ctx.clearRect(0, 0, w, h);

            # --- EDGES ---
            di = 0;
            while di < len(edges) {
                e = edges[di];
                sx = nodes[e["s"]]["x"];
                sy = nodes[e["s"]]["y"];
                tx = nodes[e["t"]]["x"];
                ty = nodes[e["t"]]["y"];
                hl = mouse["h"] == e["s"] or mouse["h"] == e["t"];

                dx = tx - sx;
                dy = ty - sy;
                dist = Math.sqrt(dx * dx + dy * dy) + 1;
                off = e["off"];
                cpx = (sx + tx) / 2 + (-dy / dist) * off;
                cpy = (sy + ty) / 2 + (dx / dist) * off;

                ctx.beginPath();
                ctx.moveTo(sx, sy);
                ctx.quadraticCurveTo(cpx, cpy, tx, ty);
                if e["fl"] {
                    ctx.strokeStyle = "rgba(255,59,48," + ("0.85" if hl else "0.4") + ")";
                    ctx.lineWidth = 2.5 if hl else 1.8;
                    ctx.setLineDash([]);
                } else {
                    ctx.strokeStyle = edge_normal + ("0.5" if hl else "0.12") + ")";
                    ctx.lineWidth = 1.5 if hl else 0.8;
                    ctx.setLineDash([4, 4]);
                }
                ctx.stroke();
                ctx.setLineDash([]);

                di = di + 1;
            }

            # --- EDGE LABELS (drawn before nodes so node labels stay on top) ---
            dli = 0;
            while dli < len(edges) {
                e = edges[dli];
                hl = mouse["h"] == e["s"] or mouse["h"] == e["t"];
                if hl {
                    sx = nodes[e["s"]]["x"];
                    sy = nodes[e["s"]]["y"];
                    tx = nodes[e["t"]]["x"];
                    ty = nodes[e["t"]]["y"];
                    dx = tx - sx;
                    dy = ty - sy;
                    dist = Math.sqrt(dx * dx + dy * dy) + 1;
                    off = e["off"];
                    cpx = (sx + tx) / 2 + (-dy / dist) * off;
                    cpy = (sy + ty) / 2 + (dx / dist) * off;

                    label = e["type"].split("_").join(" ");
                    ctx.font = "500 10px -apple-system, sans-serif";
                    tw = ctx.measureText(label).width;
                    ctx.fillStyle = edge_label_bg;
                    ctx.fillRect(cpx - tw / 2 - 6, cpy - 9, tw + 12, 18);
                    ctx.fillStyle = "#ff3b30" if e["fl"] else label_dim;
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(label, cpx, cpy);
                }
                dli = dli + 1;
            }

            # --- NODES ---
            ni2 = 0;
            while ni2 < count {
                nx = nodes[ni2]["x"];
                ny = nodes[ni2]["y"];
                hv = mouse["h"] == ni2;
                flagged = fc[ni2] > 0;
                r = 20 if hv else 17;

                # Glow
                if flagged {
                    pulse = Math.sin((ts or 0) / 500 + ni2) * 0.03 + 0.1;
                    ctx.beginPath();
                    ctx.arc(nx, ny, r + 8, 0, Math.PI * 2);
                    ctx.fillStyle = "rgba(255,59,48," + str(pulse) + ")";
                    ctx.fill();
                }

                # Shadow
                ctx.beginPath();
                ctx.arc(nx, ny + 1, r, 0, Math.PI * 2);
                ctx.fillStyle = "rgba(0,0,0,0.2)" if is_dark else "rgba(0,0,0,0.06)";
                ctx.fill();

                # Circle fill + stroke
                ctx.beginPath();
                ctx.arc(nx, ny, r, 0, Math.PI * 2);
                if flagged {
                    ctx.fillStyle = node_flag_fill_hv if hv else node_flag_fill;
                    ctx.fill();
                    ctx.strokeStyle = "#ff3b30";
                    ctx.lineWidth = 2;
                    ctx.stroke();
                } else {
                    ctx.fillStyle = node_fill_hv if hv else node_fill;
                    ctx.fill();
                    ctx.strokeStyle = "#007aff" if hv else node_stroke;
                    ctx.lineWidth = 1.5;
                    ctx.stroke();
                }

                # Abbreviation inside circle
                abbr = medications[ni2].substring(0, 3).upper();
                ctx.font = "600 10px -apple-system, sans-serif";
                ctx.fillStyle = "#ff3b30" if flagged else label_color;
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(abbr, nx, ny);

                # Full name label below
                name = medications[ni2];
                ctx.font = hv and "500 10px -apple-system, sans-serif" or "10px -apple-system, sans-serif";
                tw = ctx.measureText(name).width;
                ly = ny + r + 13;
                ctx.fillStyle = label_bg;
                ctx.fillRect(nx - tw / 2 - 4, ly - 7, tw + 8, 14);
                ctx.fillStyle = (hv or flagged) and label_color or label_dim;
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillText(name, nx, ly);

                # Badge
                if flagged and fc[ni2] > 1 {
                    bx = nx + r * 0.65;
                    by_pos = ny - r * 0.65;
                    ctx.beginPath();
                    ctx.arc(bx, by_pos, 7, 0, Math.PI * 2);
                    ctx.fillStyle = "#ff3b30";
                    ctx.fill();
                    ctx.font = "600 8px -apple-system, sans-serif";
                    ctx.fillStyle = "#fff";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillText(str(fc[ni2]), bx, by_pos);
                }

                ni2 = ni2 + 1;
            }

            # --- TOOLTIP ---
            if mouse["h"] >= 0 and mouse["h"] < count {
                hn = nodes[mouse["h"]];
                conn = 0;
                ci2 = 0;
                while ci2 < len(edges) {
                    if edges[ci2]["s"] == mouse["h"] or edges[ci2]["t"] == mouse["h"] { conn = conn + 1; }
                    ci2 = ci2 + 1;
                }
                tip = medications[mouse["h"]] + " " + String.fromCharCode(8226) + " " + str(conn) + " interaction" + ("s" if conn != 1 else "");
                if fc[mouse["h"]] > 0 {
                    tip = tip + " " + String.fromCharCode(8226) + " " + str(fc[mouse["h"]]) + " chain" + ("s" if fc[mouse["h"]] != 1 else "");
                }
                ctx.font = "500 12px -apple-system, sans-serif";
                tw2 = ctx.measureText(tip).width;
                ttx = Math.max(4, Math.min(hn["x"] - tw2 / 2 - 10, w - tw2 - 24));
                tty = hn["y"] - 48;
                if tty < 4 { tty = hn["y"] + 40; }
                ctx.fillStyle = tooltip_bg;
                ctx.fillRect(ttx, tty, tw2 + 20, 28);
                ctx.fillStyle = tooltip_text;
                ctx.textAlign = "left";
                ctx.textBaseline = "middle";
                ctx.fillText(tip, ttx + 10, tty + 14);
            }

            requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);

        # Mouse
        def hittest(mx: any, my: any) -> int {
            gi = count - 1;
            while gi >= 0 {
                dx = mx - nodes[gi]["x"];
                dy = my - nodes[gi]["y"];
                if dx * dx + dy * dy < 700 { return gi; }
                gi = gi - 1;
            }
            return -1;
        }
        def mmove(ev: any) {
            r2 = canvas.getBoundingClientRect();
            mouse["x"] = ev.clientX - r2.left;
            mouse["y"] = ev.clientY - r2.top;
            if mouse["d"] >= 0 {
                nodes[mouse["d"]]["x"] = mouse["x"];
                nodes[mouse["d"]]["y"] = mouse["y"];
                nodes[mouse["d"]]["vx"] = 0;
                nodes[mouse["d"]]["vy"] = 0;
            }
            mouse["h"] = hittest(mouse["x"], mouse["y"]);
            canvas.style.cursor = "grabbing" if mouse["d"] >= 0 else ("grab" if mouse["h"] >= 0 else "default");
        }
        def mdown(ev: any) {
            r2 = canvas.getBoundingClientRect();
            h2 = hittest(ev.clientX - r2.left, ev.clientY - r2.top);
            if h2 >= 0 { mouse["d"] = h2; canvas.style.cursor = "grabbing"; }
        }
        def mup(ev: any) { mouse["d"] = -1; }
        def mleave(ev: any) { mouse["h"] = -1; mouse["d"] = -1; canvas.style.cursor = "default"; }
        canvas.addEventListener("mousemove", mmove);
        canvas.addEventListener("mousedown", mdown);
        canvas.addEventListener("mouseup", mup);
        canvas.addEventListener("mouseleave", mleave);

        return lambda () {
            running["v"] = False;
            canvas.removeEventListener("mousemove", mmove);
            canvas.removeEventListener("mousedown", mdown);
            canvas.removeEventListener("mouseup", mup);
            canvas.removeEventListener("mouseleave", mleave);
        };
    }, [medications, interactions, flagged_paths, is_dark]);

    return <div style={{
        "borderRadius": "20px",
        "padding": "20px 24px",
        "marginBottom": "16px"
    }}>
        <div style={{"display": "flex", "justifyContent": "space-between", "alignItems": "center", "marginBottom": "12px"}}>
            <div style={{"fontSize": "15px", "fontWeight": "600", "color": "#f5f5f7" if is_dark else "#1d1d1f"}}>{"Interaction Graph"}</div>
            <div style={{"display": "flex", "gap": "12px", "fontSize": "11px", "color": "rgba(128,128,128,0.7)", "alignItems": "center"}}>
                <span style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                    <span style={{"display": "inline-block", "width": "10px", "height": "2px", "backgroundColor": "#ff3b30", "borderRadius": "1px"}}></span>
                    {"flagged"}
                </span>
                <span style={{"display": "flex", "alignItems": "center", "gap": "4px"}}>
                    <span style={{"display": "inline-block", "width": "10px", "height": "1px", "backgroundColor": "rgba(128,128,128,0.5)"}}></span>
                    {"interaction"}
                </span>
                <span style={{"color": "rgba(128,128,128,0.4)"}}>{"drag to move"}</span>
            </div>
        </div>
        <canvas ref={canvas_ref} style={{"width": "100%", "height": "480px", "borderRadius": "14px", "backgroundColor": "#2c2c2e" if is_dark else "#f5f5f7"}} />
    </div>;
}
