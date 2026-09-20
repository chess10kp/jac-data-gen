"""Test annex for wildlife park feeding rounds."""

import io;
import from contextlib { redirect_stdout }

test "kiosk greets zookeepers and school groups alike" {
    root ++> Kiosk(kiosk_name="Safari");
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper(badge="Z-042");
    }
    out = buf.getvalue();
    assert "Welcome to the Safari kiosk, tour party!" in out, f"zookeeper not greeted: {out}";

    buf2 = io.StringIO();
    with redirect_stdout(buf2) {
        res2 = root spawn SchoolGroup(grade=4);
    }
    out2 = buf2.getvalue();
    assert "Welcome to the Safari kiosk, tour party!" in out2, f"school group not greeted: {out2}";
}

test "zookeeper feeds each species its appropriate meal" {
    root ++> Kiosk(kiosk_name="Safari")
        ++> Lion(name="Simba", species="lion")
        ++> Parrot(name="Polly", species="parrot")
        ++> Animal(name="Gobi", species="antelope");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper(badge="Z-042");
    }
    out = buf.getvalue();
    assert "Z-042 feeds Simba the lion: meat" in out, f"lion not fed meat: {out}";
    assert "Z-042 feeds Polly the parrot: seed" in out, f"parrot not fed seed: {out}";
    assert "Z-042 feeds Gobi the antelope: standard feed" in out, f"generic animal not given default feed: {out}";
}

test "school group watches animals without feeding" {
    root ++> Kiosk(kiosk_name="Safari")
        ++> Lion(name="Simba", species="lion")
        ++> Parrot(name="Polly", species="parrot");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SchoolGroup(grade=4);
    }
    out = buf.getvalue();
    assert "Grade 4 watches Simba the lion" in out, f"lion not watched: {out}";
    assert "Grade 4 watches Polly the parrot" in out, f"parrot not watched: {out}";
    assert "meat" not in out, f"school group should not produce feeding output: {out}";
    assert "seed" not in out, f"school group should not produce feeding output: {out}";
    assert "feeds" not in out, f"school group should not use feed wording: {out}";
}

test "different zookeeper badge appears in feeding output" {
    root ++> Kiosk(kiosk_name="Reptile")
        ++> Lion(name="Leo", species="lion");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper(badge="Z-999");
    }
    out = buf.getvalue();
    assert "Z-999" in out, f"badge Z-999 missing: {out}";
    assert "Z-042" not in out, f"default badge leaked: {out}";
    assert "Welcome to the Reptile kiosk" in out, f"kiosk label missing: {out}";
}

test "kiosk with default name still greets" {
    root ++> Kiosk();
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper(badge="Z-001");
    }
    out = buf.getvalue();
    assert "Welcome to the Main kiosk, tour party!" in out, f"default kiosk name missing: {out}";
}