walker DeleteCompleted {
    can prune with Task entry { if here.done { del here; } }
}
