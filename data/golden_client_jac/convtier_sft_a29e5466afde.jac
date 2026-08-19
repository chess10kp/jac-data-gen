def capture_summary(results: list) -> str {
    oks = len([r for r in results if r["status"] == "ok"]);
    skips = len([r for r in results if r["status"] == "skip"]);
    fails = len(results) - oks - skips;
    code = 0 if oks > 0 else 1;
    return f"{oks} ok / {skips} skip / {fails} fail -> exit {code}";
}

with entry {
    print(capture_summary([{'status': 'ok'}, {'status': 'skip'}, {'status': 'fail'}]));
}
