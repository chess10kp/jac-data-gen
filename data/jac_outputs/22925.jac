"""Get gaps merged across channels/streams
    Parameters
    ----------
    gaps: dictionary
        contains channel/gap array pairs

    Returns
    -------
    array_like
        an array of startime/endtime arrays representing gaps.

    Notes
    -----
    Takes an dictionary of gaps, and merges those gaps across channels,
        returning an array of the merged gaps.
    """
def get_merged_gaps(gaps: dict[str, list[list[float]]]) -> list[list[float]] {
    merged_gaps = [];
    for key in gaps {
        merged_gaps.extend(gaps[key]);
    }
    sorted_gaps: list[list[float]] = sorted(merged_gaps, key=lambda (gap: list[float]) { gap[0]; });
    merged_gaps = [];
    merged_gap: list[float] | None = None;
    for gap in sorted_gaps {
        if merged_gap is None {
            merged_gap = gap;
        } elif gap[0] > merged_gap[2] {
            merged_gaps.append(merged_gap as list[float]);
            merged_gap = gap;
        } elif gap[0] <= merged_gap[2] {
            if gap[1] > merged_gap[1] {
                merged_gap[1] = gap[1];
                merged_gap[2] = gap[2];
            }
        }
    }
    if merged_gap is not None {
        merged_gaps.append(merged_gap);
    }
    return merged_gaps;
}