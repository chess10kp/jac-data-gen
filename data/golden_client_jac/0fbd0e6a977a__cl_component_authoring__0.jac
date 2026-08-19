import from "clsx" { clsx }
import from "tailwind-merge" { twMerge }

# Variadic positional args (the clsx / tailwind-merge convention, and how
# jac-shadcn components call cn) - NOT a single list argument.
def:pub cn(*inputs: any) -> any {
    return twMerge(clsx(inputs));
}
