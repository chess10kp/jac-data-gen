"""Builds the operations adding a Keyword Criterion to each AdGroup.

  Args:
    adgroup_operations: a list containing the operations that will add AdGroups.
    number_of_keywords: an int defining the number of Keywords to be created.

  Returns:
    a list containing the operations that will create a new Keyword Criterion
    associated with each provided AdGroup.
  """
def BuildAdGroupCriterionOperations(adgroid: list[int], keywo: list[str]) -> list[dict[str, str | int | dict[str, str | int | dict[str, str]]]] {
    criterion_operations = [
        {
            'xsi_type': 'AdGroupCriterionOperation',
            'operand': {
                'xsi_type': 'BiddableAdGroupCriterion',
                'adGroupId': adgroid[i],
                'criterion': {
                    'xsi_type': 'Keyword',
                    'text': keywo[i],
                    'matchType': 'EXACT'
                }
            },
            'operator': 'ADD'
        } for i in range(0, len(adgroid))
    ];
    return criterion_operations;
}