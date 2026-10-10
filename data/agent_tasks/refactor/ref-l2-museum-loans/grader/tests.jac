import from loans { add_museum, acquire, lend, on_display, lenders_to }

test "museums and acquisitions" {
    assert add_museum("Rijks");
    assert not add_museum("Rijks");
    assert add_museum("Prado");
    assert acquire("Rijks", "Night Watch");
    assert not acquire("Rijks", "Night Watch");
    assert acquire("Prado", "Night Watch");
    assert not acquire("Louvre", "Mona Lisa");
    assert on_display("Rijks", 2020) == ["Night Watch"];
    assert len(on_display("Louvre", 2020)) == 0;
}

test "loan validation" {
    add_museum("Rijks");
    add_museum("Prado");
    acquire("Rijks", "Milkmaid");
    assert not lend("Rijks", "Milkmaid", "Rijks", 2020, 2021);
    assert not lend("Rijks", "Milkmaid", "Tate", 2020, 2021);
    assert not lend("Tate", "Milkmaid", "Prado", 2020, 2021);
    assert not lend("Rijks", "Sunflowers", "Prado", 2020, 2021);
    assert not lend("Rijks", "Milkmaid", "Prado", 2022, 2021);
    assert lend("Rijks", "Milkmaid", "Prado", 2020, 2021);
    assert not lend("Rijks", "Milkmaid", "Prado", 2021, 2023);
    assert not lend("Rijks", "Milkmaid", "Prado", 2018, 2020);
    assert lend("Rijks", "Milkmaid", "Prado", 2022, 2022);
    assert lend("Rijks", "Milkmaid", "Prado", 2017, 2019);
}

test "what each museum shows in a given year" {
    add_museum("Rijks");
    add_museum("Prado");
    add_museum("Tate");
    acquire("Rijks", "Milkmaid");
    acquire("Rijks", "Night Watch");
    acquire("Prado", "Las Meninas");
    lend("Rijks", "Milkmaid", "Prado", 2020, 2021);
    lend("Prado", "Las Meninas", "Tate", 2021, 2021);
    assert on_display("Rijks", 2019) == ["Milkmaid", "Night Watch"];
    assert on_display("Rijks", 2020) == ["Night Watch"];
    assert on_display("Rijks", 2021) == ["Night Watch"];
    assert on_display("Rijks", 2022) == ["Milkmaid", "Night Watch"];
    assert on_display("Prado", 2020) == ["Las Meninas", "Milkmaid"];
    assert on_display("Prado", 2021) == ["Milkmaid"];
    assert on_display("Prado", 2022) == ["Las Meninas"];
    assert on_display("Tate", 2021) == ["Las Meninas"];
    assert len(on_display("Tate", 2020)) == 0;
}

test "who has lent to a museum" {
    add_museum("Rijks");
    add_museum("Prado");
    add_museum("Tate");
    add_museum("Uffizi");
    acquire("Rijks", "Milkmaid");
    acquire("Rijks", "Night Watch");
    acquire("Prado", "Las Meninas");
    lend("Rijks", "Milkmaid", "Tate", 2020, 2020);
    lend("Rijks", "Night Watch", "Tate", 2024, 2025);
    lend("Prado", "Las Meninas", "Tate", 2019, 2019);
    lend("Tate", "Ghost", "Rijks", 2019, 2019);
    assert lenders_to("Tate") == ["Prado", "Rijks"];
    assert len(lenders_to("Rijks")) == 0;
    assert len(lenders_to("Uffizi")) == 0;
    assert len(lenders_to("Nowhere")) == 0;
}
