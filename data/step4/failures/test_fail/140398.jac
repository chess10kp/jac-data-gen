"""
    Return the GraphQL datasetAssets query
    """
def gql_assets(fragment: Any) -> object {
    return f'''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {{{{
  data: datasetAssets(where: $where, skip: $skip, first: $first) {{{{
    {fragment}
  }}}}
}}}}
''';
}

test "t0" {
    assert (
        gql_assets('id name')
        == '''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {
  data: datasetAssets(where: $where, skip: $skip, first: $first) {
    id name
  }
}
'''
    );;
}

test "t1" {
    assert (
        gql_assets(
            '''
   ...AssetFields
   ... on DatasetAsset {
       ...AssetFields
    }
    '''
        )
        == gql_assets(
            '''
   ...AssetFields
   ... on DatasetAsset {
       ...AssetFields
    }
    '''
        )
    );;
}

test "t2" {
    assert (
        gql_assets('id')
        == '''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {
  data: datasetAssets(where: $where, skip: $skip, first: $first) {
    id
  }
}
'''
    );;
}

test "t3" {
    assert (
        gql_assets(
            '''
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
    '''
        )
        == gql_assets(
            '''
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
   ...AssetFields
    '''
        )
    );;
}

test "t4" {
    assert (
        gql_assets("""id name type size assetPath label assetPath""")
        == '''
query($where: DatasetAssetWhere!, $first: PageSize!, $skip: Int!) {
  data: datasetAssets(where: $where, skip: $skip, first: $first) {
    id name type size assetPath label assetPath
  }
}
'''
    );;
}
