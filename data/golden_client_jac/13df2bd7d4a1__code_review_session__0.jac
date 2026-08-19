# Named imports
cl import from "sonner" { toast as sonnerToast }
cl import from "clsx" { clsx }
cl import from "tailwind-merge" { twMerge }

# Scoped packages
cl import from "@monaco-editor/react" { Editor, DiffEditor }
cl import from "@hugeicons/react" { HugeiconsIcon }
cl import from "@hugeicons/core-free-icons" { File02Icon, Cancel01Icon }

# Radix UI primitives -- combined into one import from the same module
cl import from "radix-ui" { Dialog as DialogPrimitive, Select as SelectPrimitive }
