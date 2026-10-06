"""App settings — loaded from environment variables."""

import from os { environ }
import from dotenv { load_dotenv }

glob _loaded = load_dotenv();
glob OPENROUTER_API_KEY = environ.get("OPENROUTER_API_KEY", "");
glob ANTHROPIC_API_KEY = environ.get("ANTHROPIC_API_KEY", "");  # kept for compatibility
glob APP_ENV = environ.get("APP_ENV", "development");
glob DEBUG = environ.get("DEBUG", "true").lower() == "true";
glob DATABASE_URL = environ.get("DATABASE_URL", "postgresql://agewise:agewise@localhost:5432/agewise");
