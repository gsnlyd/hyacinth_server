defmodule Hyacinth.Repo do
  use Ecto.Repo,
    otp_app: :hyacinth,
    adapter: Ecto.Adapters.SQLite3
end
