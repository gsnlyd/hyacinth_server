defmodule Hyacinth.AssemblyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Assembly` context.
  """

  import Hyacinth.{AccountsFixtures, WarehouseFixtures}

  alias Hyacinth.Assembly

  alias Hyacinth.Accounts.User
  alias Hyacinth.Warehouse.Dataset
  alias Hyacinth.Assembly.{Pipeline, Driver}

  @spec options_fixture(atom, map) :: map
  def options_fixture(driver, params \\ %{}) do
    driver
    |> Driver.options_changeset(params)
    |> Ecto.Changeset.apply_action!(:insert)
    |> Map.from_struct()
  end

  def pipeline_fixture(name \\ nil, user \\ nil, dataset \\ nil) do
    name = name || "Pipeline #{System.unique_integer()}"
    %User{} = user = user || user_fixture()
    %Dataset{} = dataset = dataset || root_dataset_fixture()

    params = %{
      name: name,
      transforms: [
        %{
          order_index: 0,
          driver: :slicer,
          options: options_fixture(:slicer),
          input_id: dataset.id,
        },
        %{
          order_index: 1,
          driver: :sample,
          options: options_fixture(:sample),
        },
      ],
    }

    {:ok, %Pipeline{} = pipeline} = Assembly.create_pipeline(user, params)
    pipeline
  end
end
