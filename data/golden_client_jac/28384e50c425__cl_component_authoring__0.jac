# components/ui/button.cl.jac
import from "class-variance-authority" { cva }
import from ...lib.utils { cn }

glob _buttonVariants: any = cva(
    "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors",
    {
        "variants": {
            "variant": {
                "default": "bg-primary text-primary-foreground hover:bg-primary/80",
                "outline": "border border-border bg-background hover:bg-muted",
                "ghost": "hover:bg-muted hover:text-foreground",
                "destructive": "bg-destructive/10 hover:bg-destructive/20 text-destructive"
            },
            "size": {
                "default": "h-8 gap-1.5 px-2.5",
                "sm": "h-7 gap-1 px-2.5 text-xs",
                "lg": "h-10 gap-2 px-4",
                "icon": "size-8"
            }
        },
        "defaultVariants": {
            "variant": "default",
            "size": "default"
        }
    }
);

def:pub Button(props: any) -> JsxElement {
    variant = props.variant or "default";
    size = props.size or "default";
    computedClass = cn(
        _buttonVariants.call(None, {"variant": variant, "size": size}),
        props.className
    );

    return <button className={computedClass} {**props}>
        {props.children}
    </button>;
}
