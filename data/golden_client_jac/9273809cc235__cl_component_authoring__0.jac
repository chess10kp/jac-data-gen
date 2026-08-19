cl {
    def:pub Notification(count: int) -> JsxElement {
        return <div>
            {count > 0 and <span>You have {count} messages</span>}
        </div>;
    }
}
