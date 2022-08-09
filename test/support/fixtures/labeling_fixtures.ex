defmodule Hyacinth.LabelingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Labeling` context.
  """

  alias Hyacinth.AccountsFixtures
  alias Hyacinth.WarehouseFixtures

  @doc """
  Generate a label_job.
  """
  def label_job_fixture(attrs \\ %{}) do
    user = AccountsFixtures.user_fixture()
    dataset = WarehouseFixtures.root_dataset_fixture()

    {:ok, label_job} =
      attrs
      |> Enum.into(%{
        label_type: :classification,
        name: "some name",
        dataset_id: dataset.id,
      })
      |> Hyacinth.Labeling.create_label_job(user)

    label_job
  end
end
