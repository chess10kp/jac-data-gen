"""Calculate gas hourly space velocity [1/h]."""
def calGasHourlySpaceVelocity(VoFlRa: float, ReVo: float) -> float | None {
    try {
        return VoFlRa / ReVo;
    } except Exception as e {
        print(e);
    }
}