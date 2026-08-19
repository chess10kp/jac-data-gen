def fire(bullets: list[Bullet]) -> None {
    yaw_r = yaw * DEG2RAD;
    pitch_r = pitch * DEG2RAD;
    dx = -jsin(yaw_r);
    dy = jsin(pitch_r);
    dz = -jcos(yaw_r);
    # place first dead bullet...
}
