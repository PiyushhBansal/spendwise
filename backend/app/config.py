from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "SpendWise API"
    database_url: str = "postgresql+psycopg2://spendwise:spendwise@localhost:5432/spendwise"
    cors_origins: str = "http://localhost:3000,http://localhost:5173"


settings = Settings()
