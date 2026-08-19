"""MultiLineChart — N overlaid lines (one per run). Ports ui/components/shared/multi-line-chart.tsx.

`rows` is list[dict] each keyed by "x" plus one key per name in `names`.
"""

import from "recharts" {
    ResponsiveContainer, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip
}
import from ...lib.chartkit {
    tick, tipContentStyle, tipLabelStyle, tipItemStyle, tipCursor, gridStroke, axisStroke, chartColor
}

def:pub MultiLineChart(title: str, rows: list[dict], names: list[str]) -> JsxElement {
    return <div className="relative rounded-md border border-border bg-card p-3 pt-4">
        <span className="micro-label absolute -top-2 left-3 bg-background px-2">{title}</span>
        {if len(rows) == 0 {
            <div className="micro-label flex items-center justify-center" style={{"height": 180}}>NO SIGNAL</div>
            skip;
        }}
        {if len(rows) > 0 {
            <ResponsiveContainer width="100%" height={180}>
                <LineChart data={rows} margin={{"top": 10, "right": 14, "left": 0, "bottom": 0}}>
                    <CartesianGrid stroke={gridStroke()} vertical={False} />
                    <XAxis dataKey="x" tick={tick()} tickLine={False} axisLine={{"stroke": axisStroke()}} />
                    <YAxis tick={tick()} tickLine={False} axisLine={False} width={46} domain={["auto", "auto"]} />
                    <Tooltip cursor={tipCursor()} contentStyle={tipContentStyle()} labelStyle={tipLabelStyle()} itemStyle={tipItemStyle()} />
                    {for (i, name) in enumerate(names) {
                        <Line key={name} type="monotone" dataKey={name} stroke={chartColor(i)} strokeWidth={1.4} dot={False} isAnimationActive={False} connectNulls={True} />
                    }}
                </LineChart>
            </ResponsiveContainer>
            <div className="mt-2 flex flex-wrap gap-3">
                {for (i, name) in enumerate(names) {
                    <span key={name} className="stat-line" style={{"color": chartColor(i)}}>── {name}</span>
                }}
            </div>
        }}
    </div>;
}
