# components/ui/dialog.cl.jac
import from "radix-ui" { Dialog as DialogPrimitive }
import from ...lib.utils { cn }

def:pub Dialog(props: any) -> JsxElement {
    return <DialogPrimitive.Root {**props}>
        {props.children}
    </DialogPrimitive.Root>;
}

def:pub DialogTrigger(props: any) -> JsxElement {
    return <DialogPrimitive.Trigger {**props}>
        {props.children}
    </DialogPrimitive.Trigger>;
}

def:pub DialogContent(props: any) -> JsxElement {
    return <DialogPrimitive.Portal>
        <DialogPrimitive.Overlay
            className={cn("fixed inset-0 z-50 bg-black/50", props.overlayClassName)}
        />
        <DialogPrimitive.Content
            className={cn(
                "fixed left-1/2 top-1/2 z-50 -translate-x-1/2 -translate-y-1/2",
                "w-full max-w-lg rounded-lg bg-background p-6 shadow-lg",
                props.className
            )}
        >
            {props.children}
        </DialogPrimitive.Content>
    </DialogPrimitive.Portal>;
}
