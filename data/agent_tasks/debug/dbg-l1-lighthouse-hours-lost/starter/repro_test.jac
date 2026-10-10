import from keepers { Lens, Lamp, add_lamp, NightShift }

test "burn hours accumulate across nights" {
    add_lamp("gull-point", Lens.SECOND_ORDER, 0.0, 1000.0, True);
    root spawn NightShift(hours=7.5);
    root spawn NightShift(hours=7.5);
    lamp = [root -->[?:Lamp, station == "gull-point"]][0];
    assert lamp.burn_hours == 15.0;
}
