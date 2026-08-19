glob MAX_MESSAGE_LEN: int = 2000;

@restspec(protocol=APIProtocol.WEBSOCKET, broadcast=True)
async walker:pub ChatRoom {
    has message: str;
    has sender: str = "anonymous";

    async can handle with Root entry {
        trimmed = self.message.strip();
        if not trimmed {
            report {"type": "error", "reason": "empty message"};
            return;
        }
        if len(trimmed) > MAX_MESSAGE_LEN {
            report {"type": "error", "reason": "message too long"};
            return;
        }

        report {
            "type": "message",
            "sender": self.sender,
            "content": trimmed
        };
    }
}
