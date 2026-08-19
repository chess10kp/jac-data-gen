import json;

obj Task { has title: str = ""; }

def parse(text: str) -> any {
    return json.loads(text);
}

def to_task(raw: any) -> Task | None {
    if isinstance(raw, dict) {
        title = raw.get("title", "");
        if isinstance(title, str) {
            return Task(title=title);
        }
    }
    return None;
}

with entry {
    raw = parse('{"title": "ship"}');
    t = to_task(raw);
    if t is not None {
        print(t.title);
    }
}
