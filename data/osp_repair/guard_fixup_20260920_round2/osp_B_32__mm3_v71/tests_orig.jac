"""Test annex for wildlife park feeding rounds."""

import io;
import from contextlib { redirect_stdout }

test "tourist greets every animal with kiosk message" {
    root ++> Lion(name="Simba", species="lion") ++> Parrot(name="Polly", species="parrot") ++> Animal(name="Thumper", species="rabbit");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Tourist(party_name="Smith family");
    }
    out = buf.getvalue();

    assert "Welcome, Smith family party!" in out, f"missing greeting: {out}";
    assert "Kiosk: enjoy viewing Simba the lion" in out, f"missing lion greet: {out}";
    assert "Kiosk: enjoy viewing Polly the parrot" in out, f"missing parrot greet: {out}";
    assert "Kiosk: enjoy viewing Thumper the rabbit" in out, f"missing rabbit greet: {out}";
    assert out.count("Kiosk:") == 3, f"expected 3 kiosk messages, got {out.count('Kiosk:')} in {out}";
}

test "zookeeper feeds each animal species-appropriate meal" {
    root ++> Lion(name="Simba", species="lion") ++> Parrot(name="Polly", species="parrot") ++> Animal(name="Thumper", species="rabbit");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper();
    }
    out = buf.getvalue();

    assert "Zookeeper starting feeding rounds" in out, f"missing start: {out}";
    assert "Feeding Simba the lion: meat" in out, f"lion should get meat: {out}";
    assert "Feeding Polly the parrot: seed" in out, f"parrot should get seed: {out}";
    assert "Feeding Thumper the rabbit: standard feed" in out, f"rabbit should get standard feed: {out}";
}

test "school group watches but does not feed" {
    root ++> Lion(name="Simba", species="lion") ++> Parrot(name="Polly", species="parrot") ++> Animal(name="Thumper", species="rabbit");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SchoolGroup(school="Westwood Elementary");
    }
    out = buf.getvalue();

    assert "School group from Westwood Elementary arriving" in out, f"missing arrival: {out}";
    assert "Students observe Simba the lion" in out, f"missing observe lion: {out}";
    assert "Students observe Polly the parrot" in out, f"missing observe parrot: {out}";
    assert "Students observe Thumper the rabbit" in out, f"missing observe rabbit: {out}";
    assert "meat" not in out, f"school should not feed meat: {out}";
    assert "seed" not in out, f"school should not feed seed: {out}";
    assert "Feeding" not in out, f"school should not feed anything: {out}";
}

test "different visitors see same animals but produce different output" {
    root ++> Lion(name="Leo") ++> Animal(name="Bunny", species="rabbit");

    tbuf = io.StringIO();
    with redirect_stdout(tbuf) {
        res = root spawn Tourist(party_name="Jones");
    }
    tout = tbuf.getvalue();

    zbuf = io.StringIO();
    with redirect_stdout(zbuf) {
        res = root spawn Zookeeper();
    }
    zout = zbuf.getvalue();

    assert "Welcome, Jones party!" in tout, f"tourist greeting missing: {tout}";
    assert "Kiosk: enjoy viewing Leo" in tout, f"tourist sees lion: {tout}";

    assert "Zookeeper starting feeding rounds" in zout, f"zookeeper start missing: {zout}";
    assert "Feeding Leo the lion: meat" in zout, f"zookeeper feeds lion meat: {zout}";
    assert "Feeding Bunny the rabbit: standard feed" in zout, f"zookeeper feeds bunny: {zout}";

    assert "Feeding" not in tout, f"tourist should not feed: {tout}";
    assert "Kiosk" not in zout, f"zookeeper should not use kiosk msg: {zout}";
}

test "lion and parrot overrides return species-specific meals" {
    simba = Lion(name="Simba");
    polly = Parrot(name="Polly");
    thumper = Animal(name="Thumper", species="rabbit");

    assert simba.meal() == "meat", f"lion meal override failed: {simba.meal()}";
    assert polly.meal() == "seed", f"parrot meal override failed: {polly.meal()}";
    assert thumper.meal() == "standard feed", f"base animal meal failed: {thumper.meal()}";
}