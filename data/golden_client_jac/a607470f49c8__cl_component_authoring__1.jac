"""cn() — merge Tailwind class strings across component boundaries.
clsx flattens/conditionals, twMerge resolves conflicting utilities (the caller's
className wins over a primitive's default). Only needed where classes cross a
component boundary; plain string concat inside one component stays as-is.
"""

import from "clsx" { clsx }
import from "tailwind-merge" { twMerge }

def:pub cn(*inputs: any) -> str {
    return str(twMerge(clsx(inputs)));
}
