"""Validate tag sets for a MongoReplicaSetClient."""
def _validate_tag_sets(tag_sets: list[dict] | None) -> list[dict] | None {
    if tag_sets is None {
        return tag_sets;
    }
    if not isinstance(tag_sets, list) {
        raise TypeError("Tag sets %r invalid, must be a list" % (tag_sets,));
    }
    if len(tag_sets) == 0 {
        raise ValueError(
            "Tag sets %r invalid, must be None or contain at least one set of tags"
            % (tag_sets,)
        );
    }
    for tags in tag_sets {
        if not isinstance(tags, dict) {
            raise TypeError(
                "Tag set %r invalid, must be an instance of dict, or bson.son.SON"
                % (tags,)
            );
        }
    }
    return tag_sets;
}