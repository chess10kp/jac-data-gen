"""studio - prompt library. Serves studio/prompts.json (ported from server).

Resolved relative to THIS module file (not cwd) so it works regardless of where
`jac start` is launched from — matches the old `Path(__file__).parent` behavior.
"""

import json;
import os;

def:pub list_prompts() -> dict {
    here = os.path.dirname(os.path.abspath(__file__));
    path = os.path.join(here, "prompts.json");
    try {
        with open(path) as f {
            return dict(json.load(f));
        }
    } except Exception {
        return {"categories": []};
    }
}
