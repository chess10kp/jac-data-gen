cl {
    def:pub ContactForm() -> JsxElement {
        has form_data: dict = {
            "name": "",
            "email": "",
            "message": ""
        };
        has errors: dict = {};
        has submitting: bool = False;

        def update_field(field: str, value: str) -> None {
            form_data = {**form_data, field: value};
        }

        def validate() -> bool {
            new_errors = {};
            if not form_data["name"] {
                new_errors["name"] = "Name is required";
            }
            if "@" not in form_data["email"] {
                new_errors["email"] = "Invalid email";
            }
            if not form_data["message"] {
                new_errors["message"] = "Message is required";
            }
            errors = new_errors;
            return len(new_errors) == 0;
        }

        def handle_submit() -> None {
            if validate() {
                submitting = True;
            }
        }

        return <form>
            <input
                value={form_data["name"]}
                onChange={lambda e: ChangeEvent { update_field("name", e.target.value); }}
            />
            {errors.get("name") and <span className="error">{errors["name"]}</span>}
        </form>;
    }
}
