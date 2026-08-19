@restspec(protocol=APIProtocol.WEBSOCKET)
walker:pub EchoMessage {
    has message: str;
    has client_id: str = "anonymous";

    can echo with Root entry {
        report {
            "echo": self.message,
            "client_id": self.client_id
        };
    }
}
