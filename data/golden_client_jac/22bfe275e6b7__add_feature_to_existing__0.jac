has perimeter: float;
def postinit {
    self.area = self.width * self.height;
    self.perimeter = 2 * (self.width + self.height);
}
