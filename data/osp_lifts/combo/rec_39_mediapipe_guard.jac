"""Guard suite for rec_39_mediapipe."""
import from rec_39_mediapipe { MediaPipeline }

def fresh() -> MediaPipeline {
    m = MediaPipeline();
    m.add_folder("media");
    m.add_folder("photos", parent="media");
    m.add_folder("renders", parent="media");
    m.add_asset("orig", "photos", quality=10);
    m.derive("orig", "thumb", "renders", quality=2);
    m.derive("thumb", "sprite", "renders", quality=3);
    m.add_asset("logo", "media", quality=5);
    return m;
}

test "scores aggregate up the folder tree" {
    m = fresh();
    assert sorted([m.by_fid[f].fid for f in m.by_fid]) == ["media", "photos", "renders"];
    assert m.folder_score("photos") == 10;
    assert m.folder_score("media") == 20;
    threw_dup = False;
    try {
        m.add_folder("media");
    } except ValueError as ex {
        threw_dup = True;
    }
    assert threw_dup;
    threw_fid = False;
    try {
        m.add_asset("x", "ghost");
    } except KeyError as ex {
        threw_fid = True;
    }
    assert threw_fid;
}

test "derivative closure multiset" {
    m = fresh();
    assert m.derivatives_of("orig") == ["sprite", "thumb"];
    assert m.derivatives_of("logo") == [];
    assert m.folder_assets("media") == ["logo", "orig", "sprite", "thumb"];
    assert m.folder_assets("renders") == ["sprite", "thumb"];
    # include_sub=False restricts the census to the folder itself
    assert m.folder_assets("media", include_sub=False) == ["logo"];
    assert m.folder_assets("photos", include_sub=False) == ["orig"];
    assert m.folder_assets("renders", include_sub=False) == ["sprite", "thumb"];
}

test "derivation cycle terminates once-only" {
    m = fresh();
    m.src_of["orig"] = "sprite";  # adversarial back link
    got = m.derivatives_of("orig");
    assert len(got) == len(set(got));
    assert got == ["sprite", "thumb"];
}

test "purge cascades and recomputes each chain" {
    m = fresh();
    doomed = m.purge("orig");
    assert len(doomed) == len(set(doomed));
    assert doomed == ["orig", "sprite", "thumb"];
    assert "orig" not in m.by_aid and "thumb" not in m.by_aid;
    # per-chain adjustment: photos loses only orig (10)
    assert m.folder_score("photos") == 0;
    # media loses orig(10) via photos chain + renders assets (2+3), keeps logo(5)
    assert m.folder_score("media") == 5;
    assert m.folder_score("renders") == 0;
    assert m.folder_assets("media") == ["logo"];
}

test "purging a leaf derivative only touches its own chain" {
    m = fresh();
    doomed = m.purge("thumb");
    assert doomed == ["sprite", "thumb"];
    assert m.folder_score("photos") == 10;   # untouched
    assert m.folder_score("media") == 15;    # 20 - 2 - 3
    assert "orig" in m.by_aid;
}
