"""Handles DV360 entity status field by applying changes from the input_li to the dv_li

  Returns: List of strings representing the fields to patch
  """
def handle_entity_status(input_li: dict[str, str], dv_li: dict[str, str]) -> list[str] {
    if 'Active' in input_li {
        if input_li['Active'] != '' {
            dv_li['entityStatus'] = 'ENTITY_STATUS_ACTIVE' if input_li['Active'] == 'TRUE' else 'ENTITY_STATUS_PAUSED';
            return ['entityStatus'];
        }
    }
    return [];
}