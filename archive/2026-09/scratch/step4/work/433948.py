def ContentTypeTranslation(content_type):
  """Translate content type from gcloud format to API format.

  Args:
    content_type: the gcloud format of content_type

  Returns:
    cloudasset API format of content_type.
  """
  if content_type == 'resource':
    return 'RESOURCE'
  if content_type == 'iam-policy':
    return 'IAM_POLICY'
  if content_type == 'org-policy':
    return 'ORG_POLICY'
  if content_type == 'access-policy':
    return 'ACCESS_POLICY'
  if content_type == 'os-inventory':
    return 'OS_INVENTORY'
  if content_type == 'relationship':
    return 'RELATIONSHIP'
  return 'CONTENT_TYPE_UNSPECIFIED'

assert ContentTypeTranslation('access-policy') == 'ACCESS_POLICY'
assert ContentTypeTranslation('org-policy') == 'ORG_POLICY'
assert ContentTypeTranslation('resource') == 'RESOURCE'
assert ContentTypeTranslation('abc') == 'CONTENT_TYPE_UNSPECIFIED'
assert ContentTypeTranslation('iam-policy') == 'IAM_POLICY'
assert ContentTypeTranslation('not-a-content-type') == 'CONTENT_TYPE_UNSPECIFIED'
assert ContentTypeTranslation('os-inventory') == 'OS_INVENTORY'
assert ContentTypeTranslation('relationship') == 'RELATIONSHIP'
