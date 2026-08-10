"""Remove base64-encoded string if "path" is preserved in example."""
def remove_base64(examples: list[dict[str, str]]) -> list[dict[str, str]] {
    for eg in examples {
        if "audio" in eg and eg["audio"].startswith("data:") and "path" in eg {
            eg["audio"] = eg["path"];
        }
        if "video" in eg and eg["video"].startswith("data:") and "path" in eg {
            eg["video"] = eg["path"];
        }
    }
    return examples;
}