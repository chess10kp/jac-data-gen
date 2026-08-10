"""Get features to be generated for a type."""
def get_features_for_type(column_type: str) -> list[str | tuple[str, str, str]] {
    lookup_table = dict();
    lookup_table['STR_EQ_1W'] = [
        'lev_dist',
        'lev_sim',
        'jaro',
        'jaro_winkler',
        'exact_match',
        ('jaccard', 'qgm_3', 'qgm_3')
    ];
    lookup_table['STR_BT_1W_5W'] = [
        ('jaccard', 'qgm_3', 'qgm_3'),
        ('cosine', 'dlm_dc0', 'dlm_dc0'),
        ('jaccard', 'dlm_dc0', 'dlm_dc0'),
        'monge_elkan',
        'lev_dist',
        'lev_sim',
        'needleman_wunsch',
        'smith_waterman'
    ];
    lookup_table['STR_BT_5W_10W'] = [
        ('jaccard', 'qgm_3', 'qgm_3'),
        ('cosine', 'dlm_dc0', 'dlm_dc0'),
        'monge_elkan',
        'lev_dist',
        'lev_sim'
    ];
    lookup_table['STR_GT_10W'] = [
        ('jaccard', 'qgm_3', 'qgm_3'),
        ('cosine', 'dlm_dc0', 'dlm_dc0')
    ];
    lookup_table['NUM'] = ['exact_match', 'abs_norm', 'lev_dist', 'lev_sim'];
    lookup_table['BOOL'] = ['exact_match'];
    lookup_table['UN_DETERMINED'] = [];
    match column_type {
        case 'str_eq_1w':
            return lookup_table['STR_EQ_1W'];
        case 'str_bt_1w_5w':
            return lookup_table['STR_BT_1W_5W'];
        case 'str_bt_5w_10w':
            return lookup_table['STR_BT_5W_10W'];
        case 'str_gt_10w':
            return lookup_table['STR_GT_10W'];
        case 'numeric':
            return lookup_table['NUM'];
        case 'boolean':
            return lookup_table['BOOL'];
        case 'un_determined':
            return lookup_table['UN_DETERMINED'];
        case _:
            raise TypeError('Unknown type');
    }
}