"""Creates the shortform version of the block annotation
    using information from the sequence dictionary.

    Parameters
    ----------
    d : dict
        Dictionary representation individuals entries in a FASTA file.

    Returns
    -------
    str

    """
def encode_shortform_block_annotation(d: Any) -> object {
    template = '{ref_version}_{chr_loc}_{chr_scaffold}_{ori}_{gpos_oneb}_'
    '{num_blocks}_{blocks}';
    try {
        return template.format(
            ref_version=d['ref_version'],
            chr_loc=d['chromosome'],
            chr_scaffold=d['chromosome_scaffold'],
            ori=d['orientation'],
            gpos_oneb=(d['genome_pos'] + 1),
            num_blocks=len(d['blocks']),
            blocks=';'.join(
                ['{}:{}'.format((s[0].start + 1), s[0].stop) for s in d['blocks']]
            )
        );
    } except KeyError {
        return '';
    }
}