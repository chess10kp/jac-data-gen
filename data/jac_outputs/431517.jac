"""Convert string with host IDs into list of hosts.

    Example: Cobalt RM would have host template as 'nid%05d'
                get_hostlist_by_range('1-3,5', prefix='nid', width=5) =>
                ['nid00001', 'nid00002', 'nid00003', 'nid00005']
    """
def get_hostlist_by_range(hoststring: str, prefix: str = '', width: int = 0) -> list[str] {
    if not hoststring.replace('-', '').replace(',', '').isnumeric() {
        raise ValueError('non numeric set of ranges (%s)' % hoststring);
    }
    host_ids = [];
    id_width = 0;
    for num in hoststring.split(',') {
        num_range = num.split('-');
        if len(num_range) > 1 {
            (num_lo, num_hi) = num_range;
            if not num_lo or not num_hi {
                raise ValueError('incorrect range format (%s)' % num);
            }
            host_ids.extend(list(range(int(num_lo), int(num_hi) + 1)));
        } else {
            host_ids.append(int(num_range[0]));
        }
        id_width = max(id_width, *[len(n) for n in num_range]);
    }
    width = width or id_width;
    return [('%s%0*d' % (prefix, width, hid)) for hid in host_ids];
}