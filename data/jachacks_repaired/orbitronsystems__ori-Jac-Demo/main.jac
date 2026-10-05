"""
ORBITRON ERP Platform — Main entry point.
Mounts the client app.
"""

import from .index { ClientApp }
import ".styles.global.css";

def:pub app() -> JsxElement {
    return <ClientApp />;
}
