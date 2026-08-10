"""Split `filename` into a path hierarchy, each path at most `length` characters long, and return the tuple `(paths,basename,n_subdirs)`."""
def split_filename_into_subdirs(filename: str, length: int = 3) -> tuple[str, str, int] {
    c = filename.split("/");
    if len(c) >= 2 {
        prefix = "/".join(c[:-1]) + "/";
    } else {
        prefix = "";
    }
    name = c[-1];
    c = name.split(".");
    if len(c) >= 2 {
        ext = c[-1];
        name = ".".join(c[:-1]);
    } else {
        ext = "";
    }
    l = [name[x:(x + 3)] for x in range(0, len(name), length)];
    paths = "/".join(l[:-1]);
    basename = l[-1];
    if ext {
        complete_basename = basename + "." + ext;
    } else {
        complete_basename = basename;
    }
    n_subdirs = len(l) - 1;
    if paths {
        complete_paths = prefix + paths + "/";
    } else {
        complete_paths = prefix;
    }
    return (complete_paths, complete_basename, n_subdirs);
}