"""Jac client entry point for the browser shell migration."""

import ".styles.css";
import from .components.BrowserShell { BrowserShell }


"""R: Mount the Jac-authored browser shell.
    M: Returns the top-level Electron browser shell component.
    E: Keeps the root thin so runtime behavior lives in focused Jac modules.
    """
def:pub app() -> JsxElement {
    return <BrowserShell/>;
}
