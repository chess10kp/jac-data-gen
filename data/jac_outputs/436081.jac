"""Coins rewarded when upgrading to new_level."""
def level_up_reward(level: int, new_level: int) -> int {
    coins = 0;
    while level < new_level {
        coins += 5 + level // 15;
        level += 1;
    }
    return coins;
}