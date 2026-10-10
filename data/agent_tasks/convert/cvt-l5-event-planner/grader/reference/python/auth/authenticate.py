from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from auth.jwt_handler import verify_access_token

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/user/signin")


async def authenticate(token: str = Depends(oauth2_scheme)):
    """Authenticate a user based on the provided JWT token.

    Args:
        token: JWT token extracted from the Authorization header.

    Returns:
        The user information decoded from the token if authentication is successful.

    Raises:
        HTTPException: If the token is missing, invalid, or expired, an HTTPException with status code 403 is raised, indicating that the user must sign in to access the resource.
    """

    if not token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Sign-in for access"
        )

    decoded_token = verify_access_token(token)
    return decoded_token["user"]
