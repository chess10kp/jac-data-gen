# lib/utils.cl.jac
cl import from "clsx" { clsx }
cl import from "tailwind-merge" { twMerge }

def:pub cn(*inputs: any) -> str {
    return twMerge(clsx(inputs));
}
