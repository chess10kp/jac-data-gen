"""Test annex for wildlife park feeding rounds."""

import io;
import from contextlib { redirect_stdout }

# --- Test 1: InfoKiosk greets every animal regardless of species ---

test "kiosk greets every enclosure" {
    root ++> Lion(species="lion", name="Simba")
           ++> Parrot(species="parrot", name="Polly")
           ++> Animal(species="tortoise", name="Gopher");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn InfoKiosk();
    }
    out = buf.getvalue();

    assert "welcome to the wildlife park!" in out, f"missing kiosk welcome: {out}";
    assert "Kiosk greets party at Simba's enclosure." in out, f"missing Simba greeting: {out}";
    assert "Kiosk greets party at Polly's enclosure." in out, f"missing Polly greeting: {out}";
    assert "Kiosk greets party at Gopher's enclosure." in out, f"missing Gopher greeting: {out}";
}

# --- Test 2: Zookeeper feeds each animal its species-appropriate meal ---

test "zookeeper feeds species-appropriate meals" {
    simba = Lion(species="lion", name="Simba");
    polly = Parrot(species="parrot", name="Polly");
    gopher = Animal(species="tortoise", name="Gopher");
    root ++> simba ++> polly ++> gopher;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Zookeeper(keeper_name="Alex");
    }
    out = buf.getvalue();

    assert "Zookeeper Alex begins the feeding round." in out, f"missing zookeeper start: {out}";
    assert "Simba the lion tears into a fresh steak." in out, f"lion should get steak: {out}";
    assert "Polly the parrot cracks seed mix." in out, f"parrot should get seed mix: {out}";
    assert "Gopher the tortoise eats standard feed." in out, f"other animal should get standard feed: {out}";
    assert simba.fed, "Simba should be marked fed";
    assert polly.fed, "Polly should be marked fed";
    assert gopher.fed, "Gopher should be marked fed";
}

# --- Test 3: School group observes without feeding ---

test "school group observes and notes fed state" {
    simba = Lion(species="lion", name="Simba");
    polly = Parrot(species="parrot", name="Polly");
    gopher = Animal(species="tortoise", name="Gopher");
    root ++> simba ++> polly ++> gopher;

    # Pre-feed so school group sees "(just fed!)" markers.
    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Zookeeper(keeper_name="Alex");
    }
    simba_buf = buf.getvalue();
    assert "tears into a fresh steak" in simba_buf, "pre-feed zookeeper step failed";

    buf2 = io.StringIO();
    with redirect_stdout(buf2) {
        root spawn SchoolGroup(students=24);
    }
    out = buf2.getvalue();

    assert "School group of 24 students arrives to watch." in out, f"missing school group intro: {out}";
    assert "Students watch Simba the lion (just fed!)." in out, f"Simba should show fed marker: {out}";
    assert "Students watch Polly the parrot (just fed!)." in out, f"Polly should show fed marker: {out}";
    assert "Students watch Gopher the tortoise (just fed!)." in out, f"Gopher should show fed marker: {out}";
}

# --- Test 4: School group sees "(waiting for feeding)" before any feeding ---

test "school group sees unfed animals when arriving first" {
    root ++> Lion(species="lion", name="Simba")
           ++> Parrot(species="parrot", name="Polly");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn SchoolGroup(students=10);
    }
    out = buf.getvalue();

    assert "Students watch Simba the lion (waiting for feeding)." in out, f"Simba should be unfed: {out}";
    assert "Students watch Polly the parrot (waiting for feeding)." in out, f"Polly should be unfed: {out}";
}

# --- Test 5: Kiosk walks the full chain and visits every animal ---

test "kiosk traversal covers all reachable animals" {
    root ++> Lion(species="lion", name="Leo")
           ++> Parrot(species="parrot", name="Kiwi")
           ++> Animal(species="giraffe", name="Gigi");

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn InfoKiosk();
    }
    out = buf.getvalue();

    # Three enclosures must each get a greeting line.
    greets = [l for l in out.splitlines() if "Kiosk greets party at" in l];
    assert len(greets) == 3, f"expected 3 greetings, got {len(greets)}: {out}";
    assert "Leo" in greets[0], f"first greeting should mention Leo: {greets}";
}