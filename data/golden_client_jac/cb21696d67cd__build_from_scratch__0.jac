with entry {
    cells = {};
    for ln in Path(path).read_text().split("\n") {
        rec = json.loads(ln);
        (rung, model, cond, kind) = tuple(rec["tag"].split("/"));
        cells[model + "|" + rung + "|" + cond] = rec;
    }
    for k in sorted(cells.keys()) {
        print("| " + k + " | ... |");
    }
}
