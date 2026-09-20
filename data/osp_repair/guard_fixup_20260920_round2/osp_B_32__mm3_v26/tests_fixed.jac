"""Test annex for wildlife park feeding rounds."""

import io;
import from contextlib { redirect_stdout }

test "visitor greets kiosk and observes animals" {
    root ++> InfoKiosk(kiosk_name="Front Gate")
        ++> Lion(species="lion", name="Leo")
        ++> Parrot(species="parrot", name="Polly")
        ++> Animal(species="zebra", name="Zara");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Visitor(party="tourists");
    }
    out = buf.getvalue();

    assert "[Front Gate] Welcome to the park, tourists!" in out, f"missing kiosk greeting: {out}";
    assert "tourists watches Leo the lion." in out, f"missing Leo observation: {out}";
    assert "tourists watches Polly the parrot." in out, f"missing Polly observation: {out}";
    assert "tourists watches Zara the zebra." in out, f"missing Zara observation: {out}";
}

test "zookeeper passes kiosk and feeds species-appropriate meals" {
    root ++> InfoKiosk(kiosk_name="Front Gate")
        ++> Lion(species="lion", name="Leo")
        ++> Parrot(species="parrot", name="Polly")
        ++> Animal(species="zebra", name="Zara");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper(keeper="Alex");
    }
    out = buf.getvalue();

    assert "[Front Gate] Welcome to the park, zookeeper Alex!" in out, f"missing kiosk greeting: {out}";
    assert "Zookeeper Alex feeds Leo the lion: meat." in out, f"lion should get meat: {out}";
    assert "Zookeeper Alex feeds Polly the parrot: seed." in out, f"parrot should get seed: {out}";
    assert "Zookeeper Alex feeds Zara the zebra: standard feed." in out, f"zebra should get standard feed: {out}";
}

test "zookeeper custom keeper name appears in greeting and feeding lines" {
    root ++> InfoKiosk(kiosk_name="North Gate")
        ++> Lion(species="lion", name="Simba");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn Zookeeper(keeper="Sam");
    }
    out = buf.getvalue();

    assert "[North Gate] Welcome to the park, zookeeper Sam!" in out, f"missing kiosk greeting: {out}";
    assert "Zookeeper Sam feeds Simba the lion: meat." in out, f"missing feeding line: {out}";

    # Kiosk name must come from the node, not hard-coded.
    assert "Front Gate" not in out, f"wrong kiosk name used: {out}";
}

test "school group greets kiosk and only observes animals, no feeding" {
    root ++> InfoKiosk(kiosk_name="Front Gate")
        ++> Lion(species="lion", name="Leo")
        ++> Parrot(species="parrot", name="Polly")
        ++> Animal(species="zebra", name="Zara");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SchoolGroup(class_name="Class 3B");
    }
    out = buf.getvalue();

    assert "[Front Gate] Welcome to the park, Class 3B!" in out, f"missing kiosk greeting: {out}";
    assert "Class 3B quietly observes Leo the lion." in out, f"missing Leo watch: {out}";
    assert "Class 3B quietly observes Polly the parrot." in out, f"missing Polly watch: {out}";
    assert "Class 3B quietly observes Zara the zebra." in out, f"missing Zara watch: {out}";

    # School group must not perform any feeding action.
    assert "feeds" not in out, f"school group should not feed: {out}";
    assert "meat" not in out, f"school group should not mention meals: {out}";
    assert "seed" not in out, f"school group should not mention meals: {out}";
    assert "watches" not in out, f"school group uses 'observes', not 'watches': {out}";
}

test "polymorphic meal dispatch resolves by concrete animal type" {
    lion = Lion(species="lion", name="Leo");
    parrot = Parrot(species="parrot", name="Polly");
    generic = Animal(species="zebra", name="Zara");

    assert lion.meal() == "meat", f"lion meal wrong: {lion.meal()}";
    assert parrot.meal() == "seed", f"parrot meal wrong: {parrot.meal()}";
    assert generic.meal() == "standard feed", f"generic animal meal wrong: {generic.meal()}";
}