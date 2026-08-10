"""Generates a CLI formatted listing of validations

    Assumes validation_list is a list of dictionaries with 'validation_name',
    'action_id', 'id', and 'details'.
    """
def gen_action_validations(validation_list: list[dict[str, object]]) -> str {
    if validation_list {
        validations = [];
        for val in validation_list {
            validations.append(
                '{} : validation/{}/{}\n'.format(
                    val.get('validation_name'), val.get('action_id'), val.get('id')
                )
            );
            validations.append(val.get('details'));
            validations.append('\n\n');
        }
        return 'Validations: {}'.format('\n'.join(validations));
    } else {
        return 'Validations: {}'.format('None');
    }
}