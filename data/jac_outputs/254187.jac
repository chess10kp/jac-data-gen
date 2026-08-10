"""Removes all placeholder peaks from an iterable of peaks

Parameters
----------
peaks : Iterable of FittedPeak

Returns
-------
list
"""
def drop_placeholders(peaks: list) -> list {
    return [
        peak
        for peak in peaks
        if peak.mz > 1 and peak.intensity > 1
    ];
}