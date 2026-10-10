import from diskmap { Folder, File, DiskUsage, LargeFiles, ExtensionCounts }

def build -> Folder {
    home = Folder(name="home");
    docs = Folder(name="docs");
    pics = Folder(name="pics");
    trip = Folder(name="trip");
    empty = Folder(name="empty");
    home ++> docs;
    home ++> pics;
    home ++> empty;
    pics ++> trip;
    home ++> File(name=".bashrc", size=300);
    docs ++> File(name="cv.pdf", size=5000);
    docs ++> File(name="notes.TXT", size=120);
    docs ++> File(name="README", size=80);
    pics ++> File(name="cat.jpg", size=9000);
    trip ++> File(name="beach.JPG", size=9000);
    trip ++> File(name="map.tar.gz", size=40000);
    return home;
}

test "disk usage sums the subtree" {
    home = build();
    r = home spawn DiskUsage();
    assert len(r.reports) == 1;
    assert r.reports[0] == 63500;
    assert (Folder(name="nothing") spawn DiskUsage()).reports[0] == 0;
}

test "disk usage of a subfolder" {
    home = build();
    pics = [f for f in [home -->[?:Folder]] if f.name == "pics"][0];
    assert (pics spawn DiskUsage()).reports[0] == 58000;
}

test "large files with paths and ordering" {
    home = build();
    r = home spawn LargeFiles(min_size=5000);
    assert len(r.reports) == 1;
    assert r.reports[0] == ["home/pics/trip/map.tar.gz", "home/pics/cat.jpg", "home/pics/trip/beach.JPG", "home/docs/cv.pdf"];
    assert len((home spawn LargeFiles(min_size=10 ** 9)).reports[0]) == 0;
}

test "large files paths start at the spawn folder" {
    home = build();
    pics = [f for f in [home -->[?:Folder]] if f.name == "pics"][0];
    assert (pics spawn LargeFiles(min_size=1)).reports[0] == ["pics/trip/map.tar.gz", "pics/cat.jpg", "pics/trip/beach.JPG"];
}

test "extension counts" {
    home = build();
    r = home spawn ExtensionCounts();
    assert len(r.reports) == 1;
    c = r.reports[0];
    assert c["jpg"] == 2;
    assert c["pdf"] == 1;
    assert c["txt"] == 1;
    assert c["gz"] == 1;
    assert c[""] == 2;
    assert len(c) == 5;
}
