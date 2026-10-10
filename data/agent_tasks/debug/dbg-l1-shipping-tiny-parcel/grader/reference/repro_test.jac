import from shipping { quote }

test "parcel under one kilo pays the base price" {
    assert quote(0.5, "domestic") == 5.0;
    assert quote(1.0, "regional") == 9.0;
}
