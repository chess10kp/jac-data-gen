"""Bug-injection specs for the `debug` agent-task kind (consumed by debug_build.py).

Each spec: id, src (validated source task, <kind>/<id>), level, bugs (each a list
of exact old->new edits against the source reference, applied in order), request
(the bug report the agent sees - symptom only, never the location), optional
repro (a visible failing test shipped in starter/), optional extra_tests
(appended to the source's hidden tests), notes (hidden).

Levels 1-3 carry one bug; levels 4-5 carry two bugs, each independently killed by
the hidden tests (so a fix of only one of them still fails).
"""
from __future__ import annotations


def E(file: str, old: str, new: str) -> dict:
    return {"file": file, "old": old, "new": new}


def B(cls: str, why: str, *edits: dict) -> dict:
    return {"cls": cls, "why": why, "edits": list(edits)}


def R(content: str) -> dict:
    """A visible reproduction: `jac test repro_test.jac` fails on the starter."""
    return {"kind": "test", "file": "repro_test.jac", "content": content}


HTTP_HELPERS = '''import tempfile;
import from jaclang.testing.testing { JacTestClient }

def open_client -> JacTestClient {
    c = JacTestClient.from_file("app.jac", base_path=tempfile.mkdtemp());
    c.register_user("repro", "password123");
    return c;
}

def walk(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/walker/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["reports"][0];
}

def fn(c: JacTestClient, name: str, body: dict[str, any]) -> any {
    resp = c.post("/function/" + name, json=body);
    assert resp.status_code == 200, f"{name}: {resp.status_code} {resp.text}";
    return resp.json()["data"]["result"];
}
'''

