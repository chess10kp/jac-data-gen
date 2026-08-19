import from ".ui.card" { Card, CardHeader, CardTitle, CardContent }
import from ".ui.button" { Button }
import from ".ui.badge" { Badge }
import from ".ui.table" { Table, TableHeader, TableBody, TableRow, TableHead, TableCell }
import from ".ui.dialog" { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle }
import from ".ui.spinner" { Spinner }
import from "..lib.utils" { cn }
cl import from "@hugeicons/react" { HugeiconsIcon }
cl import from "@hugeicons/core-free-icons" { Add01Icon }

def:pub EventListPage() -> JsxElement {
    has events: list = [];
    has loading: bool = True;

    async can with entry {
        # sv import RPC call goes here
        loading = False;
    }

    if loading {
        return <div className="flex items-center justify-center p-8">
            <Spinner />
        </div>;
    }

    return <div className="flex flex-col gap-6 p-6">
        <div className="flex items-center justify-between">
            <h1 className="text-2xl font-semibold">Events</h1>
            <Dialog>
                <DialogTrigger asChild={True}>
                    <Button>
                        <HugeiconsIcon icon={Add01Icon} strokeWidth={2} className="size-4" />
                        New Event
                    </Button>
                </DialogTrigger>
                <DialogContent>
                    <DialogHeader>
                        <DialogTitle>Create Event</DialogTitle>
                    </DialogHeader>
                </DialogContent>
            </Dialog>
        </div>
        <Card>
            <CardHeader>
                <CardTitle>Upcoming Events</CardTitle>
            </CardHeader>
            <CardContent>
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Name</TableHead>
                            <TableHead>Status</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {for e in events {
                            if e != None {
                                <TableRow key={e["id"]}>
                                    <TableCell>{e["name"]}</TableCell>
                                    <TableCell>
                                        <Badge variant="outline">{e["status"]}</Badge>
                                    </TableCell>
                                </TableRow>
                            }
                        }}
                    </TableBody>
                </Table>
            </CardContent>
        </Card>
    </div>;
}
