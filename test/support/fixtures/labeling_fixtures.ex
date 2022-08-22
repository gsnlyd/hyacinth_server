defmodule Hyacinth.LabelingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Labeling` context.
  """

  alias Hyacinth.AccountsFixtures
  alias Hyacinth.WarehouseFixtures

  alias Hyacinth.Labeling
  alias Hyacinth.Accounts.User
  alias Hyacinth.Labeling.{LabelJob, LabelSession}

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

  @doc """
  Generates a LabelSession.
  """
  def label_session_fixture(job \\ nil, user \\ nil) do
    job = if job, do: %LabelJob{} = job, else: label_job_fixture()
    user = if user, do: %User{} = user, else: AccountsFixtures.user_fixture()

    %LabelSession{} = Labeling.create_label_session(job, user)
  end
end
