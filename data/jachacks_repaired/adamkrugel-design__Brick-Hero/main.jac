import from services.recognition { recognize_lego_frame, get_llm_color }

import ".styles.global.css";
import from .components.countdownApp { CountdownApp }

def:pub app() -> JsxElement {
    return <main className="min-h-screen bg-background px-6 py-10 text-foreground">
        <CountdownApp />
    </main>;
}
