"""


    :type plan: List[Tuple[str, str]]
    :param plan: [(can_id, tag), ...]

    :rtype: List[Tuple[List[str], str]]]
    """
def resolve_pipeline(plan: Any) -> object {
    pipeline_change_set = list();
    job = ([], None);
    previous_env = None;
    for (tier_name, tier_env) in plan {
        if (tier_env != previous_env) {
            pipeline_change_set.append(job);
            previous_env = tier_env;
            job = ([tier_name], tier_env);
        } else {
            job[0].append(tier_name);
        }
    }
    pipeline_change_set.append(job);
    pipeline_change_set = pipeline_change_set[1:];
    dct = dict();
    pipeline = list();
    for (tier_list, tier_env) in pipeline_change_set {
        if (tier_env in dct) {
            dct[tier_env].extend(tier_list);
        } else {
            dct[tier_env] = tier_list;
        }
        pipeline.append((list(dct[tier_env]), tier_env));
    }
    return pipeline;
}