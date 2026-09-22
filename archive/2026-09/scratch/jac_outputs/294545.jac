"""Get relations from annotation dictonary and combine it with information from the corresponding entities

    Args:
        annotations (dictionary): annotation dictionary (result of calling annotation_to_dict)
        entities (dictionary): entity annotation (result of get_sentence_entities)

    Returns:
        dictionary: extracted and enhanced relations
    """
def get_sentence_relations(annotations: Any, entities: Any) -> object {
    ann_keys = `list(entities.keys());
    relations = {};
    for (k, v) in annotations['relations'].items() {
        if ((v['arg1'] in ann_keys) and (v['arg2'] in ann_keys)) {
            relations[k] = {
                'label': v['label'],
                'arg1_old': v['arg1'],
                'arg2_old': v['arg2'],
                'arg1': entities[v['arg1']]['string'],
                'arg2': entities[v['arg2']]['string'],
                'pos1': entities[v['arg1']]['new_beg']
                    if ('new_beg' in entities[v['arg1']])
                    else entities[v['arg1']]['beg'],
                'pos2': entities[v['arg2']]['new_beg']
                    if ('new_beg' in entities[v['arg2']])
                    else entities[v['arg2']]['beg'],
                'ent1': entities[v['arg1']]['idx'],
                'ent2': entities[v['arg2']]['idx']
            };
        } elif (
            ((v['arg1'] in ann_keys) and not (v['arg2'] in ann_keys))
            or ((v['arg2'] in ann_keys) and not (v['arg1'] in ann_keys))
        ) {
            ;
        }
    }
    return relations;
}