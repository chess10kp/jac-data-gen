cl {
    import from ".components.ui.button" { Button }
    import from ".components.ui.dropdown-menu" { DropdownMenu, DropdownMenuTrigger, DropdownMenuContent }

    def:pub MyPage() -> JsxElement {
        return <div>
            <Button variant="outline">Click me</Button>
        </div>;
    }
}
