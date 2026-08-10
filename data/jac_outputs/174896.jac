"""Radii of the cameras as defined in CTA-MARS.

These values are defined in the code of CTA-MARS.
They correspond to the radius of an equivalent FOV covering the same solid
angle.
"""
def CTAMARS_radii(camera_name: str) -> float {
    average_camera_radii_deg = {
        "ASTRICam": 4.67,
        "CHEC": 3.93,
        "DigiCam": 4.56,
        "FlashCam": 3.95,
        "NectarCam": 4.05,
        "LSTCam": 2.31,
        "SCTCam": 4.0
    };
    return average_camera_radii_deg[camera_name];
}