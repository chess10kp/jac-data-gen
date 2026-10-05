"""Cold Lake pipeline spill Sentinel-2 RGB demo.

Run: jac run cold_lake_demo.jac
"""

import from tools { classify_pipeline_spill_series, PipelineSpillBatchResult }

with entry {
    print("[orion] Fetching Cold Lake Sentinel-2 RGB image series...");

    batch: PipelineSpillBatchResult = classify_pipeline_spill_series(
        lat=54.675,
        lon=-110.511,
        start_date="2026-01-01",
        end_date="2026-06-01",
        output_dir="outputs/cold_lake_series",
        max_images=15,
        buffer_meters=10000,
        dimensions=512
    );

    print("");
    print("--- Pipeline Spill RGB Batch Classification ---");
    print(f"Images classified : {batch.image_count}");
    print(f"Positive images   : {batch.positive_count}");
    print(f"Highest confidence: {batch.highest_confidence:.0%}");

    for result in batch.results {
        print("");
        print(f"Image saved    : {result.image_path}");
        print(f"Image bytes    : {result.byte_count}");
        print(f"Spill detected : {result.spill_detected}");
        print(f"Confidence     : {result.confidence:.0%}");
        print(f"Reasoning      : {result.reasoning}");
    }
}
