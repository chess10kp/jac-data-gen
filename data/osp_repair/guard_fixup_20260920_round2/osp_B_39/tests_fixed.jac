"""Tests for the theme park midway capstone."""

import io;
import from contextlib { redirect_stdout }

test "tall guest tall enough rides viper and accumulates fun" {
    root ++> Attraction(name="Midway");
    midway = [root -->][0];
    viper = RollerCoaster(name="Viper", min_height_cm=130, thrill=9);
    midway ++> viper;
    logflume = WaterRide(name="Log Flume", splash_level=7);
    midway ++> logflume;

    tall = Rider(rider_name="Ivy", height_cm=155);
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn tall;
    }
    out = buf.getvalue();

    assert "rides Viper (+90 fun)" in out, f"missing Viper line: {out}";
    assert "gets soaked on Log Flume (+35 fun)" in out, f"missing Log Flume line: {out}";
    assert "TOO SHORT" not in out, f"Ivy should not be turned away: {out}";
    assert tall.fun_points == 125, f"Ivy fun expected 125, got {tall.fun_points}";
}

test "short guest turned away from viper then disengages" {
    root ++> Attraction(name="Midway");
    midway = [root -->][0];
    viper = RollerCoaster(name="Viper", min_height_cm=130, thrill=9);
    midway ++> viper;
    logflume = WaterRide(name="Log Flume", splash_level=7);
    midway ++> logflume;

    small = Rider(rider_name="Bo", height_cm=118);
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn small;
    }
    out = buf.getvalue();

    assert "TOO SHORT for Viper" in out, f"missing turn-away line: {out}";
    assert "(needs 130 cm)" in out, f"missing required height: {out}";
    assert "gets soaked on Log Flume" not in out, f"Bo must NOT reach Log Flume after disengage: {out}";
    assert "rides Viper" not in out, f"Bo must not ride Viper: {out}";
    assert small.fun_points == 0, f"Bo fun expected 0 after turn-away, got {small.fun_points}";
}

test "food stall purchase prints tasty message and charges default price" {
    root ++> Attraction(name="Midway");
    midway = [root -->][0];
    midway ++> FoodStall(item_name="churro");

    r = Rider(rider_name="Ivy", height_cm=155);
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = r spawn midway;
    }
    out = buf.getvalue();

    assert "grabs a fresh churro" in out, f"missing food stall line: {out}";
    assert "Tasty!" in out, f"missing Tasty tag: {out}";
    assert "Shiny!" not in out, f"FoodStall should not trigger GiftShop branch: {out}";
    assert r.purchases == 1, f"purchases expected 1, got {r.purchases}";
    assert r.spend == 6, f"spend expected 6 (default price), got {r.spend}";
}

test "gift shop purchase prints shiny message and charges overridden price" {
    root ++> Attraction(name="Midway");
    midway = [root -->][0];
    midway ++> GiftShop(item_name="plastic tiara", price=12);

    r = Rider(rider_name="Bo", height_cm=118);
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = r spawn midway;
    }
    out = buf.getvalue();

    assert "picks up a plastic tiara" in out, f"missing gift shop line: {out}";
    assert "Shiny!" in out, f"missing Shiny tag: {out}";
    assert "Tasty!" not in out, f"GiftShop should not trigger FoodStall branch: {out}";
    assert r.purchases == 1, f"purchases expected 1, got {r.purchases}";
    assert r.spend == 12, f"spend expected 12 (overridden price), got {r.spend}";
}

test "full day tall guest tall enough summary and short guest turn away summary" {
    root ++> Attraction(name="Midway");
    midway = [root -->][0];
    viper = RollerCoaster(name="Viper", min_height_cm=130, thrill=9);
    midway ++> viper;
    logflume = WaterRide(name="Log Flume", splash_level=7);
    midway ++> logflume;
    churro_stand = FoodStall(item_name="churro", price=6);
    coin_shop = GiftShop(item_name="plastic tiara", price=12);
    midway ++> churro_stand;
    midway ++> coin_shop;

    # Graph shape sanity checks
    kids = [midway -->];
    assert len(kids) == 4, f"midway should have 4 children, got {len(kids)}";

    tall = Rider(rider_name="Ivy", height_cm=155);
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn tall;
    }
    ivy_out = buf.getvalue();
    assert "TOO SHORT" not in ivy_out, f"Ivy must not be turned away: {ivy_out}";
    # 90 (Viper) + 35 (Log Flume) + 6 (churro) + 12 (tiara)
    assert tall.fun_points == 125, f"Ivy fun expected 125, got {tall.fun_points}";
    assert tall.purchases == 2, f"Ivy purchases expected 2, got {tall.purchases}";
    assert tall.spend == 18, f"Ivy spend expected 18, got {tall.spend}";

    small = Rider(rider_name="Bo", height_cm=118);
    buf2 = io.StringIO();
    with redirect_stdout(buf2) {
        res = root spawn small;
    }
    bo_out = buf2.getvalue();
    assert "TOO SHORT for Viper" in bo_out, f"Bo must be turned away from Viper: {bo_out}";
    # disengage halts traversal entirely, so Bo never reaches Log Flume, food, or gifts
    assert "gets soaked" not in bo_out, f"Bo must not reach Log Flume: {bo_out}";
    assert "grabs a fresh" not in bo_out, f"Bo must not reach FoodStall: {bo_out}";
    assert "picks up a" not in bo_out, f"Bo must not reach GiftShop: {bo_out}";
    assert small.fun_points == 0, f"Bo fun expected 0, got {small.fun_points}";
    assert small.purchases == 0, f"Bo purchases expected 0, got {small.purchases}";
    assert small.spend == 0, f"Bo spend expected 0, got {small.spend}";
}