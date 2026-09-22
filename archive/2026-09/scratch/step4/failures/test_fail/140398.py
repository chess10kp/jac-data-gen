def gql_assets(fragment):
    """
    Return the GraphQL datasetAssets query
    """
    return f'''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {{
  data: datasetAssets(where: $where, skip: $skip, first: $first) {{
    {fragment}
  }}
}}
'''

assert gql_assets(
    'id name'
) == '''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {
  data: datasetAssets(where: $where, skip: $skip, first: $first) {
    id name
  }
}
'''
assert gql_assets(
    '''
   ...AssetFields
   ... on DatasetAsset {
       ...AssetFields
    }
    '''
) == gql_assets(
    '''
   ...AssetFields
   ... on DatasetAsset {
       ...AssetFields
    }
    '''
)
assert gql_assets(
    'id'
) == '''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {
  data: datasetAssets(where: $where, skip: $skip, first: $first) {
    id
  }
}
'''
assert gql_assets(
    '''
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
    '''
) == gql_assets(
    '''
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
    '''
)
assert gql_assets(
    """id name type size assetPath label assetPath"""
) == '''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {
  data: datasetAssets(where: $where, skip: $skip, first: $first) {
    id name type size assetPath label assetPath
  }
}
'''
