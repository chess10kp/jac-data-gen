"""Test annex for the wildlife park feeding rounds program."""

import io;
import from contextlib { redirect_stdout }

test "zookeeper feeds each animal its species-appropriate meal" {
    root ++> InfoKiosk(kiosk_name="Safari Info")
        ++> Lion(species="Lion", name="Simba")
        ++> Parrot(species="Parrot", name="Polly")
        ++> Animal(species="Rabbit", name="Bunny");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Zookeeper(zookeeper_name="Alex");
    }
    out = buf.getvalue();

    assert "Feeding Simba the Lion: meat" in out, f"lion should get meat: {out}";
    assert "Feeding Polly the Parrot: seed" in out, f"parrot should get seed: {out}";
    assert "Feeding Bunny the Rabbit: standard feed" in out, f"rabbit should get standard feed: {out}";
    assert "Zookeeper Alex begins feeding rounds" in out, f"missing startup line: {out}";
}

test "school group observes animals without feeding" {
    root ++> InfoKiosk(kiosk_name="Safari Info")
        ++> Lion(species="Lion", name="Simba")
        ++> Parrot(species="Parrot", name="Polly")
        ++> Animal(species="Rabbit", name="Bunny");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn SchoolGroup(group_name="Oak Elementary");
    }
    out = buf.getvalue();

    assert "Watching Simba the Lion" in out, f"missing lion observation: {out}";
    assert "Watching Polly the Parrot" in out, f"missing parrot observation: {out}";
    assert "Watching Bunny the Rabbit" in out, f"missing rabbit observation: {out}";
    assert "School group Oak Elementary is watching the animals" in out, f"missing startup line: {out}";
    assert "Feeding" not in out, f"school group must not feed: {out}";
    assert "standard feed" not in out, f"school group must not mention meals: {out}";
}

test "zookeeper does not feed when only an info kiosk exists" {
    root ++> InfoKiosk(kiosk_name="Safari Info");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Zookeeper(zookeeper_name="Alex");
    }
    out = buf.getvalue();

    assert "Feeding" not in out, f"no feeding should occur with no animals: {out}";
    assert "Zookeeper Alex begins feeding rounds" in out, f"startup should still print: {out}";
}

test "school group visits every node in the chain" {
    root ++> InfoKiosk(kiosk_name="Safari Info")
        ++> Lion(species="Lion", name="Simba")
        ++> Parrot(species="Parrot", name="Polly");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn SchoolGroup(group_name="Oak Elementary");
    }
    out = buf.getvalue();

    assert "Welcome to Safari Info!" in out, f"kiosk should greet school group: {out}";
    assert "Watching Simba the Lion" in out, f"lion should be observed: {out}";
    assert "Watching Polly the Parrot" in out, f"parrot should be observed: {out}";
}