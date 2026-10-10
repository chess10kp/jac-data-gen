import from diskmap { add_folder, add_file, usage, file_count, big_files }

def tree {
    add_folder("home");
    add_folder("home/ana");
    add_folder("home/ana/photos");
    add_folder("home/bo");
    add_folder("srv");
    add_file("home", "notes.txt", 5);
    add_file("home/ana", "cv.pdf", 300);
    add_file("home/ana/photos", "a.jpg", 2000);
    add_file("home/ana/photos", "b.jpg", 1500);
    add_file("home/bo", "game.iso", 4000);
    add_file("srv", "db.bin", 9000);
}

test "folders need an existing parent and unique paths" {
    assert add_folder("home");
    assert not add_folder("home");
    assert not add_folder("var/log");
    assert add_folder("home/ana");
    assert add_file("home/ana", "x.txt", 1);
    assert not add_file("home/ana", "x.txt", 9);
    assert add_file("home", "x.txt", 9);
    assert not add_file("nope", "y.txt", 1);
}

test "usage sums the whole subtree" {
    tree();
    assert usage("home/ana/photos") == 3500;
    assert usage("home/ana") == 3800;
    assert usage("home") == 7805;
    assert usage("srv") == 9000;
    assert usage("home/bo") == 4000;
    assert usage("nope") == 0;
}

test "file counts are recursive" {
    tree();
    assert file_count("home") == 5;
    assert file_count("home/ana") == 3;
    assert file_count("srv") == 1;
    add_folder("home/ana/photos/2024");
    assert file_count("home/ana/photos/2024") == 0;
    add_file("home/ana/photos/2024", "c.jpg", 10);
    assert file_count("home/ana") == 4;
    assert usage("home") == 7815;
    assert file_count("nope") == 0;
}

test "big files report full paths, threshold inclusive" {
    tree();
    assert big_files("home", 1500) == ["home/ana/photos/a.jpg", "home/ana/photos/b.jpg", "home/bo/game.iso"];
    assert big_files("home/ana", 300) == ["home/ana/cv.pdf", "home/ana/photos/a.jpg", "home/ana/photos/b.jpg"];
    assert big_files("home", 0)[0] == "home/ana/cv.pdf";
    assert len(big_files("home", 0)) == 5;
    assert len(big_files("home/ana", 5000)) == 0;
    assert len(big_files("nope", 0)) == 0;
}
