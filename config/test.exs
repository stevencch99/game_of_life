import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :game_of_life, GameOfLifeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "A6M22j0UyRPxUL/ytl2kx3am718S91pNLlqYCR6DaORZcHyd0/1aO3sp7hLT7MwT",
  server: false

# In test we don't send emails
config :game_of_life, GameOfLife.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
