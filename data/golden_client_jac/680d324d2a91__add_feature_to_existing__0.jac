async def toggle(id: str) {
    await toggle_task(id);
}
<input type="checkbox" checked={t.done} onChange={lambda { toggle(jid(t)); }}/>
