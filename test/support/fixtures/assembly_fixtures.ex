defmodule Hyacinth.AssemblyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Assembly` context.
  """

  import Hyacinth.{AccountsFixtures, WarehouseFixtures}

  alias Hyacinth.Assembly

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{Pipeline, Transform, Driver}

  def pipeline_fixture(name \\ nil, user \\ nil, dataset \\ nil) do
    name = name || "Pipeline #{System.unique_integer()}"
    %User{} = user = user || user_fixture()
    %Dataset{} = dataset = dataset || root_dataset_fixture()

    transform_changesets = [
      {
        Transform.changeset(%Transform{}, %{order_index: 0, driver: :slicer}),
        Driver.options_changeset(:slicer, %{})
      },
      {
        Transform.changeset(%Transform{}, %{order_index: 0, driver: :sample}),
        Driver.options_changeset(:sample, %{})
      },
    ]

    {:ok, %{pipeline: %Pipeline{} = pipeline}} = Assembly.create_pipeline(user, name, dataset.id, transform_changesets)
    pipeline
  end
end
