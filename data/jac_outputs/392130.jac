def sort_keys_by_cnt(misclfds: dict[str, list[object]]) -> list[str] {
    cnts = [[misclf_key, len(misclfds[misclf_key])] for misclf_key in misclfds];
    return [v[0] as str for v in sorted(cnts, key=lambda (v: list[object]) { v[1] as int; }, reverse=True)];
}