"""Standard API response type shapes for AgeWise endpoints."""

# Standard response envelope fields
glob RESPONSE_FIELDS: list[str] = [
    "success",
    "data",
    "error",
    "message",
    "timestamp",
    "request_id"
];

# Walker execution response shape
glob WALKER_RESPONSE_SHAPE: dict = {
    "success": True,
    "walker": "",
    "node_id": "",
    "reports": [],
    "errors": [],
    "duration_ms": 0
};
# Patient summary response shape
glob PATIENT_SUMMARY_SHAPE: dict = {
    "patient_id": "",
    "name": "",
    "open_disputes": 0,
    "total_disputed_amount": 0.0,
    "upcoming_deadlines": [],
    "recent_notifications": [],
    "active_appeals": 0,
    "documents_pending_review": 0
};
# Dispute detail response shape
glob DISPUTE_DETAIL_SHAPE: dict = {
    "dispute_id": "",
    "error_type": "",
    "description": "",
    "amount_disputed": 0.0,
    "status": "",
    "appeal_level": 0,
    "deadline": "",
    "confidence_score": 0.0,
    "severity": "",
    "citations": [],
    "created_at": ""
};
# Webhook event types
glob WEBHOOK_EVENTS: list[str] = [
    "patient.document_processed",
    "dispute.created",
    "dispute.status_changed",
    "appeal.letter_generated",
    "appeal.deadline_approaching",
    "call.completed",
    "call.failed",
    "bill.due_soon",
    "legal.document_expiring",
    "scam.detected"
];

# HTTP status codes used
glob HTTP_STATUS: dict = {
    "OK": 200,
    "CREATED": 201,
    "ACCEPTED": 202,
    "NO_CONTENT": 204,
    "BAD_REQUEST": 400,
    "UNAUTHORIZED": 401,
    "FORBIDDEN": 403,
    "NOT_FOUND": 404,
    "CONFLICT": 409,
    "UNPROCESSABLE": 422,
    "TOO_MANY_REQUESTS": 429,
    "SERVER_ERROR": 500,
    "SERVICE_UNAVAILABLE": 503
};