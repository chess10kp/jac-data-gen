"""Estimate potential cost of performing an entire conversion on S3 using full automation."""
def estimate_s3_conversion_cost(
    total_mb: float,
    transfer_rate_mb: float = 20.0,
    conversion_rate_mb: float = 17.0,
    upload_rate_mb: float = 40,
    compression_ratio: float = 1.7
) -> float {
    c = 1 / compression_ratio;
    total_mb_s = (
        total_mb ** 2 / 2
        * (
            1 / transfer_rate_mb
            + (2 * c + 1) / conversion_rate_mb
            + 2 * c ** 2 / upload_rate_mb
        )
    );
    cost_gb_m = 0.08 / 1000.0;
    cost_mb_s = cost_gb_m / (1000.0 * 2628000.0);
    return cost_mb_s * total_mb_s;
}