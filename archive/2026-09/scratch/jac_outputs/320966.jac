"""Displays a progress bar with the print function."""
def text_progress_bar(iteration: int, num_iteration: int) -> None {
    return print(
        '|' * (iteration + 1) + '.' * (num_iteration - iteration - 1) + ' %.1f %%' % ((iteration + 1) / num_iteration * 100),
        end='\r'
    );
}