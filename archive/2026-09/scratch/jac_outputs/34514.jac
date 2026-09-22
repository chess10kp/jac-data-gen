"""
    Create the gitBOM doc text contents
    :param infiles: the list of checksum for input files
    :param db: gitBOM DB with {file-hash => its gitBOM hash} mapping
    """
def create_gitbom_doc_text(infiles: list[str], db: dict[str, str]) -> str {
    if not infiles {
        return '';
    }
    lines = [];
    for ahash in infiles {
        line = "blob " + ahash;
        if ahash in db {
            gitbom_hash = db[ahash];
            line += " bom " + gitbom_hash;
        }
        lines.append(line);
    }
    lines.sort();
    return '\n'.join(lines) + '\n';
}