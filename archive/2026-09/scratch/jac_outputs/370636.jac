"""Builds the operations needed to create Negative Campaign Criterion.

  Args:
    campaign_operations: a list containing the operations that will add
      Campaigns.

  Returns:
    a list containing the operations that will create a new Negative Campaign
    Criterion associated with each provided Campaign.
  """
def BuildCampaignCriterionOperations(campaign_operations: Any) -> object {
    criterion_operations = [
        {
            'xsi_type': 'CampaignCriterionOperation',
            'operand': {
                'xsi_type': 'NegativeCampaignCriterion',
                'campaignId': campaign_operation['operand']['id'],
                'criterion': {
                    'xsi_type': 'Keyword',
                    'matchType': 'BROAD',
                    'text': 'venus'
                }
            },
            'operator': 'ADD'
        } for campaign_operation in campaign_operations
    ];
    return criterion_operations;
}