sv import from ...main { submit_data }

cl {
    def:pub SafeSubmit() -> JsxElement {
        has error_msg: str = "";
        has submitting: bool = False;

        async def handle_submit(data: dict) -> None {
            submitting = True;
            error_msg = "";

            try {
                result = root spawn submit_data(payload=data);
                if result.reports and result.reports.length > 0 {
                    response = result.reports[0];
                    if not response.get("success") {
                        error_msg = response.get("error", "Submission failed");
                    }
                }
            } except Exception as e {
                error_msg = f"Network error: {e}";
            }

            submitting = False;
        }

        return <div>
            {error_msg and <div className="error">{error_msg}</div>}
            <button
                onClick={lambda -> None { handle_submit({"key": "value"}); }}
                disabled={submitting}
            >
                {("Submitting..." if submitting else "Submit")}
            </button>
        </div>;
    }
}
