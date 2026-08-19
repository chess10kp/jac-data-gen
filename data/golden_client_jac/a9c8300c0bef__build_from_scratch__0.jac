import json;

def parse(text: str) -> any {
    return json.loads(text);
}

obj Task { has title: str = ""; }
