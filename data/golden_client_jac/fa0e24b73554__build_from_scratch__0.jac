can run with Root entry {
    mine = [-->[?:Profile]];
    if mine {
        me = mine[0];
        visit [me-->[?:Tweet]];
    }
}
