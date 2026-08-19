def:pub Tab(props: any) -> JsxElement {
    activeCls = "border-primary text-foreground";
    inactiveCls = "border-transparent text-muted-foreground hover:text-foreground";

    return <button
        type="button"
        className={"px-2.5 py-1.5 text-sm font-medium border-b-2 " +
            (activeCls if props.active else inactiveCls)}
        onClick={props.onClick}
    >
        {props.children}
    </button>;
}
