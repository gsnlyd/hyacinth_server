defmodule Hyacinth.GenerateConfig do
  require Logger

  def generate_config() do
    config_path = Path.join(File.cwd!, "config.env")

    if File.exists?(config_path), do: raise "File already exists at path #{config_path}"

    # Based on phx.gen.secret
    secret_key_base =
      :crypto.strong_rand_bytes(64)
      |> Base.encode64(padding: false)
      |> binary_part(0, 64)

    contents =
      """
      export DATABASE_PATH="~/hyacinth/hyacinth.db"
      export WAREHOUSE_PATH="~/hyacinth/warehouse"
      export TRANSFORM_PATH="~/hyacinth/transform"

      export SECRET_KEY_BASE="#{secret_key_base}"
      """

    File.write!(config_path, contents)
    Logger.info "Wrote config to #{config_path}"
  end
end
