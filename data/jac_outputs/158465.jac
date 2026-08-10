"""Learning Rate Schedule."""
def lr_schedule(epoch: int, lr: float = 0.01) -> float {
    if epoch > 50 {
        if epoch % 10 == 9 {
            lr *= 0.0005;
        } elif 6 <= epoch % 10 < 9 {
            lr *= 0.001;
        } elif 3 <= epoch % 10 < 6 {
            lr *= 0.01;
        } elif epoch % 10 < 3 {
            lr *= 0.1;
        }
    }
    print('Learning rate: ', lr);
    return lr;
}