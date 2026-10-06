"""Jac-authored Electron preload bridge runtime."""

import from 'electron' { contextBridge, ipcRenderer }

"""R: Expose the Electron IPC bridge to the renderer bundle.
M: Publishes a narrow `window.browserAPI` surface backed by `ipcRenderer.invoke`.
E: Keeps the API stable even while the renderer implementation moves from JS to Jac.
"""
def:pub installPreloadBridge() -> None {
    contextBridge.exposeInMainWorld("browserAPI", {
        "getHomeUrl": lambda { return ipcRenderer.invoke("browser:get-home-url"); },
        "normalizeUrl": lambda (rawInput: any) { return ipcRenderer.invoke("browser:normalize-url", rawInput); },
        "getWebviewPreloadUrl": lambda { return ipcRenderer.invoke("browser:get-webview-preload-url"); },
        "getLlmStatus": lambda { return ipcRenderer.invoke("browser:get-llm-status"); },
        "minimizeWindow": lambda { return ipcRenderer.invoke("window:minimize"); },
        "toggleMaximizeWindow": lambda { return ipcRenderer.invoke("window:toggle-maximize"); },
        "closeWindow": lambda { return ipcRenderer.invoke("window:close"); },
        "layersStart": lambda (payload: any) { return ipcRenderer.invoke("layers:start", payload); },
        "layersEvent": lambda (payload: any) { return ipcRenderer.invoke("layers:event", payload); },
        "layersStop": lambda (payload: any) { return ipcRenderer.invoke("layers:stop", payload); },
        "layersGetTrace": lambda (payload: any) { return ipcRenderer.invoke("layers:get-trace", payload); },
        "layersCompile": lambda (payload: any) { return ipcRenderer.invoke("layers:compile", payload); },
        "layersPlan": lambda (payload: any) { return ipcRenderer.invoke("layers:plan", payload); },
        "helpersCreate": lambda (payload: any) { return ipcRenderer.invoke("helpers:create", payload); },
        "helpersList": lambda (payload: any) { return ipcRenderer.invoke("helpers:list", payload); },
        "helpersGet": lambda (payload: any) { return ipcRenderer.invoke("helpers:get", payload); },
        "helpersRunOnce": lambda (payload: any) { return ipcRenderer.invoke("helpers:run-once", payload); },
        "helperRunsList": lambda (payload: any) { return ipcRenderer.invoke("helpers:list-runs", payload); },
        "helperRunGet": lambda (payload: any) { return ipcRenderer.invoke("helpers:get-run", payload); }
    });
}
