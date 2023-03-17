import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/hyacinth start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :hyacinth, HyacinthWeb.Endpoint, server: true
end


# Don't configure application if the `generate_config` script is running
unless System.get_env("HYACINTH_GENERATING_CONFIG") do
  # Configure storage paths
  case config_env() do
    :dev ->
      config :hyacinth, :warehouse_path, Path.join(File.cwd!(), "priv/warehouse_objects")
      config :hyacinth, :transform_path, Path.join(File.cwd!(), "priv/transform_tmp")

    :test ->
      config :hyacinth, :warehouse_path, Path.join(File.cwd!(), "priv/test_storage/warehouse")
      config :hyacinth, :transform_path, Path.join(File.cwd!(), "priv/test_storage/transform")

    :prod ->
      config :hyacinth, :warehouse_path, System.get_env("WAREHOUSE_PATH") || raise "Environment variable WAREHOUSE_PATH missing!"
      config :hyacinth, :transform_path, System.get_env("TRANSFORM_PATH") || raise "Environment variable TRANSFORM_PATH missing!"
  end

  # Configure driver paths
  case config_env() do
    env when env in [:dev, :test] ->
      config :hyacinth, :python_binary_path, Path.join(File.cwd!, "priv/drivers/python_slicer/venv/bin/python")
      config :hyacinth, :slicer_path, Path.join(File.cwd!, "priv/drivers/python_slicer/slicer.py")
      config :hyacinth, :dcm2niix_binary_path, "dcm2niix"

    :prod ->
      config :hyacinth, :python_binary_path, System.get_env("PYTHON_BINARY_PATH") || "python"
      # TODO: Use Application.app_dir at runtime in slicer.ex and remove this from the config entirely
      config :hyacinth, :slicer_path, System.get_env("SLICER_PATH") || Path.expand(Path.join(File.cwd!, "../lib/hyacinth-1.2.0/priv/drivers/python_slicer/slicer.py"))
      config :hyacinth, :dcm2niix_binary_path, System.get_env("DCM2NIIX_BINARY_PATH") || "dcm2niix"
  end

  if config_env() == :prod do
    database_path = System.get_env("DATABASE_PATH") || raise "Environment variable DATABASE_PATH is missing!"

    config :hyacinth, Hyacinth.Repo,
      database: database_path,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

    # The secret key base is used to sign/encrypt cookies and other secrets.
    # A default value is used in config/dev.exs and config/test.exs but you
    # want to use a different value for prod and you most likely don't want
    # to check this value into version control, so we use an environment
    # variable instead.
    secret_key_base = System.get_env("SECRET_KEY_BASE") || raise "Environment variable SECRET_KEY_BASE is missing!"

    host = System.get_env("PHX_HOST") || "localhost"
    port = String.to_integer(System.get_env("PORT") || "4000")
    url_port = String.to_integer(System.get_env("URL_PORT") || "4000")
    url_scheme = System.get_env("URL_SCHEME") || "http"

    config :hyacinth, HyacinthWeb.Endpoint,
      url: [host: host, port: url_port, scheme: url_scheme],
      http: [
        # Enable IPv6 and bind on all interfaces.
        # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
        # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
        # for details about using IPv6 vs IPv4 and loopback vs public addresses.
        ip: {0, 0, 0, 0, 0, 0, 0, 0},
        port: port
      ],
      secret_key_base: secret_key_base
  end
end