SPECS: list[dict] = [
    # ------------------------------------------------------------------ L1
    dict(
        id="dbg-l1-apiary-healthy-flagged", src="native/nat-l1-apiary-requeen", level=1,
        bugs=[B("boolean-logic", "negation applied to the whole conjunction instead of queen_seen only",
                E("apiary.jac", "queenless_and_weak = not here.queen_seen and here.brood_frames < 3;",
                  "queenless_and_weak = not (here.queen_seen and here.brood_frames < 3);"))],
        request="""
The requeen audit (`RequeenAudit` in apiary.jac) has started telling us to requeen colonies that are obviously fine. Yesterday it flagged `hill-3`: laying queen seen, nine frames of brood, temper 2. That hive is the strongest one we have.

The rule we agreed on: a hive gets flagged if it is queenless (no queen seen) AND weak (fewer than 3 brood frames), OR if its temper is 4 or more. Everything else should stay off the list. Can you find out why healthy hives are being flagged and fix it?
""",
        repro=R('''import from apiary { add_hive, RequeenAudit }

test "strong queenright calm hive is not flagged" {
    add_hive("hill-3", 9, True, 2);
    add_hive("hill-7", 1, False, 1);
    w = root spawn RequeenAudit();
    assert w.reports[0] == ["hill-7"];
}
'''),
    ),
    dict(
        id="dbg-l1-apiary-nucs-audited", src="native/nat-l1-apiary-requeen", level=1,
        bugs=[B("traversal-depth", "the Hive ability keeps visiting outgoing Hive nodes, so nucleus hives hung off a hive get audited",
                E("apiary.jac", "        self.checked += 1;\n", "        self.checked += 1;\n        visit [-->[?:Hive]];\n"))],
        request="""
Weird numbers from the requeen audit. We have 4 colonies in the home yard, and two of them have a nucleus hive (a nuc) recorded as hanging off the parent hive rather than off the apiary root. The audit says `checked == 6` and it lists one of the nucs as needing a new queen — which it doesn't, nucs are queenless on purpose while they raise one.

Only the colonies attached directly to the apiary should be audited. Please fix the audit; don't change how we store the nucs.
""",
    ),
    dict(
        id="dbg-l1-lighthouse-hours-lost", src="native/nat-l1-lighthouse-lamps", level=1,
        bugs=[B("persistence-local-copy", "burn time is accumulated into a local variable and never written back to the Lamp node",
                E("keepers.jac", "        here.burn_hours += self.hours * factor;\n        if here.burn_hours >= 0.9 * here.rated_hours {",
                  "        total = here.burn_hours + self.hours * factor;\n        if total >= 0.9 * here.rated_hours {"))],
        request="""
The keepers say the burn-hours counter on the lamps never goes up. We run `NightShift` every night and the Gull Point lamp has shown the same `burn_hours` for a week. Oddly the due-for-bulb-change list still seems to work for a lamp that is already close to the limit, so the walker is clearly running.

Lamp burn hours must accumulate night after night on the lamp itself (first-order lenses wear 1.5x as fast). Could you track this down?
""",
        repro=R('''import from keepers { Lens, Lamp, add_lamp, NightShift }

test "burn hours accumulate across nights" {
    add_lamp("gull-point", Lens.SECOND_ORDER, 0.0, 1000.0, True);
    root spawn NightShift(hours=7.5);
    root spawn NightShift(hours=7.5);
    lamp = [root -->[?:Lamp, station == "gull-point"]][0];
    assert lamp.burn_hours == 15.0;
}
'''),
    ),
    dict(
        id="dbg-l1-lighthouse-due-late", src="native/nat-l1-lighthouse-lamps", level=1,
        bugs=[B("statement-order", "due check runs before tonight's hours are added, so lamps appear one night late",
                E("keepers.jac", "        here.burn_hours += self.hours * factor;\n        if here.burn_hours >= 0.9 * here.rated_hours {\n            self.due.append(here.station);\n        }\n",
                  "        if here.burn_hours >= 0.9 * here.rated_hours {\n            self.due.append(here.station);\n        }\n        here.burn_hours += self.hours * factor;\n"))],
        request="""
Lamps are showing up on the bulb-change list a night late. Example: a lamp rated 1000 h sitting at 890 h, after a 10-hour night it is at 900 h (90%) — it should be on that night's due list, but it only appears the following night. The hour totals themselves look right.

Please fix it so a lamp is reported as due on the night it reaches 90% of its rated hours.
""",
    ),
    dict(
        id="dbg-l1-choir-or-and", src="native/nat-l1-choir-sections", level=1,
        bugs=[B("boolean-logic", "`and` replaced by `or` in the eligibility condition",
                E("choir.jac", "if here.active and here.rehearsals >= 2 {", "if here.active or here.rehearsals >= 2 {"))],
        request="""
The section check is overcounting. Our alto section shows 6 even though only 3 altos actually made it to two or more rehearsals this cycle — it looks like everybody active is being counted, plus people who left the choir but still have old attendance on their record.

A singer should only count for their part if they are active AND attended at least 2 rehearsals. Can you fix `SectionCheck`?
""",
        repro=R('''import from choir { Part, enrol, SectionCheck }

test "only active singers with two rehearsals count" {
    enrol("eve", Part.ALTO, 1);
    s = enrol("old", Part.ALTO, 5);
    s.active = False;
    enrol("fay", Part.ALTO, 2);
    w = root spawn SectionCheck(minimum=1);
    assert w.reports[0]["ALTO"] == 1;
}
'''),
    ),
    dict(
        id="dbg-l1-choir-minimum-inclusive", src="native/nat-l1-choir-sections", level=1,
        bugs=[B("off-by-one", "short list uses <= minimum instead of < minimum",
                E("choir.jac", "if self.counts[p.name] < self.minimum {", "if self.counts[p.name] <= self.minimum {"))],
        request="""
`SectionCheck(minimum=3)` lists SOPRANO as short, but we have exactly three eligible sopranos. Three is the minimum, so that section is fine — a part is only short when it has fewer than the minimum. The counts dictionary it reports is correct, it's just the `short` list that's wrong.
""",
    ),
    dict(
        id="dbg-l1-kiln-yield-rounding", src="native/nat-l1-kiln-cone-yield", level=1,
        bugs=[B("numeric-rounding", "yield is rounded instead of floored",
                E("kiln.jac", "s.yield_pct = (s.pieces - s.losses) * 100 // s.pieces;",
                  "s.yield_pct = round((s.pieces - s.losses) * 100 / s.pieces);"))],
        request="""
Small thing but the studio manager noticed: for cone 6 this month we fired 15 pieces and lost 2, and the yield report says 87%. Our convention (and the old spreadsheet) always rounds the percentage DOWN to a whole number, so it should be 86%. Other cones look plausible but I suspect they're affected too. Can you fix `ConeYield`?
""",
        repro=R('''import from kiln { log_firing, ConeYield }

test "yield percentage is rounded down" {
    log_firing("b1", 6, 10, 1, 1);
    log_firing("b2", 6, 5, 0, 0);
    stats = (root spawn ConeYield()).reports[0];
    assert stats[0].yield_pct == 86;
}
'''),
    ),
    dict(
        id="dbg-l1-kiln-totals-reset", src="native/nat-l1-kiln-cone-yield", level=1,
        bugs=[B("accumulator-reset", "the per-cone stat is re-created for every firing, discarding earlier loads",
                E("kiln.jac", "        if here.cone not in self.totals {\n            self.totals[here.cone] = ConeStat(cone=here.cone, pieces=0, losses=0, yield_pct=0);\n        }\n",
                  "        self.totals[here.cone] = ConeStat(cone=here.cone, pieces=0, losses=0, yield_pct=0);\n"))],
        request="""
The cone yield report only ever seems to reflect one kiln load per cone. We had three cone-6 firings this week (10, 12 and 8 pieces) and the report says cone 6: 8 pieces. The totals for each cone should add up every non-aborted firing at that cone.
""",
    ),
    dict(
        id="dbg-l1-seedvault-age-boundary", src="native/nat-l1-seed-vault-regrow", level=1,
        bugs=[B("off-by-one", "age rule uses > 10 instead of >= 10",
                E("vault.jac", "self.year - here.banked_year >= 10", "self.year - here.banked_year > 10"))],
        request="""
Running `RegrowPlan(year=2026)` doesn't include our 2016 wheat accessions even though they're due: anything that has been in the bank for ten years or more must be regrown. The 2015 lots do show up. Germination and low-stock lots look correct.
""",
        repro=R('''import from vault { bank_lot, RegrowPlan }

test "lot banked exactly ten years ago is due" {
    bank_lot("W-2016", "wheat", 2016, 95, 800);
    w = root spawn RegrowPlan(year=2026);
    assert w.reports[0] == {"wheat": ["W-2016"]};
}
'''),
    ),
    dict(
        id="dbg-l1-seedvault-examined-retired", src="native/nat-l1-seed-vault-regrow", level=1,
        bugs=[B("statement-order", "examined counter incremented before the retired-lot early return",
                E("vault.jac", "        if here.retired {\n            return;\n        }\n        self.examined += 1;\n",
                  "        self.examined += 1;\n        if here.retired {\n            return;\n        }\n"))],
        request="""
The `examined` number on the regrow plan doesn't match what the curators expect. We have 140 accessions, 25 of them retired, and the plan says it examined 140. Retired lots are skipped by the plan (correctly — none of them appear in it) and they shouldn't be counted as examined either.
""",
    ),
    # ------------------------------------------------------------------ L2
    dict(
        id="dbg-l2-family-half-siblings", src="native/nat-l2-family-cousins", level=2,
        bugs=[B("wrong-predicate", "only full siblings are excluded; a half-sibling (one shared parent) is reported as a cousin",
                E("family.jac", "            if not shared {", "            if len(shared) < len(parents) {"))],
        request="""
Bug in the family tree app: when I run `Cousins` on myself it lists my half-brother. We share a dad but have different mums, so he's my sibling, not my cousin. Real cousins on both sides seem fine. Anyone who shares at least one parent with me must not appear as a cousin.
""",
        repro=R('''import from family { child_of, Cousins }

test "half sibling is not a cousin" {
    gp = child_of("gp", []);
    dad = child_of("dad", [gp]);
    aunt = child_of("aunt", [gp]);
    mum = child_of("mum", []);
    step = child_of("step", []);
    me = child_of("me", [dad, mum]);
    half = child_of("half", [dad, step]);
    cuz = child_of("cuz", [aunt]);
    w = me spawn Cousins();
    assert w.reports[0] == ["cuz"];
}
'''),
    ),
    dict(
        id="dbg-l2-family-wrong-direction", src="native/nat-l2-family-cousins", level=2,
        bugs=[B("edge-direction", "grandparents computed by walking ParentOf edges forward (to grandchildren) instead of backward",
                E("family.jac", "grandparents = [me <-:ParentOf:<- <-:ParentOf:<-];", "grandparents = [me ->:ParentOf:-> ->:ParentOf:->];"))],
        request="""
`Cousins` always returns an empty list for me, for my kids, for everyone I try — even in a tree where I know there are first cousins (my mum and my aunt share a parent, and my aunt has two kids). No error, just `[]`. Can you figure out what's wrong?
""",
    ),
    dict(
        id="dbg-l2-museum-last-loan-year", src="native/nat-l2-museum-loans", level=2,
        bugs=[B("inconsistent-filter", "borrower-side loan filter treats end_year as exclusive while the owner side treats it as inclusive",
                E("collection.jac", "[here <-:LoanedTo:start_year <= y, end_year >= y:<-]", "[here <-:LoanedTo:start_year <= y, end_year > y:<-]"))],
        request="""
A loaned painting disappears completely in the final year of its loan. "Orchard" is lent from museum A to museum B for 2025–2027 (inclusive). In 2027, `OnDisplay` at A correctly leaves it out (it's away), but `OnDisplay` at B doesn't list it either — so according to the system it's on display nowhere. 2025 and 2026 are fine. Loan years are inclusive at both ends.
""",
        repro=R('''import from collection { Museum, acquire, lend, OnDisplay }

test "borrower shows the work in the last loan year" {
    a = root ++> Museum(name="a");
    b = root ++> Museum(name="b");
    lend(acquire(a, "Orchard"), b, 2025, 2027);
    assert (b spawn OnDisplay(year=2027)).reports[0] == ["Orchard"];
}
'''),
    ),
    dict(
        id="dbg-l2-museum-conservation-borrowed", src="native/nat-l2-museum-loans", level=2,
        bugs=[B("missing-condition", "conservation check applied to owned works only; borrowed works in conservation are still listed",
                E("collection.jac", "            if not art.in_conservation {\n                titles.add(art.title);\n            }\n        }\n        self.shown",
                  "            titles.add(art.title);\n        }\n        self.shown"))],
        request="""
Our visitor app lists "Torn Map" as on display in our galleries. It's on loan to us this year, but it went to the conservation studio last week and is flagged `in_conservation`. Our own works in conservation are hidden correctly. Nothing in conservation should be listed as on display, whether we own it or borrowed it, and `shown` should match the list.
""",
    ),
    dict(
        id="dbg-l2-pantry-optional-blocks", src="native/nat-l2-pantry-substitutes", level=2,
        bugs=[B("missing-edge-filter", "Needs edges are not filtered on optional == False, so optional ingredients block recipes",
                E("cookbook.jac", "[here ->:Needs:optional == False:->]", "[here ->:Needs:->]"))],
        request="""
"What can I cook" refuses to suggest pancakes even though I have flour and milk; the only thing missing is blueberries, which the recipe marks as optional. Optional ingredients should never stop a recipe from being suggested (and shouldn't produce swaps either).
""",
        repro=R('''import from cookbook { add_recipe, WhatCanICook }

test "optional ingredient does not block a recipe" {
    add_recipe("pancakes", ["flour", "milk"], ["blueberries"]);
    w = root spawn WhatCanICook(pantry=["flour", "milk"]);
    assert [p.title for p in w.reports[0]] == ["pancakes"];
}
'''),
    ),
    dict(
        id="dbg-l2-pantry-orphan-ingredients", src="native/nat-l2-pantry-substitutes", level=2,
        bugs=[B("persistence-not-attached", "new Ingredient nodes are not connected to root, so get-or-create never finds them and substitutes attach to duplicate nodes",
                E("cookbook.jac", "    return root ++> Ingredient(name=label);", "    return Ingredient(name=label);"))],
        request="""
Substitutions have stopped working. I registered `allow_substitute("butter", "margarine")`, my pantry has flour, sugar and margarine, and shortbread (flour, butter, sugar) is not suggested. Recipes where I have every ingredient still come up fine. It looks as if the substitute rules are just being ignored.
""",
    ),
    dict(
        id="dbg-l2-tram-wrong-branch", src="native/nat-l2-tram-lines", level=2,
        bugs=[B("missing-edge-filter", "next stop is chosen among all outgoing tracks instead of the requested line's",
                E("tramway.jac", "            nxt = [here ->:Track:line == self.line:->];", "            nxt = [here ->:Track:->];"))],
        request="""
`RunLine(line="1")` from Quay goes Quay → Market → Depot. Depot is on line 2! Line 1 continues Market → Museum. It only happens at stops where two lines branch; straight sections are fine. A run must only ever follow hops of the line it was asked for.
""",
        repro=R('''import from tramway { stop, add_hop, RunLine }

test "line 1 stays on line 1 at a branch" {
    add_hop("1", "Quay", "Market", 3);
    add_hop("2", "Market", "Depot", 5);
    add_hop("1", "Market", "Museum", 4);
    w = stop("Quay") spawn RunLine(line="1");
    assert w.reports[0] == ["Quay", "Market", "Museum"];
}
'''),
    ),
    dict(
        id="dbg-l2-tram-interchange-copy-paste", src="native/nat-l2-tram-lines", level=2,
        bugs=[B("copy-paste", "second loop meant to read incoming tracks reads outgoing tracks again",
                E("tramway.jac", "        for e in [edge here <-:Track:<-] {", "        for e in [edge here ->:Track:->] {"))],
        request="""
The interchange list is missing stops. Museum is where line 1 terminates and line 2 departs, so passengers definitely change there, but `Interchanges` doesn't report it. Same with Quay, where line 3 arrives from the Beach and line 1 leaves. A stop is an interchange if two or more different lines arrive at or depart from it.
""",
    ),
    dict(
        id="dbg-l2-watershed-double-count", src="native/nat-l2-watershed-upstream", level=2,
        bugs=[B("inconsistent-key", "visited set is filled with names but checked with jid, so braided reaches are counted twice",
                E("watershed.jac", "        self.seen.add(key);\n", "        self.seen.add(here.name);\n"))],
        request="""
The upstream load at the Low Ford station comes out as 22.5 kg/day, but adding up the reaches upstream of it by hand gives 12.5. Upstream of Low Ford the river splits around an island and joins again (top → left/right → low), and it looks like the stretch above the split is being counted more than once. Each reach should count exactly once, no matter how many routes lead to it.
""",
        repro=R('''import from watershed { Reach, Station, Samples, connect_reach, UpstreamLoad }

test "braided channel counts each reach once" {
    top = Reach(name="top", load_kg=10.0);
    left = Reach(name="left", load_kg=1.0);
    right = Reach(name="right", load_kg=1.0);
    low = Reach(name="low", load_kg=0.5);
    root ++> top;
    connect_reach(top, left, False);
    connect_reach(top, right, False);
    connect_reach(left, low, False);
    connect_reach(right, low, False);
    s = root ++> Station(code="low-ford");
    s +>:Samples():+> low;
    w = s spawn UpstreamLoad();
    assert w.total_kg == 12.5;
}
'''),
    ),
    dict(
        id="dbg-l2-watershed-dry-inverted", src="native/nat-l2-watershed-upstream", level=2,
        bugs=[B("inverted-filter", "dry-season traversal follows only seasonal channels instead of only permanent ones",
                E("watershed.jac", "seasonal == False", "seasonal == True"))],
        request="""
Dry-season mode of `UpstreamLoad` gives nonsense. At the town station, wet season correctly sums everything upstream. In the dry season the seasonal gully channel is dry, so the hill and gully reaches behind it shouldn't contribute — but instead the dry-season result includes the gully and hill and leaves out the spring, which flows into town through a permanent channel all year.
""",
    ),
    # ------------------------------------------------------------------ L3
    dict(
        id="dbg-l3-bird-last-seen-regresses", src="native/nat-l3-bird-survey", level=3,
        bugs=[B("wrong-aggregate", "last_day takes the latest submission instead of the max day",
                E("survey.jac", "link.last_day = max(link.last_day, self.day);", "link.last_day = self.day;"))],
        request="""
Volunteers don't always hand in their field cards in order. When someone submits Monday's heron sighting (day 1) after Wednesday's (day 3), the survey now says heron was last seen at the marsh on day 1. The totals add up fine; it's only the "last seen" day that goes backwards. The last day must be the latest day the species was seen at that site, regardless of submission order.
""",
        repro=R('''import from survey { Site, Species, Sighted, LogSighting }

test "late card does not move last_day backwards" {
    root spawn LogSighting(site="Marsh", species="Heron", count=2, day=3);
    root spawn LogSighting(site="Marsh", species="Heron", count=1, day=1);
    s = [root -->[?:Site, name == "Marsh"]][0];
    e = [edge s ->:Sighted:->][0];
    assert e.total == 3;
    assert e.last_day == 3;
}
'''),
    ),
    dict(
        id="dbg-l3-bird-species-duplicated", src="native/nat-l3-bird-survey", level=3,
        bugs=[B("persistence-not-attached", "new Species nodes are not attached to root, so every sighting creates a fresh species and a fresh edge",
                E("survey.jac", "    return found[0] if found else root ++> Species(name=label);", "    return found[0] if found else Species(name=label);"))],
        request="""
Something is off with the bird survey since the last refactor. Repeat sightings of the same species at the same site don't accumulate: the Wood site list shows Robin twice with separate totals, and the `Scarce` report says every species was seen at one site, even crows, which we record everywhere. Sites themselves look fine. Logging a sighting of a known species should update the existing record for that site, and species should be shared across sites.
""",
    ),
    dict(
        id="dbg-l3-greenhouse-waters-everything", src="native/nat-l3-greenhouse-watering", level=3,
        bugs=[B("missing-filter", "WaterBed visits every bed instead of only the requested one",
                E("greenhouse.jac", "visit [-->[?:Bed, code == self.bed]];", "visit [-->[?:Bed]];"))],
        request="""
Watering bed B1 resets the watering clock for the entire greenhouse. After someone waters B1, the thyme in B2 doesn't come up as due any more, even though nobody touched B2. Also the watered count reported for B1 is the total number of plants in the greenhouse. Watering a bed should only affect the plants in that bed.
""",
        repro=R('''import from greenhouse { PlantIn, WaterBed, DueOn }

test "watering one bed leaves the others due" {
    root spawn PlantIn(bed="B1", species="basil", interval_days=2, day=0);
    root spawn PlantIn(bed="B2", species="thyme", interval_days=2, day=0);
    assert (root spawn WaterBed(bed="B1", day=3)).reports[0] == 1;
    assert (root spawn DueOn(day=4)).reports[0] == ["B2/thyme"];
}
'''),
    ),
    dict(
        id="dbg-l3-greenhouse-due-late", src="native/nat-l3-greenhouse-watering", level=3,
        bugs=[B("off-by-one", "due test uses > interval instead of >= interval",
                E("greenhouse.jac", ">= p.interval_days", "> p.interval_days"))],
        request="""
Plants show up on the watering list one day late. Basil has a 2-day interval and was watered on day 10; on day 12 `DueOn` should list it, but it only appears on day 13. A plant is due once the days since its last watering reach its interval.
""",
    ),
    dict(
        id="dbg-l3-garage-over-capacity", src="native/nat-l3-parking-garage", level=3,
        bugs=[B("off-by-one", "capacity check uses <= so each level accepts one car more than it has spots",
                E("garage.jac", "if len([lvl ->:ParkedOn:->]) < lvl.spots {", "if len([lvl ->:ParkedOn:->]) <= lvl.spots {"))],
        request="""
The car park let a car onto level 1 when level 1 was already full — 40 spots, and the occupancy report showed 41 cars there. Drivers are circling looking for a space that doesn't exist. A level must not take more cars than it has spots; when every level is full, `Enter` must refuse with reason "full".
""",
        repro=R('''import from garage { AddLevel, Enter, Occupancy }

test "full level sends the next car upstairs" {
    root spawn AddLevel(number=1, spots=1);
    root spawn AddLevel(number=2, spots=1);
    assert (root spawn Enter(plate="A", minute=0)).reports[0].level == 1;
    assert (root spawn Enter(plate="B", minute=0)).reports[0].level == 2;
    assert (root spawn Enter(plate="C", minute=0)).reports[0].reason == "full";
}
'''),
    ),
    dict(
        id="dbg-l3-garage-free-hour", src="native/nat-l3-parking-garage", level=3,
        bugs=[B("integer-division", "fee counts completed hours instead of started hours",
                E("garage.jac", "fee = 3 * ((stay + 59) // 60);", "fee = 3 * (stay // 60);"))],
        request="""
Customer complaint turned into an audit finding: a driver who stayed 45 minutes paid nothing, and someone who stayed 1 hour 50 minutes paid for one hour. Pricing is: first 30 minutes free; beyond that 3 per STARTED hour of the whole stay (so 31–60 minutes = 3, 61–120 = 6, ...). Please fix `Leave`.
""",
    ),
    dict(
        id="dbg-l3-radio-dupe-case", src="native/nat-l3-radio-contest-log", level=3,
        bugs=[B("inconsistent-normalization", "dupe check compares the stored upper-case call against the raw (unnormalised) input",
                E("contest.jac", "[book ->:Logged:->[?:Qso, call == sign]]", "[book ->:Logged:->[?:Qso, call == self.call]]"))],
        request="""
The contest logger isn't catching dupes when the operator types the callsign in lower case. I logged K1ABC on 20m, later typed `k1abc` on 20m again and it said "ok" — that's a dupe and costs us points with the contest committee. Calls are supposed to be case-insensitive (we store them upper-case).
""",
        repro=R('''import from contest { Band, LogQso }

test "lower case repeat is a dupe" {
    assert (root spawn LogQso(call="K1ABC", band=Band.B20M, minute=1, zone=5)).reports[0] == "ok";
    assert (root spawn LogQso(call="k1abc", band=Band.B20M, minute=9, zone=5)).reports[0] == "dupe";
}
'''),
    ),
    dict(
        id="dbg-l3-radio-summary-keyerror", src="native/nat-l3-radio-contest-log", level=3,
        bugs=[B("crash-missing-init", "summary accumulates with += into a dict key that was never initialised (KeyError)",
                E("contest.jac", "self.counts[here.band.name] = len([here ->:Logged:->]);", "self.counts[here.band.name] += len([here ->:Logged:->]);"))],
        request="""
`BandSummary` crashes as soon as there's anything in the log:

```
KeyError: 'B80M'
```

With an empty log it's fine. Scoring still works. It should report a dict of band name → number of contacts for each band we've logged on.
""",
    ),
    dict(
        id="dbg-l3-toollib-member-not-saved", src="native/nat-l3-tool-library", level=3,
        bugs=[B("persistence-not-attached", "new Member nodes are created but never connected to root, so the same card becomes a new member on every checkout",
                E("toollib.jac", "            member = root ++> Member(card=self.card);", "            member = Member(card=self.card);"))],
        request="""
Two problems at the tool library that I think are related: members can borrow any number of tools (the 2-tool limit never triggers — card c7 currently has five tools out), and the overdue report is always empty even though I know the hedge trimmer is three weeks late. Checkouts themselves say ok and the tools do show as lent.
""",
        repro=R('''import from toollib { RegisterTool, Checkout }

test "third tool for the same card hits the limit" {
    root spawn RegisterTool(code="DR1", name="Drill");
    root spawn RegisterTool(code="SW1", name="Saw");
    root spawn RegisterTool(code="LD1", name="Ladder");
    root spawn Checkout(card="c7", code="DR1", day=1);
    root spawn Checkout(card="c7", code="SW1", day=1);
    r = root spawn Checkout(card="c7", code="LD1", day=1);
    assert r.reports[0].reason == "limit reached";
}
'''),
    ),
    dict(
        id="dbg-l3-toollib-return-deletes-tool", src="native/nat-l3-tool-library", level=3,
        bugs=[B("wrong-delete-target", "Return deletes the Tool node instead of the Lent edge",
                E("toollib.jac", "del [edge holders[0] ->:Lent:-> tool];", "del tool;"))],
        request="""
After a member returns a tool it vanishes from the catalogue. Someone returned the drill DR1 this morning and now checking it out again says "unknown tool"; we had to run RegisterTool for it again. Returning should just end the loan — the tool and the member stay.
""",
    ),
    # ------------------------------------------------------------------ L4 (two bugs)
    dict(
        id="dbg-l4-chess-ladder-shuffle", src="native/nat-l4-chess-ladder", level=4,
        bugs=[
            B("off-by-one", "rank shift excludes the defender (>= became >), leaving two players on the same rank",
              E("challenge.jac", "if p.rank >= old_d and p.rank < old_c {", "if p.rank > old_d and p.rank < old_c {")),
            B("off-by-one", "range rule rejects a challenge exactly 3 rungs up",
              E("challenge.jac", "if gap <= 0 or gap > 3 {", "if gap <= 0 or gap >= 3 {")),
        ],
        request="""
Two complaints from the club about the ladder after this week's matches:

1. Eli (5th) beat Ben (2nd). Eli is now shown 2nd, fine, but Ben is ALSO rank 2 and Cyd/Dov moved down, so the ranks now read 1, 2, 2, 4, 5. When a challenger wins, they take the defender's rank and everyone from the defender down to just above the challenger's old rank moves down one.
2. Dov tried to challenge Ada three rungs above him and got "out of range". Our rules allow challenging anyone up to three rungs above you.

Please fix both. `jac run main.jac` replays a short season if that helps.
""",
    ),
    dict(
        id="dbg-l4-film-callsheet-times", src="native/nat-l4-film-callsheet", level=4,
        bugs=[
            B("inverted-comparison", "earliest-scene tracking keeps the latest scene instead",
              E("callsheet.jac", "here.start_min < self.first_scene[key]", "here.start_min > self.first_scene[key]")),
            B("wrong-attribute", "distinct locations counted by scene number instead of location",
              E("callsheet.jac", "self.places.add(here.location);", "self.places.add(here.number);")),
        ],
        request="""
Today's call sheet was a mess. Mia from makeup was called for 07:00 but her first scene was at 07:00 — makeup needs to be in two hours before their FIRST scene of the day, and she has an earlier one (4B at 07:00, then 4A at 09:00), so her call should have been 05:00. Camera had the same problem. Also the header said we're at 2 locations today; we're only at the diner all day (two scenes there).

Can you go through the call sheet logic and fix whatever is causing these?
""",
        repro=R('''import from crew { Department }
import from schedule { add_scene, hire, assign }
import from callsheet { CallSheet }

test "call time comes from the earliest scene" {
    s1 = add_scene(3, "4A", 540, "Diner");
    s2 = add_scene(3, "4B", 420, "Diner");
    mia = hire("Mia", Department.MAKEUP);
    assign(mia, s1);
    assign(mia, s2);
    w = root spawn CallSheet(day=3);
    assert w.reports[0] == ["05:00 Mia (MAKEUP)"];
    assert w.locations == 1;
}
'''),
    ),
    dict(
        id="dbg-l4-orchard-forecast-low", src="native/nat-l4-orchard-forecast", level=4,
        bugs=[
            B("accumulator-overwrite", "per-variety kg is overwritten by each tree instead of summed",
              E("harvest.jac", "self.kg[name] = self.kg.get(name, 0.0) + MATURE_KG[name] * age_factor(here.age);",
                "self.kg[name] = MATURE_KG[name] * age_factor(here.age);")),
            B("statement-order", "trees counted before the diseased early-return",
              E("harvest.jac", "        self.counted += 1;\n    }\n", "    }\n"),
              E("harvest.jac", "        if here.diseased {\n            return;\n        }\n", "        self.counted += 1;\n        if here.diseased {\n            return;\n        }\n")),
        ],
        request="""
The harvest forecast for block Two looks way too low: two rows of mature Fuji (one tree per row) should be 100 kg and we get 50. In general it seems like each variety's total is just the yield of one tree. And separately, `trees_counted` includes trees we've marked diseased — those are supposed to be left out of both the kilos and the count.
""",
    ),
    dict(
        id="dbg-l4-panel-load-voltage", src="native/nat-l4-panel-load", level=4,
        bugs=[
            B("ignored-parameter", "amps computed with a hard-coded 120 V instead of the walker's volts",
              E("load.jac", "amps = round(watts / self.volts, 2);", "amps = round(watts / 120.0, 2);")),
            B("off-by-one", "overload threshold inclusive (>=) instead of strictly above 80%",
              E("load.jac", "if amps > 0.8 * here.amps {", "if amps >= 0.8 * here.amps {")),
        ],
        request="""
The panel load checker gives wrong answers for my workshop:

- On the 240 V sub-panel, `PanelLoad(volts=240.0)` reports the dryer and oven breakers as overloaded and the per-breaker loads are exactly double what my clamp meter shows. It looks like it isn't using the voltage I pass in.
- On the main panel, the garage breaker (10 A rating, a 960 W saw → exactly 8.0 A) is flagged as overloaded. The rule is "strictly above 80% of the rating", so exactly 80% is OK.
""",
        repro=R('''import from panel { breaker, outlet, plug }
import from load { PanelLoad }

test "uses the given voltage and a strict threshold" {
    a = breaker("dryer", 10);
    plug(outlet(a, "laundry"), "dryer", 2000, True);
    w = root spawn PanelLoad(volts=240.0);
    assert w.loads["dryer"] == 8.33;
    assert w.reports[0] == ["dryer"];
    at = breaker("garage", 10);
    plug(outlet(at, "garage"), "saw", 960, True);
    w2 = root spawn PanelLoad();
    assert w2.loads["garage"] == 8.0;
    assert "garage" not in w2.reports[0];
}
'''),
    ),
    dict(
        id="dbg-l4-warehouse-pick-stops-early", src="native/nat-l4-warehouse-picking", level=4,
        bugs=[
            B("aliasing", "walker works directly on the caller's order dict instead of a copy",
              E("picking.jac", "self.outstanding = dict(self.order);", "self.outstanding = self.order;")),
            B("any-vs-all", "pick run stops as soon as one SKU is complete (all) instead of continuing while any SKU is outstanding",
              E("picking.jac", "if any([n > 0 for n in self.outstanding.values()]) {", "if all([n > 0 for n in self.outstanding.values()]) {")),
        ],
        request="""
Two pick-run issues reported by the floor team:

1. Orders come back short even though stock exists further down the aisle chain. Example: order bolt×10, nut×3; aisle 1 has 6 bolts and 1 nut, aisle 2 has 5 nuts, aisle 3 has 100 bolts. The run picked aisle 1 and aisle 2 and then stopped, reporting 4 bolts short.
2. The order dict the sales system passes into `PickRun(order=...)` comes back modified (quantities reduced to 0), which breaks their invoicing. The walker must not change the caller's order.

`jac run main.jac` should print "picked 5 lines, short 4 units" for the demo warehouse.
""",
    ),
    dict(
        id="dbg-l4-greenhouse-beds-mixed", src="native/nat-l3-greenhouse-watering", level=4,
        bugs=[
            B("wrong-field", "bed lookup in PlantIn compares the bed code against the species, so every planting creates a new bed",
              E("greenhouse.jac", "beds = [root -->[?:Bed, code == self.bed]];", "beds = [root -->[?:Bed, code == self.species]];")),
            B("missing-filter", "Uproot pulls the species from every bed, not just the requested one",
              E("greenhouse.jac", "for b in [root -->[?:Bed, code == self.bed]] {", "for b in [root -->[?:Bed]] {")),
        ],
        request="""
The greenhouse app is getting the beds confused:

- Every time we plant something a new bed appears. We have three physical beds but the database now lists eleven B1s and B2s, and `PlantIn` always reports 1 plant in the bed.
- Uprooting the mint in B1 also pulled the mint out of B2.

Both should be scoped to the bed code we pass in.
""",
    ),
    dict(
        id="dbg-l4-garage-levels-and-total", src="native/nat-l3-parking-garage", level=4,
        bugs=[
            B("missing-sort", "levels tried in creation order instead of lowest number first",
              E("garage.jac", "for lvl in sorted([root -->[?:Level]], key=lambda (l: Level) { l.number; }) {", "for lvl in [root -->[?:Level]] {")),
            B("accumulator-overwrite", "occupancy total overwritten per level instead of summed",
              E("garage.jac", "self.total += n;", "self.total = n;")),
        ],
        request="""
After we added level 3 first (the new rooftop) and then levels 1 and 2, cars are being sent to the rooftop while the lower floors are empty. Cars should always go to the lowest-numbered level with a free spot.

Also the occupancy screen's total is wrong — with 2 cars on level 1 and 1 on level 2 it says total 0. The per-level numbers look right.
""",
        repro=R('''import from garage { AddLevel, Enter, Occupancy }

test "lowest level first and total across levels" {
    root spawn AddLevel(number=3, spots=5);
    root spawn AddLevel(number=1, spots=2);
    root spawn AddLevel(number=2, spots=2);
    for p in ["a", "b", "c"] {
        root spawn Enter(plate=p, minute=0);
    }
    w = root spawn Occupancy();
    assert w.reports[0] == {3: 0, 1: 2, 2: 1};
    assert w.total == 3;
}
'''),
    ),
    # ------------------------------------------------------------------ L5 (two bugs, HTTP service)
    dict(
        id="dbg-l5-bikeshare-odometer-dock", src="native/nat-l5-bikeshare-api", level=5,
        bugs=[
            B("assign-vs-accumulate", "return overwrites the odometer with the trip distance instead of adding it",
              E("app.jac", "bike.km += self.km;", "bike.km = self.km;")),
            B("off-by-one", "full-station check uses > so a full station accepts one more bike",
              E("app.jac", "if len([st ->:Docked:->]) >= st.capacity {", "if len([st ->:Docked:->]) > st.capacity {")),
        ],
        request="""
Fleet maintenance escalated two things about the bike-share service:

- Wear levelling is broken. `rent_bike` is supposed to hand out the least-worn bike (lowest km, ties by serial), but high-mileage bikes keep going out because after a ride their odometer looks almost new — e.g. A-10 had 10 km, came back from a 4.5 km ride and now reads 4.5 km.
- Station S2 has one dock but `network_status` showed 2 bikes there yesterday; a return was accepted into a full station. Returns to a full station must be refused with "station full".
""",
        repro=R(HTTP_HELPERS + '''
test "odometer accumulates and full station refuses" {
    c = open_client();
    try {
        fn(c, "add_station", {"code": "S1", "capacity": 3});
        fn(c, "add_station", {"code": "S2", "capacity": 1});
        fn(c, "add_bike", {"station": "S1", "serial": "A-10", "km": 10.0});
        fn(c, "add_bike", {"station": "S1", "serial": "B-11", "km": 11.0});
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 1});
        walk(c, "return_bike", {"station": "S1", "rider": "kim", "km": 4.5});
        assert walk(c, "rent_bike", {"station": "S1", "rider": "lee", "minute": 2})["bike"] == "B-11";
        assert walk(c, "return_bike", {"station": "S2", "rider": "lee", "km": 1.0})["ok"] == True;
        walk(c, "rent_bike", {"station": "S1", "rider": "kim", "minute": 3});
        assert walk(c, "return_bike", {"station": "S2", "rider": "kim", "km": 1.0})["reason"] == "station full";
    } finally {
        c.close();
    }
}
'''),
    ),
    dict(
        id="dbg-l5-bikeshare-repeat-riders", src="native/nat-l5-bikeshare-api", level=5,
        bugs=[
            B("get-or-create", "rent always creates a new Rider node instead of reusing the existing one",
              E("app.jac", "        if rd is None {\n            rd = root ++> Rider(name=self.rider);\n        }\n", "        rd = root ++> Rider(name=self.rider);\n")),
            B("wrong-sort-key", "least-worn ordering sorts by serial first instead of km first",
              E("app.jac", "key=lambda (b: Bike) { (b.km, b.serial); }", "key=lambda (b: Bike) { (b.serial, b.km); }")),
        ],
        request="""
Support tickets from the bike-share app:

- "I returned my bike, rented another one an hour later, and now I can't return it — the app says `not riding`." This seems to happen to anyone who rents a second time.
- Maintenance says the bike handed out at a station isn't the least-worn one. The rule is lowest odometer (km) first, ties broken by serial; it looks like it's just picking alphabetically.
""",
    ),
    dict(
        id="dbg-l5-dog-boarding-vacancy", src="native/nat-l5-dog-boarding", level=5,
        bugs=[
            B("off-by-one", "overlap test treats back-to-back stays (one ends the night before the other starts) as overlapping",
              E("app.jac", "start < s.start + s.nights", "start <= s.start + s.nights")),
            B("wrong-sort-key", "run preference sorts by code before size, so larger runs are picked before fitting smaller ones",
              E("app.jac", "key=lambda (r: Run) { (r.size.value, r.code); }", "key=lambda (r: Run) { (r.code, r.size.value); }")),
        ],
        request="""
Two booking problems at the kennel:

1. Back-to-back stays get rejected. Rex stays in S1 for nights 10, 11, 12 (start 10, 3 nights); a booking for S1 starting night 13 should be fine, but the system says "no vacancy". (A stay covers nights start .. start + nights - 1.)
2. Medium dogs keep getting put in the large run (L1) while both medium runs are empty. A dog should get the smallest run size that fits, and among those the lowest run code.
""",
        repro=R(HTTP_HELPERS + '''
test "back to back and smallest fitting run" {
    c = open_client();
    try {
        for (code, size) in [("L1", "LARGE"), ("M1", "MEDIUM"), ("S1", "SMALL")] {
            fn(c, "add_run", {"code": code, "size": size});
        }
        assert walk(c, "book_stay", {"dog": "rex", "size": "SMALL", "start": 10, "nights": 3})["run"] == "S1";
        assert walk(c, "book_stay", {"dog": "ivy", "size": "SMALL", "start": 13, "nights": 2})["run"] == "S1";
        assert walk(c, "book_stay", {"dog": "bo", "size": "MEDIUM", "start": 1, "nights": 2})["run"] == "M1";
    } finally {
        c.close();
    }
}
'''),
    ),
    dict(
        id="dbg-l5-ferry-capacity-refs", src="native/nat-l5-ferry-booking", level=5,
        bugs=[
            B("missing-condition", "foot slots consumed by passengers of every booking, not only FOOT bookings",
              E("app.jac", "return self.passengers if self.vehicle == Vehicle.FOOT else 0;", "return self.passengers;")),
            B("wrong-scope", "duplicate booking ref only checked on the requested sailing instead of across all sailings",
              E("app.jac", "if [b for b in [root -->[?:Sailing] ->:Holds:->] if b.ref == self.ref] {", "if [b for b in [s ->:Holds:->] if b.ref == self.ref] {")),
        ],
        request="""
Ferry booking issues from the purser's office:

- Foot-passenger seats sell out far too early. On today's AM1 (5 seats) we had a van with 4 people and a car with 5 people, and then a family of 3 on foot was refused as "sold out". People travelling in a car or van don't take foot seats.
- A customer managed to use the same booking reference `same` on both AM1 and PM1. Booking references must be unique across all sailings ("duplicate ref").
""",
    ),
    dict(
        id="dbg-l5-hackathon-scores-wrong", src="native/nat-l5-hackathon-judging", level=5,
        bugs=[
            B("missing-filter", "existing-score lookup ignores the criterion, so scoring a second criterion overwrites the first",
              E("app.jac", "existing = [e for e in [edge j ->:Scored:-> t] if e.criterion == self.criterion];", "existing = [e for e in [edge j ->:Scored:-> t]];")),
            B("missing-condition", "empty track filter no longer means 'all tracks'",
              E("app.jac", "if self.track and here.track != self.track {", "if here.track != self.track {")),
        ],
        request="""
Judging went sideways at the hackathon:

- When a judge scores a team on IMPACT and then on CRAFT, the IMPACT score seems to get replaced — the team ends up with one score from that judge instead of two, and the leaderboard numbers are too low. Re-scoring the SAME criterion should replace it, different criteria should add up.
- The overall leaderboard (`{"track": ""}`) comes back empty. An empty track means all tracks; a specific track filters.
""",
        repro=R(HTTP_HELPERS + '''
test "two criteria from one judge both count, empty track lists all" {
    c = open_client();
    try {
        fn(c, "register_team", {"name": "Otters", "track": "climate"});
        fn(c, "register_team", {"name": "Badgers", "track": "health"});
        fn(c, "add_judge", {"name": "Ines"});
        walk(c, "score_team", {"judge": "Ines", "team": "Otters", "criterion": "IMPACT", "points": 8});
        walk(c, "score_team", {"judge": "Ines", "team": "Otters", "criterion": "CRAFT", "points": 7});
        board = walk(c, "leaderboard", {"track": ""});
        assert [r["team"] for r in board] == ["Otters", "Badgers"];
        assert board[0]["score"] == 15.0;
    } finally {
        c.close();
    }
}
'''),
    ),
    dict(
        id="dbg-l5-lostfound-search-expire", src="native/nat-l5-lost-and-found", level=5,
        bugs=[
            B("off-by-one", "items donated at exactly keep_days instead of strictly after",
              E("app.jac", "self.today - here.found_day > self.keep_days", "self.today - here.found_day >= self.keep_days")),
            B("inconsistent-normalization", "search lower-cases the stored colour but not the query colour",
              E("app.jac", "here.color.lower() == self.color.lower()", "here.color.lower() == self.color")),
        ],
        request="""
Lost-property desk problems:

- Searching for colour "Red" finds nothing, while "red" works. Colour matching is supposed to be case-insensitive on both sides.
- The expiry run donated a tan bag that had been with us exactly 30 days, with keep_days=30. We keep items for keep_days days; only items found MORE than keep_days days ago get donated (and never claimed ones).
""",
    ),
    # ------------------------------------------------------------------ app-kind sources
    dict(
        id="dbg-l1-shipping-tiny-parcel", src="app/app-l1-shipping-quote", level=1,
        bugs=[B("missing-clamp", "extra-weight term not clamped at zero, so parcels under 1 kg get a discount below the base price",
                E("shipping.jac", "return round(base + max(0.0, weight_kg - 1) * per_kg, 2);", "return round(base + (weight_kg - 1) * per_kg, 2);"))],
        request="""
A customer noticed that a 0.5 kg domestic parcel is quoted at 4.40, which is less than our 5.00 domestic base price. Every parcel should pay at least the zone's base price; the per-kg rate only applies to weight above the first kilogram. Heavier parcels look correct.
""",
        repro=R('''import from shipping { quote }

test "parcel under one kilo pays the base price" {
    assert quote(0.5, "domestic") == 5.0;
    assert quote(1.0, "regional") == 9.0;
}
'''),
    ),
    dict(
        id="dbg-l2-orgchart-chain-direction", src="app/app-l2-org-chart", level=2,
        bugs=[B("edge-direction", "chain of command follows Manages edges downward instead of upward",
                E("orgchart.jac", "        visit [here <-:Manages:<-];", "        visit [here ->:Manages:->];"))],
        request="""
`ChainOfCommand` is upside down. Spawned on Linus (an engineer) it reports an empty list, and spawned on Ada (the CEO) it lists her whole organisation. It should report the people ABOVE the starting employee, nearest manager first, up to the top. Headcount and payroll are fine.
""",
    ),
    dict(
        id="dbg-l3-library-copies-never-drop", src="app/app-l3-library-loans", level=3,
        bugs=[B("edge-direction", "available copies count Loan edges leaving the book (there are none) instead of arriving at it",
                E("main.jac", "return b.copies - len([edge b <-:Loan:<-]);", "return b.copies - len([edge b ->:Loan:->]);"))],
        request="""
The library CLI never runs out of copies. We have one copy of Ulysses; `jac run main.jac checkout ann <isbn> 2026-04-01` works, `available <isbn>` still says 1, and Bob can check it out too, and so can a third person. Checkouts are recorded (they appear in the overdue report later). Available should be copies minus copies currently on loan, and a checkout with no copy left must print "unavailable".
""",
        repro=R('''import from main { AddBook, Checkout, Available }

test "checkout uses up the only copy" {
    root spawn AddBook(isbn="repro-1", title="Ulysses", copies=1);
    root spawn Checkout(member="ann", isbn="repro-1", date="2026-04-01");
    assert (root spawn Available(isbn="repro-1")).reports[0] == 0;
}
'''),
    ),
]
