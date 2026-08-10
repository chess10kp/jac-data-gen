"""Returns the index of element in dest, with some app.yaml awareness."""
def handler_ix(dest: list[dict[str, str]], el: dict[str, str]) -> int {
    if not isinstance(el, dict) or not "url" in el {
        try {
            return dest.index(el);
        } except ValueError {
            return -1;
        }
    }
    for (ix, existing) in enumerate(dest) {
        if (
            "url" in existing
            and existing["url"] == el["url"]
            and (
                ("static_dir" in existing and "static_dir" in el)
                or ("static_files" in existing and "static_files" in el)
            )
        ) {
            return ix;
        }
    }
    return -1;
}