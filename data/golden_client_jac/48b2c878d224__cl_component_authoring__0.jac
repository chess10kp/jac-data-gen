import from ".ui.button" { Button, buttonVariants }
import from ".ui.dropdown-menu" { DropdownMenuTrigger }
cl import from "@hugeicons/react" { HugeiconsIcon }
cl import from "@hugeicons/core-free-icons" { Add01Icon, SearchIcon, MoreVerticalIcon }

# Inline icon
def:pub InlineIconExample() -> JsxElement {
    return <HugeiconsIcon icon={SearchIcon} strokeWidth={2} className="size-4" />;
}

# Icon-only button
def:pub IconButtonExample() -> JsxElement {
    return <Button size="icon">
        <HugeiconsIcon icon={Add01Icon} strokeWidth={2} />
    </Button>;
}

# Radix trigger - no forwardRef, apply buttonVariants() directly
def:pub RadixTriggerExample() -> JsxElement {
    return <DropdownMenuTrigger className={buttonVariants().call(None, {"variant": "ghost", "size": "icon"})}>
        <HugeiconsIcon icon={MoreVerticalIcon} strokeWidth={2} className="size-4" />
    </DropdownMenuTrigger>;
}
