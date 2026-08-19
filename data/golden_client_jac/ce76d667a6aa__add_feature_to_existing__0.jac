has show_done: bool = True;
...
<input type="checkbox" checked={show_done}
    onChange={lambda { show_done = not show_done; }}/>
