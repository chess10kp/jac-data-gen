"""
        Get list of zero hit count rules
        :param hit_count_rules:
            dictionary which contain json response with all hit count rules
        :return:
            list with all zero hit count rules (contain rule name, id, type and access policy name)
    """
def zero_hit_count_rules(hit_count_rules: Any) -> object {
    rule = [];
    for i in hit_count_rules {
        if (i["hitCount"] == 0) {
            rule.append(i["rule"]);
        }
    }
    return rule;
}