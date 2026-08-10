"""[Turns a List of Reward Objects into a comma seperated strings]

    Arguments:
        s {[list of rewards]} -- [list of rewards]

    Returns:
        [String] -- [string of comma seperated reward names]
    """
def rewardListToString(s: Any) -> object {
    str1 = "";
    reward_list = [];
    for ele in s {
        reward_list.append(ele.name);
    }
    str1 = ", ".join(reward_list);
    return str1;
}