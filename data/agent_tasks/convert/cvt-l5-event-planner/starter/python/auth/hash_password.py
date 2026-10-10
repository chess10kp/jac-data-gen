from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class HashPassword:
    def create_hash(self, password: str):
        """Hash a plain-text password using bcrypt.

        Args:
            password: Plain-text password to hash.

        Returns:
            A bcrypt hash of the provided password.
        """

        return pwd_context.hash(password)

    def verify_hash(self, plain_password: str, hashed_password: str):
        """Verify a plain-text password against a stored hash.

        Args:
            plain_password: Plain-text password to verify.
            hashed_password: Stored bcrypt hash to compare against.

        Returns:
            True if the password matches the hash; otherwise False.
        """

        return pwd_context.verify(plain_password, hashed_password)
