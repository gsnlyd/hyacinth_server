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
        name: "some name",
        label_type: :classification,
        label_options_string: "option 1, option 2, option 3",
        dataset_id: dataset.id,
      })
      |> Hyacinth.Labeling.create_label_job(user)

    label_job
  end
end
