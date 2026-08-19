cl {
    def:pub Button(
        className: str = "",
        onClick: MouseEventHandler = None,
        children: any = None
    ) -> JsxElement {
        return <button className={className} onClick={onClick}>
            {children}
        </button>;
    }
}
