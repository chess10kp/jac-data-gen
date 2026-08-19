def respawn(t: Target) {
    t.x = rand_range(-14.0, 14.0);
    t.base_y = rand_range(1.0, 5.0);
    t.z = rand_range(-16.0, 2.0);
    t.phase = rand_range(0.0, 6.28);
}
