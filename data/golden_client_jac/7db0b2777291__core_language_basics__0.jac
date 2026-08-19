enum HttpStatus {
    OK = 200,
    NOT_FOUND = 404

    ::py::
    def is_success(self):
        return 200 <= self.value < 300

    @property
    def message(self):
        return {200: "OK", 404: "Not Found"}.get(self.value, "Unknown")
    ::py::
}
