def transfer_user_click(user_click: dict[str, list[str]]) -> dict[str, list[str]] {
    item_click_by_user: dict[str, list[str]] = {};
    for user in user_click {
        for itemid in user_click[user] {
            item_click_by_user.setdefault(itemid, []);
            item_click_by_user[itemid].append(user);
        }
    }
    return item_click_by_user;
}