"""GHOST BOARD — Client UI.

Porting the React components into Jac codespace.
"""

import from "react" { useEffect }
import from .models { Executive, SystemMetrics, ExecutiveStatus }
import from .server { get_executives, get_system_metrics, trigger_orchestration }

# -----------------------------------------------------------------------------
# UI Components
# -----------------------------------------------------------------------------

def:pub ExecutiveCard(exec: Executive) -> JsxElement {
    # Color mapping
    color_classes: dict[any, any] = {
        "white":  "text-white border-white bg-white/10",
        "cyan":   "text-cyan-400 border-cyan-400 bg-cyan-400/10",
        "violet": "text-violet-400 border-violet-400 bg-violet-400/10",
        "green":  "text-emerald-400 border-emerald-400 bg-emerald-400/10",
        "orange": "text-orange-400 border-orange-400 bg-orange-400/10",
        "red":    "text-red-400 border-red-400 bg-red-400/10"
    };

    c = color_classes.get(exec.color) or color_classes["white"];

    return <div className={f"p-4 rounded-xl border-2 backdrop-blur-md transition-all {c}"}>
        <div className="flex items-start gap-4">
            <div className={f"w-14 h-14 rounded-lg border-2 overflow-hidden bg-black/40 {('animate-pulse' if exec.is_thinking else '')}"}>
                <img src={f"/{exec.id}_ai.png"} alt={exec.name} className="object-cover" />
            </div>
            <div className="flex-1">
                <div className="flex justify-between items-center">
                    <h3 className="font-black text-lg uppercase">{exec.name}</h3>
                    <span className="text-[10px] font-mono px-1 border border-current rounded">{exec.status}</span>
                </div>
                <div className="text-[10px] opacity-60 font-mono tracking-widest">{exec.role}</div>
            </div>
        </div>

        <div className="mt-4 p-2 bg-black/40 rounded border border-white/5 h-12 overflow-hidden">
            <p className="text-[10px] font-mono italic text-gray-400">
                {("REASONING..." if exec.is_thinking else exec.reasoning)}
            </p>
        </div>

        <div className="mt-4 space-y-2">
            <div className="flex justify-between text-[10px] font-mono">
                <span>CONFIDENCE</span>
                <span>{f"{exec.confidence:.1f}"}%</span>
            </div>
            <div className="h-1 bg-white/5 rounded-full overflow-hidden">
                <div className="h-full bg-current transition-all" style={{"width": f"{exec.confidence}%"}}></div>
            </div>
        </div>
    </div>;
}

def:pub CommandCenter() -> JsxElement {
    has executives: list[Executive] = [];
    has metrics: SystemMetrics | None = None;
    has crisis_input: str = "";

    async def poll() {
        executives = await get_executives();
        metrics = await get_system_metrics();
    }

    # Polling logic
    async can with entry {
        await poll();
    }

    can with entry {
        useEffect(lambda {
            interval = setInterval(lambda { poll(); }, 5000);
            return lambda { clearInterval(interval); };
        }, []);
    }

    async def handle_orchestrate(e: MouseEvent) {
        if crisis_input.strip() {
            await trigger_orchestration(crisis_msg=crisis_input);
            crisis_input = "";
        }
    }

    return <div className="min-h-screen bg-black text-white font-sans selection:bg-primary selection:text-black">
        <header className="h-16 border-b border-white/10 flex items-center justify-between px-10 bg-black/50 backdrop-blur-md sticky top-0 z-50">
            <div className="flex items-center gap-4">
                <div className="w-10 h-10 bg-primary/20 border border-primary/50 rounded-lg flex items-center justify-center">
                    <span className="text-primary font-black">GB</span>
                </div>
                <div>
                    <h1 className="text-xl font-black tracking-tighter">GHOST BOARD</h1>
                    <div className="text-[10px] text-gray-500 font-mono">SYSTEM_v4.0.2 // ACTIVE</div>
                </div>
            </div>

            <div className="flex gap-8">
                <div className="flex flex-col items-end">
                    <span className="text-[9px] text-gray-500 uppercase">System Load</span>
                    <span className="text-sm font-black text-cyan-400">{f"{metrics.system_load:.1f}" if metrics else ""}%</span>
                </div>
                <div className="flex flex-col items-end">
                    <span className="text-[9px] text-gray-500 uppercase">Latency</span>
                    <span className="text-sm font-black text-violet-400">{metrics.net_latency if metrics else ""}ms</span>
                </div>
            </div>
        </header>

        <main className="p-8 max-w-7xl mx-auto space-y-8">
            <div className="p-6 bg-white/5 border border-white/10 rounded-2xl backdrop-blur-xl">
                <h2 className="text-xs font-black tracking-[0.3em] text-primary mb-4 uppercase">Crisis Orchestration</h2>
                <div className="flex gap-4">
                    <input
                        type="text"
                        value={crisis_input}
                        onInput={lambda (e: InputEvent) { crisis_input = e.target.value; }}
                        placeholder="DEPLOY_CRISIS_PROTOCOL_INPUT..."
                        className="flex-1 bg-black/40 border border-white/10 rounded-lg px-4 py-3 font-mono text-sm focus:border-primary outline-none"
                    />
                    <button
                        onClick={handle_orchestrate}
                        className="px-8 py-3 bg-primary text-black font-black rounded-lg hover:scale-105 transition-transform"
                    >
                        EXECUTE
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {for exec in executives { <ExecutiveCard key={exec.id} exec={exec} /> }}
            </div>
        </main>

        <footer className="p-10 border-t border-white/5 text-center text-[10px] text-gray-600 font-mono">
            NEURAL_PROCESSING_ACTIVE // {new(Date).toISOString()} // GB_OS
        </footer>
    </div>;
}
