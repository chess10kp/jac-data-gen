def record(name: str, status: str, detail: str) -> None {
    self.results.append({"step": name, "status": status, "detail": detail});
    print(status + " " + name + " " + detail);
}
