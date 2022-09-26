defmodule Hyacinth.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :hyacinth

  def new_dataset(a1, a2, a3) do
    load_app()

    Ecto.Migrator.with_repo(Hyacinth.Repo, fn _repo ->
      Hyacinth.Warehouse.NewDataset.new_dataset({a1, a2, a3})
    end)
  end

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
