"""app.jac — entry point for the Jac-native single-page frontend.

The real UI lives in frontend.jac. This file exists for two reasons:

  1. `jac start` doesn't accept a `.cl.jac` file as a server entry
     point directly (jaclang treats the dotted name as a Python
     sub-module path and refuses to import it). The entry must be a
     plain `.jac` file that pulls in the client component.

  2. The walker imports here are what tell the runtime's introspector
     that `submit_claim` and `list_appeals` are `walker:pub` and
     therefore should NOT be gated behind the default Bearer-token
     auth.

Run it:

    jac start app.jac

Then open http://localhost:8000 (default port) in a browser. The page
loads the Jac-compiled React bundle, which spawns the walkers via the
in-browser jac-client runtime — no hand-written fetch() anywhere.
"""

# Top-level imports so the introspector picks up `walker:pub`.
import from walkers { submit_claim, list_appeals }

# Client-side: mount the React component from frontend.jac.
import from .frontend { app as FrontendApp }

def:pub app -> JsxElement {
    return <FrontendApp/>;
}
