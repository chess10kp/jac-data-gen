"""Returns dictionary-record for from history_list_of_dicts."""
def history_dict_for_file(listdicts: list[dict[str, object]] | None, fname: str) -> dict[str, object] | None {
    if listdicts is None {
        return None;
    }
    for d in listdicts {
        v = d.get('file', None);
        if v == None {
            continue;
        }
        if v == fname {
            return d;
        }
    }
    return None;
}