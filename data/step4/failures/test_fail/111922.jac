"""Formats an Omniglot input into a standard format.

  The formatted sample will have two keys: 'image', containing the input image,
  and 'label' containing the label.

  Args:
    data: dict, a sample from the Omniglot dataset. Contains keys: 'image',
      'alphabet' and 'alphabet_char_id'.

  Returns:
    Formatted `data` dict.
  """
def format_omniglot(data: Any) -> object {
    data['label'] = data['alphabet_char_id'];
    delete(data['alphabet_char_id'],);
    delete(data['alphabet'],);
    return data;
}

test "t0" {
    assert (
        format_omniglot(
            {
                'alphabet_char_id': 'alphabet_char_id_data',
                'image': 'image_data',
                'alphabet': 'alphabet_data'
            }
        )
        == {'image': 'image_data', 'label': 'alphabet_char_id_data'}
    );;
}

test "t1" {
    assert (
        format_omniglot({'image': 'image_a', 'alphabet': 'a', 'alphabet_char_id': 1})
        == {'image': 'image_a', 'label': 1}
    );;
}

test "t2" {
    assert (
        format_omniglot(
            {'image': [1, 2, 3, 4, 5], 'alphabet_char_id': 10, 'alphabet': 300}
        )
        == {'image': [1, 2, 3, 4, 5], 'label': 10}
    );;
}

test "t3" {
    assert (
        format_omniglot({'image': None, 'alphabet': 'a', 'alphabet_char_id': None})
        == {'image': None, 'label': None}
    );;
}

test "t4" {
    assert (
        format_omniglot(
            {
                'image': 'dummy_image',
                'alphabet': 'dummy_alphabet',
                'alphabet_char_id': 0
            }
        )
        == {'image': 'dummy_image', 'label': 0}
    );;
}

test "t5" {
    assert (
        format_omniglot({'image': 'image_c', 'alphabet': 'c', 'alphabet_char_id': 3})
        == {'image': 'image_c', 'label': 3}
    );;
}

test "t6" {
    assert (
        format_omniglot({'alphabet_char_id': 1, 'alphabet': 2, 'image': 3})
        == {'image': 3, 'label': 1}
    );;
}

test "t7" {
    assert (
        format_omniglot(
            {
                'alphabet_char_id': 'alphabet_char_id_data',
                'alphabet': 'alphabet_data',
                'image': 'image_data'
            }
        )
        == {'image': 'image_data', 'label': 'alphabet_char_id_data'}
    );;
}

test "t8" {
    assert (
        format_omniglot({'image': 1, 'alphabet': 2, 'alphabet_char_id': 3})
        == {'image': 1, 'label': 3}
    );;
}

test "t9" {
    assert (
        format_omniglot(
            {'alphabet': 'japonicus', 'alphabet_char_id': 4, 'image': 'jap_char4.png'}
        )
        == {'label': 4, 'image': 'jap_char4.png'}
    );;
}

test "t10" {
    assert (
        format_omniglot(
            {
                'image': 'image_data',
                'alphabet': 'alphabet_data',
                'alphabet_char_id': 'alphabet_char_id_data'
            }
        )
        == {'image': 'image_data', 'label': 'alphabet_char_id_data'}
    );;
}

test "t11" {
    assert (
        format_omniglot(
            {'image': [1, 2, 3, 4, 5], 'alphabet_char_id': 0, 'alphabet': 2000}
        )
        == {'image': [1, 2, 3, 4, 5], 'label': 0}
    );;
}

test "t12" {
    assert (
        format_omniglot(
            {'alphabet': 'japonicus', 'alphabet_char_id': 3, 'image': 'jap_char3.png'}
        )
        == {'label': 3, 'image': 'jap_char3.png'}
    );;
}

test "t13" {
    assert (
        format_omniglot({'image': 2, 'alphabet': 3, 'alphabet_char_id': 4})
        == {'image': 2, 'label': 4}
    );;
}

test "t14" {
    assert (
        format_omniglot(
            {
                'alphabet': 'alphabet_data',
                'alphabet_char_id': 'alphabet_char_id_data',
                'image': 'image_data'
            }
        )
        == {'image': 'image_data', 'label': 'alphabet_char_id_data'}
    );;
}

test "t15" {
    assert (
        format_omniglot({'image': 'image_b', 'alphabet': 'b', 'alphabet_char_id': 2})
        == {'image': 'image_b', 'label': 2}
    );;
}

test "t16" {
    assert (
        format_omniglot(
            {'image': [1, 2, 3, 4, 5], 'alphabet_char_id': 1, 'alphabet': 100}
        )
        == {'image': [1, 2, 3, 4, 5], 'label': 1}
    );;
}

test "t17" {
    assert (
        format_omniglot(
            {'alphabet': 'japonicus', 'alphabet_char_id': 2, 'image': 'jap_char2.png'}
        )
        == {'label': 2, 'image': 'jap_char2.png'}
    );;
}
