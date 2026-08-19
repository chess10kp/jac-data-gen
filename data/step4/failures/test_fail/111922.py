def format_omniglot(data):
  """Formats an Omniglot input into a standard format.

  The formatted sample will have two keys: 'image', containing the input image,
  and 'label' containing the label.

  Args:
    data: dict, a sample from the Omniglot dataset. Contains keys: 'image',
      'alphabet' and 'alphabet_char_id'.

  Returns:
    Formatted `data` dict.
  """
  data['label'] = data['alphabet_char_id']

  del data['alphabet_char_id']
  del data['alphabet']

  return data

assert format_omniglot(
  {'alphabet_char_id': 'alphabet_char_id_data', 'image': 'image_data', 'alphabet': 'alphabet_data'}) == {
    'image': 'image_data', 'label': 'alphabet_char_id_data'}
assert format_omniglot(
    {'image': 'image_a', 'alphabet': 'a', 'alphabet_char_id': 1}) == {
        'image': 'image_a', 'label': 1}
assert format_omniglot(
    {'image': [1, 2, 3, 4, 5], 'alphabet_char_id': 10, 'alphabet': 300}) == {
        'image': [1, 2, 3, 4, 5], 'label': 10
    }
assert format_omniglot({'image': None, 'alphabet': 'a', 'alphabet_char_id': None}) == {
    'image': None, 'label': None}
assert format_omniglot(
    {'image': 'dummy_image', 'alphabet': 'dummy_alphabet', 'alphabet_char_id': 0}) == {
        'image': 'dummy_image', 'label': 0}
assert format_omniglot(
    {'image': 'image_c', 'alphabet': 'c', 'alphabet_char_id': 3}) == {
        'image': 'image_c', 'label': 3}
assert format_omniglot(
    {'alphabet_char_id': 1, 'alphabet': 2, 'image': 3}) == {
        'image': 3,
        'label': 1
    }
assert format_omniglot(
  {'alphabet_char_id': 'alphabet_char_id_data', 'alphabet': 'alphabet_data', 'image': 'image_data'}) == {
    'image': 'image_data', 'label': 'alphabet_char_id_data'}
assert format_omniglot({
    'image': 1,
    'alphabet': 2,
    'alphabet_char_id': 3
}) == {'image': 1, 'label': 3}
assert format_omniglot(
  {'alphabet': 'japonicus', 'alphabet_char_id': 4, 'image': 'jap_char4.png'}
) == {
  'label': 4,
  'image': 'jap_char4.png'
}
assert format_omniglot(
  {'image': 'image_data', 'alphabet': 'alphabet_data', 'alphabet_char_id': 'alphabet_char_id_data'}) == {
    'image': 'image_data', 'label': 'alphabet_char_id_data'}
assert format_omniglot(
    {'image': [1, 2, 3, 4, 5], 'alphabet_char_id': 0, 'alphabet': 2000}) == {
        'image': [1, 2, 3, 4, 5], 'label': 0
    }
assert format_omniglot(
  {'alphabet': 'japonicus', 'alphabet_char_id': 3, 'image': 'jap_char3.png'}
) == {
  'label': 3,
  'image': 'jap_char3.png'
}
assert format_omniglot({'image': 2, 'alphabet': 3, 'alphabet_char_id': 4}) == {'image': 2, 'label': 4}
assert format_omniglot(
  {'alphabet': 'alphabet_data', 'alphabet_char_id': 'alphabet_char_id_data', 'image': 'image_data'}) == {
    'image': 'image_data', 'label': 'alphabet_char_id_data'}
assert format_omniglot(
    {'image': 'image_b', 'alphabet': 'b', 'alphabet_char_id': 2}) == {
        'image': 'image_b', 'label': 2}
assert format_omniglot(
    {'image': [1, 2, 3, 4, 5], 'alphabet_char_id': 1, 'alphabet': 100}) == {
        'image': [1, 2, 3, 4, 5], 'label': 1
    }
assert format_omniglot(
  {'alphabet': 'japonicus', 'alphabet_char_id': 2, 'image': 'jap_char2.png'}
) == {
  'label': 2,
  'image': 'jap_char2.png'
}
