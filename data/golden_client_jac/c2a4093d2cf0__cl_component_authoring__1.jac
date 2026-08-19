"""studio - client entry. Mounts the app shell (nav rail + sections)."""

import from .components.AppShell { AppShell }

def:pub app -> JsxElement {
    return <AppShell />;
}
