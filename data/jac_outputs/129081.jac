"""Load score files and return a list of (neg, pos) tuples."""
def load_files(
    filenames: list[str] | None,
    func_load: Callable[[str], tuple[object, object]]
) -> list[tuple[object, object]] | None {
    if filenames is None {
        return None;
    }
    res = [];
    for filepath in filenames {
        try {
            res.append(func_load(filepath));
        } except Exception as e {
            raise;
        }
    }
    return res;
}