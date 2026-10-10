from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from services import recommender as recommender_service
from services import storage

router = APIRouter()


class RecommendationsRequest(BaseModel):
    analysis_ids: list[str]


@router.post("/recommendations")
def generate_recommendations(body: RecommendationsRequest, force: bool = Query(False)):
    if not body.analysis_ids:
        raise HTTPException(400, "At least one analysis_id is required")

    records = []
    for rid in body.analysis_ids:
        record = storage.load_analysis(rid)
        if record is None:
            raise HTTPException(404, f"Analysis {rid} not found")
        records.append(record)

    # Return cached result if available (unless force=true)
    if not force and len(records) == 1 and records[0].recommendations is not None:
        return records[0].recommendations.model_dump(mode="json")

    try:
        result = recommender_service.generate_recommendations(records)
    except (RuntimeError, ValueError) as e:
        raise HTTPException(502, f"Recommendation generation failed: {e}") from e

    # Persist back to each analysis file
    for record in records:
        storage.patch_recommendations(record.id, result)

    return result.model_dump(mode="json")
