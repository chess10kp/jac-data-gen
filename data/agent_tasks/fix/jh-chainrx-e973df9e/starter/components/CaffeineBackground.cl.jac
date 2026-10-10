"""3D caffeine molecule background that rotates with mouse movement."""

cl import from react { useRef, useEffect }

def:pub CaffeineBackground(is_dark: bool = True) -> any {
    canvas_ref = useRef(None);

    useEffect(lambda {
        canvas = canvas_ref.current;
        if not canvas { return lambda {}; }
        ctx = canvas.getContext("2d");

        dpr = window.devicePixelRatio or 1;
        w = {"v": window.innerWidth};
        h = {"v": window.innerHeight};

        def resize() {
            w["v"] = window.innerWidth;
            h["v"] = window.innerHeight;
            canvas.width = int(w["v"] * dpr);
            canvas.height = int(h["v"] * dpr);
            canvas.style.width = str(w["v"]) + "px";
            canvas.style.height = str(h["v"]) + "px";
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.scale(dpr, dpr);
        }
        resize();

        # Element colors
        col_c = "#5a5a66" if is_dark else "#48484a";
        col_n = "#4583e8";
        col_o = "#e8554e";
        col_h = "#c5c5cc" if is_dark else "#e0e0e5";

        # Caffeine (C8H10N4O2) — ring atoms puckered slightly, methyl H's give depth.
        atoms = [
            {"c": col_n, "x": -1.20, "y": -1.05, "z": -0.25, "r": 11},
            {"c": col_c, "x":  0.05, "y": -1.55, "z":  0.30, "r": 9},
            {"c": col_n, "x":  1.25, "y": -0.85, "z": -0.35, "r": 11},
            {"c": col_c, "x":  1.20, "y":  0.65, "z":  0.25, "r": 9},
            {"c": col_c, "x": -0.05, "y":  1.35, "z": -0.20, "r": 9},
            {"c": col_c, "x": -1.25, "y":  0.55, "z":  0.35, "r": 9},
            {"c": col_n, "x":  0.30, "y":  2.80, "z": -0.30, "r": 11},
            {"c": col_c, "x":  1.65, "y":  2.75, "z":  0.40, "r": 9},
            {"c": col_n, "x":  2.15, "y":  1.45, "z": -0.25, "r": 11},
            {"c": col_o, "x":  0.10, "y": -2.95, "z":  0.45, "r": 11},
            {"c": col_o, "x": -2.45, "y":  1.20, "z":  0.50, "r": 11},
            {"c": col_c, "x": -2.55, "y": -1.80, "z": -0.10, "r": 9},
            {"c": col_c, "x":  2.55, "y": -1.65, "z": -0.20, "r": 9},
            {"c": col_c, "x": -0.55, "y":  4.10, "z": -0.15, "r": 9},
            {"c": col_h, "x":  2.45, "y":  3.70, "z":  0.55, "r": 5},
            # Methyl hydrogens out of plane give real 3D depth
            {"c": col_h, "x": -3.35, "y": -2.45, "z":  0.80, "r": 5},
            {"c": col_h, "x": -3.35, "y": -2.45, "z": -1.00, "r": 5},
            {"c": col_h, "x": -2.75, "y": -2.85, "z": -0.10, "r": 5},
            {"c": col_h, "x":  3.35, "y": -2.30, "z":  0.70, "r": 5},
            {"c": col_h, "x":  3.35, "y": -2.30, "z": -1.10, "r": 5},
            {"c": col_h, "x":  2.75, "y": -2.70, "z": -0.20, "r": 5},
            {"c": col_h, "x": -1.00, "y":  4.90, "z":  0.75, "r": 5},
            {"c": col_h, "x": -1.00, "y":  4.90, "z": -1.05, "r": 5},
            {"c": col_h, "x": -0.15, "y":  4.85, "z": -0.15, "r": 5}
        ];

        # Bonds: [atom_a, atom_b, order]
        bonds = [
            [0, 1, 1], [1, 2, 1], [2, 3, 1], [3, 4, 2], [4, 5, 1], [5, 0, 1],
            [4, 6, 1], [6, 7, 1], [7, 8, 2], [8, 3, 1],
            [1, 9, 2], [5, 10, 2],
            [0, 11, 1], [2, 12, 1], [6, 13, 1], [7, 14, 1],
            [11, 15, 1], [11, 16, 1], [11, 17, 1],
            [12, 18, 1], [12, 19, 1], [12, 20, 1],
            [13, 21, 1], [13, 22, 1], [13, 23, 1]
        ];

        target_rx = {"v": 0.0};
        target_ry = {"v": 0.0};
        rx = {"v": 0.0};
        ry = {"v": 0.0};
        auto_rot = {"v": 0.0};
        running = {"v": True};

        def rotate(p: any, ax: float, ay: float) -> any {
            cY = Math.cos(ay);
            sY = Math.sin(ay);
            x1 = p["x"] * cY + p["z"] * sY;
            y1 = p["y"];
            z1 = -p["x"] * sY + p["z"] * cY;
            cX = Math.cos(ax);
            sX = Math.sin(ax);
            x2 = x1;
            y2 = y1 * cX - z1 * sX;
            z2 = y1 * sX + z1 * cX;
            return {"x": x2, "y": y2, "z": z2};
        }

        def tick(ts: any) {
            if not running["v"] { return; }

            rx["v"] = rx["v"] + (target_rx["v"] - rx["v"]) * 0.05;
            ry["v"] = ry["v"] + (target_ry["v"] - ry["v"]) * 0.05;
            auto_rot["v"] = auto_rot["v"] + 0.0018;

            ctx.clearRect(0, 0, w["v"], h["v"]);

            # Adaptive scale based on window size; min/max clamped.
            base_scale = Math.min(w["v"], h["v"]) / 22.0;
            if base_scale < 28 { base_scale = 28; }
            if base_scale > 48 { base_scale = 48; }

            # Two instances: left and right, counter-rotating
            centers = [
                {"cx": w["v"] * 0.15, "cy": h["v"] * 0.5, "dir": 1.0, "phase": 0.0},
                {"cx": w["v"] * 0.85, "cy": h["v"] * 0.5, "dir": -1.0, "phase": Math.PI}
            ];

            ci = 0;
            while ci < len(centers) {
                center = centers[ci];
                cx = center["cx"];
                cy = center["cy"];
                dir = center["dir"];
                phase = center["phase"];

                wobble = Math.sin((ts or 0) / 3500 + phase) * 0.12;
                angle_x = rx["v"] + wobble + 0.25;
                angle_y = ry["v"] * dir + auto_rot["v"] * dir + phase;

                # Project all atoms
                projected = [];
                ai = 0;
                while ai < len(atoms) {
                    a = atoms[ai];
                    rotated = rotate(a, angle_x, angle_y);
                    persp = 600.0 / (600.0 + rotated["z"] * base_scale);
                    px = cx + rotated["x"] * base_scale * persp;
                    py = cy + (rotated["y"] - 0.6) * base_scale * persp;
                    projected.push({"px": px, "py": py, "pz": rotated["z"], "ps": persp, "a": a});
                    ai = ai + 1;
                }

                # Sort bonds by average z (back to front)
                bond_data = [];
                bi = 0;
                while bi < len(bonds) {
                    b = bonds[bi];
                    avgz = (projected[b[0]]["pz"] + projected[b[1]]["pz"]) / 2;
                    bond_data.push({"b": b, "z": avgz});
                    bi = bi + 1;
                }
                bond_data.sort(lambda x { return x["z"]; });

                bdi = 0;
                while bdi < len(bond_data) {
                    b = bond_data[bdi]["b"];
                    p1 = projected[b[0]];
                    p2 = projected[b[1]];
                    order = b[2];

                    zavg = bond_data[bdi]["z"];
                    opacity = (zavg + 4) / 8;
                    if opacity < 0.25 { opacity = 0.25; }
                    if opacity > 0.8 { opacity = 0.8; }

                    lw = 4.0 * ((p1["ps"] + p2["ps"]) / 2);
                    bond_color = "rgba(150,155,165," if is_dark else "rgba(90,95,105,";
                    ctx.strokeStyle = bond_color + str(opacity) + ")";
                    ctx.lineCap = "round";

                    if order == 1 {
                        ctx.lineWidth = lw;
                        ctx.beginPath();
                        ctx.moveTo(p1["px"], p1["py"]);
                        ctx.lineTo(p2["px"], p2["py"]);
                        ctx.stroke();
                    } else {
                        dx = p2["px"] - p1["px"];
                        dy = p2["py"] - p1["py"];
                        dist = Math.sqrt(dx * dx + dy * dy) + 0.001;
                        nx = -dy / dist * 4;
                        ny = dx / dist * 4;
                        ctx.lineWidth = lw * 0.7;
                        ctx.beginPath();
                        ctx.moveTo(p1["px"] + nx, p1["py"] + ny);
                        ctx.lineTo(p2["px"] + nx, p2["py"] + ny);
                        ctx.moveTo(p1["px"] - nx, p1["py"] - ny);
                        ctx.lineTo(p2["px"] - nx, p2["py"] - ny);
                        ctx.stroke();
                    }
                    bdi = bdi + 1;
                }

                # Sort atoms by z (back to front)
                sorted_atoms = [];
                si = 0;
                while si < len(projected) {
                    sorted_atoms.push(projected[si]);
                    si = si + 1;
                }
                sorted_atoms.sort(lambda x { return x["pz"]; });

                di = 0;
                while di < len(sorted_atoms) {
                    item = sorted_atoms[di];
                    a = item["a"];
                    r = a["r"] * item["ps"];

                    depth = (item["pz"] + 4) / 8;
                    if depth < 0.35 { depth = 0.35; }
                    if depth > 1.0 { depth = 1.0; }

                    ctx.globalAlpha = depth;

                    # Soft glow
                    g = ctx.createRadialGradient(item["px"], item["py"], 0, item["px"], item["py"], r * 1.9);
                    g.addColorStop(0, a["c"]);
                    g.addColorStop(1, "rgba(0,0,0,0)");
                    ctx.fillStyle = g;
                    ctx.beginPath();
                    ctx.arc(item["px"], item["py"], r * 1.9, 0, Math.PI * 2);
                    ctx.fill();

                    # Core atom
                    ctx.fillStyle = a["c"];
                    ctx.beginPath();
                    ctx.arc(item["px"], item["py"], r, 0, Math.PI * 2);
                    ctx.fill();

                    # Specular highlight
                    ctx.fillStyle = "rgba(255,255,255,0.38)";
                    ctx.beginPath();
                    ctx.arc(item["px"] - r * 0.3, item["py"] - r * 0.3, r * 0.35, 0, Math.PI * 2);
                    ctx.fill();

                    ctx.globalAlpha = 1.0;
                    di = di + 1;
                }
                ci = ci + 1;
            }

            requestAnimationFrame(tick);
        }
        requestAnimationFrame(tick);

        def mmove(ev: any) {
            mx = ev.clientX / w["v"] - 0.5;
            my = ev.clientY / h["v"] - 0.5;
            target_ry["v"] = -mx * 1.4;
            target_rx["v"] = -my * 1.0;
        }

        window.addEventListener("mousemove", mmove);
        window.addEventListener("resize", resize);

        return lambda {
            running["v"] = False;
            window.removeEventListener("mousemove", mmove);
            window.removeEventListener("resize", resize);
        };
    }, [is_dark]);

    return <canvas ref={canvas_ref} style={{
        "position": "fixed",
        "top": "0",
        "left": "0",
        "width": "100vw",
        "height": "100vh",
        "zIndex": "0",
        "pointerEvents": "none",
        "opacity": "0.32"
    }} />;
}
