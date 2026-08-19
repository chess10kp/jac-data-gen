obj Rectangle {
    has width: float;
    has height: float;
    has area: float by postinit;

    def postinit {
        self.area = self.width * self.height;
    }
}
