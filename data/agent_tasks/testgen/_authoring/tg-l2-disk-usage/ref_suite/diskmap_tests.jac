import from diskmap { Folder, File, DiskUsage, LargeFiles, ExtensionCounts, extension_of }

def tree -> Folder {
    top = Folder(name="top");
    src = Folder(name="src");
    lib = Folder(name="lib");
    bare = Folder(name="bare");
    top ++> src;
    top ++> bare;
    src ++> lib;
    top ++> File(name="Makefile", size=10);
    top ++> File(name=".env", size=5);
    src ++> File(name="main.c", size=700);
    src ++> File(name="util.c", size=700);
    src ++> File(name="NOTES.Md", size=50);
    lib ++> File(name="core.tar.GZ", size=2000);
    lib ++> File(name="z.c", size=1);
    return top;
}

def sub(f: Folder, name: str) -> Folder {
    return [x for x in [f -->[?:Folder]] if x.name == name][0];
}

test "extension_of rules" {
    assert extension_of("a.txt") == "txt";
    assert extension_of("A.TXT") == "txt";
    assert extension_of("archive.tar.gz") == "gz";
    assert extension_of("README") == "";
    assert extension_of(".bashrc") == "";
    assert extension_of(".config.json") == "json";
    assert extension_of("..x") == "";
}

test "total size of the whole tree" {
    w = tree() spawn DiskUsage();
    assert len(w.reports) == 1;
    assert w.reports[0] == 3466;
    assert w.total == 3466;
}

test "size of a subfolder and of an empty folder" {
    t = tree();
    assert (sub(t, "src") spawn DiskUsage()).reports[0] == 3451;
    assert (sub(sub(t, "src"), "lib") spawn DiskUsage()).reports[0] == 2001;
    assert (sub(t, "bare") spawn DiskUsage()).reports[0] == 0;
}

test "large files ordered by size desc then path" {
    w = tree() spawn LargeFiles(min_size=50);
    assert len(w.reports) == 1;
    assert list(w.reports[0]) == ["top/src/lib/core.tar.GZ", "top/src/main.c", "top/src/util.c", "top/src/NOTES.Md"];
}

test "min_size is inclusive and defaults to everything" {
    t = tree();
    assert list((t spawn LargeFiles(min_size=700)).reports[0]) == ["top/src/lib/core.tar.GZ", "top/src/main.c", "top/src/util.c"];
    assert list((t spawn LargeFiles(min_size=701)).reports[0]) == ["top/src/lib/core.tar.GZ"];
    assert len((t spawn LargeFiles()).reports[0]) == 7;
    assert len((t spawn LargeFiles(min_size=5000)).reports[0]) == 0;
}

test "paths are relative to the spawn folder" {
    t = tree();
    assert list((sub(t, "src") spawn LargeFiles(min_size=1000)).reports[0]) == ["src/lib/core.tar.GZ"];
    assert list((sub(sub(t, "src"), "lib") spawn LargeFiles()).reports[0]) == ["lib/core.tar.GZ", "lib/z.c"];
}

test "extension counts across the tree" {
    w = tree() spawn ExtensionCounts();
    assert len(w.reports) == 1;
    c = w.reports[0];
    assert c["c"] == 3;
    assert c["md"] == 1;
    assert c["gz"] == 1;
    assert c[""] == 2;
    assert len(c) == 4;
}

test "extension counts of an empty folder" {
    assert len((Folder(name="x") spawn ExtensionCounts()).reports[0]) == 0;
}
