from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    CORS_ORIGINS: List[str] = ["*"]

settings = Settings()
print("CORS_ORIGINS:", settings.CORS_ORIGINS)
