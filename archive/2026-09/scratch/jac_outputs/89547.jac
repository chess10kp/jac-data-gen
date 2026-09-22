"""Find the tier for the given endurance volume (IOPS per GB)

:param volume: The volume for which the tier level is desired
:return: Returns a float value indicating the IOPS per GB for the volume
"""
def find_endurance_tier_iops_per_gb(volume: dict[str, dict[str, str]]) -> float {
    tier_description_split = volume['storageTierLevel']['description'].split();
    if tier_description_split != [] {
        iops_per_gb = tier_description_split[0];
        if iops_per_gb == '0.25' {
            return 0.25;
        }
        if iops_per_gb == '2' {
            return 2.0;
        }
        if iops_per_gb == '4' {
            return 4.0;
        }
        if iops_per_gb == '10' {
            return 10.0;
        }
    }
    raise ValueError("Could not find tier IOPS per GB for this volume");
}