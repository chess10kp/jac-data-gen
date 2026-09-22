"""
Takes gallery tags and converts it to string, returns string
if simple is set to True, returns a CSV string, else a dict-like string
"""
def tag_to_string(gallery_tag: dict[str, list[str]], simple: bool = False) -> str {
    assert isinstance(gallery_tag, dict), "Please provide a dict like this: {'namespace':['tag1']}";
    string = "";
    if not simple {
        for (n, namespace) in enumerate(sorted(gallery_tag), 1) {
            if len(gallery_tag[namespace]) != 0 {
                if namespace != 'default' {
                    string += namespace + ":";
                }
                if namespace != 'default' and len(gallery_tag[namespace]) > 1 {
                    string += '[';
                }
                for (x, tag) in enumerate(sorted(gallery_tag[namespace]), 1) {
                    if x == len(gallery_tag[namespace]) {
                        string += tag;
                    } else {
                        string += tag + ', ';
                    }
                }
                if namespace != 'default' and len(gallery_tag[namespace]) > 1 {
                    string += ']';
                }
                if n != len(gallery_tag) {
                    string += ', ';
                }
            }
        }
    } else {
        for (n, namespace) in enumerate(sorted(gallery_tag), 1) {
            if len(gallery_tag[namespace]) != 0 {
                if namespace != 'default' {
                    string += namespace + ",";
                }
                for (x, tag) in enumerate(sorted(gallery_tag[namespace]), 1) {
                    if x == len(gallery_tag[namespace]) {
                        string += tag;
                    } else {
                        string += tag + ', ';
                    }
                }
                if n != len(gallery_tag) {
                    string += ', ';
                }
            }
        }
    }
    return string;
}