# From a composite in components/ (the usual place for your components)
import from ".ui.button" { Button }
import from ".ui.card" { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter }
import from ".ui.dropdown-menu" {
    DropdownMenu, DropdownMenuTrigger, DropdownMenuContent, DropdownMenuGroup, DropdownMenuItem
}
import from ".ui.dialog" { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogFooter }
import from ".ui.table" { Table, TableHeader, TableBody, TableRow, TableHead, TableCell }

# cn() utility - always from lib/utils, never from @jac/runtime
import from "..lib.utils" { cn }

# npm packages (icons etc.) - always cl import, always a quoted bare-package string
cl import from "@hugeicons/react" { HugeiconsIcon }
cl import from "@hugeicons/core-free-icons" { SearchIcon, Add01Icon, Cancel01Icon, Menu01Icon }
