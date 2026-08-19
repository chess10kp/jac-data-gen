"""MonoChart — single (optionally dual) line chart. Ports ui/components/shared/mono-chart.tsx.

`data`/`secondary` are list[dict] of {x, y}. `expY` formats the Y axis as an
exponent (learning-rate panel). `live` marks the last point with a ReferenceDot.
"""

import from "recharts" {
    ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ReferenceDot
}
import from ...lib.chartkit {
    tick, tipContentStyle, tipLabelStyle, tipItemStyle, tipCursor, gridStroke, axisStroke
}

def:pub MonoChart(
    title: str, data: list[dict], secondary: list[dict], live: bool, accent: str, expY: bool
) -> JsxElement {
    # merge primary (y) + secondary (y2) by x, preserving data order (x is monotonic)
    rows: list[dict] = [];
    seen: dict = {};
    for pt in data {
        row = {"x": pt["x"], "y": pt["y"]};
        seen[pt["x"]] = row;
        rows.append(row);
    }
    for pt in secondary {
        if pt["x"] in seen {
            seen[pt["x"]]["y2"] = pt["y"];
        } else {
            # insert in x-order (x is numeric + monotonic) so the line doesn't zigzag
            j = len(rows);
            while j > 0 and rows[j - 1]["x"] > pt["x"] { j -= 1; }
            rows.insert(j, {"x": pt["x"], "y2": pt["y"]});
        }
    }
    last: any = data[len(data) - 1] if len(data) > 0 else None;
    yfmt: any = (lambda v: any { return f"{v:.0e}"; }) if expY else None;

    return <div className="relative rounded-md border border-border bg-card p-3 pt-4">
        <span className="micro-label absolute -top-2 left-3 bg-background px-2">{title}</span>
        {if len(data) == 0 {
            <div key="empty" className="micro-label flex items-center justify-center" style={{"height": 180}}>NO SIGNAL</div>
            skip;
        }}
        {if len(data) > 0 {
            <ResponsiveContainer key="chart" width="100%" height={180}>
                <LineChart data={rows} margin={{"top": 10, "right": 14, "left": 0, "bottom": 0}}>
                    <CartesianGrid stroke={gridStroke()} vertical={False} />
                    <XAxis dataKey="x" tick={tick()} tickLine={False} axisLine={{"stroke": axisStroke()}} />
                    <YAxis tick={tick()} tickLine={False} axisLine={False} width={46} domain={["auto", "auto"]} tickFormatter={yfmt} />
                    <Tooltip cursor={tipCursor()} contentStyle={tipContentStyle()} labelStyle={tipLabelStyle()} itemStyle={tipItemStyle()} />
                    <Line type="monotone" dataKey="y" stroke={accent} strokeWidth={1.4} dot={False} isAnimationActive={False} />
                    {secondary and len(secondary) > 0 and <Line type="monotone" dataKey="y2" stroke={accent} strokeWidth={1.4} strokeDasharray="5 3" dot={{"r": 2}} isAnimationActive={False} connectNulls={True} />}
                    {live and last and <ReferenceDot x={last["x"]} y={last["y"]} r={3} fill="var(--background)" stroke={accent} />}
                </LineChart>
            </ResponsiveContainer>
        }}
    </div>;
}
