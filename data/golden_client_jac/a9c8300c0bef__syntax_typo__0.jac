import json;

def parse(text: str) -> any {
    return json.loads(text);
}

obj Task { has title: str = ""; }

with entry {
    # Inferred destination -- `raw` becomes `any`, no error.
    raw = parse('{"title": "ship"}');

    # Narrow before flowing into a declared type.
    if isinstance(raw, dict) {
        title = raw.get("title", "");
        if isinstance(title, str) {
            t = Task(title=title);
            print(t.title);
        }
    }
}
