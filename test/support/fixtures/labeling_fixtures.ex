defmodule Hyacinth.LabelingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hyacinth.Labeling` context.
  """

  @doc """
  Generate a label_job.
  """
  def label_job_fixture(attrs \\ %{}) do
    {:ok, label_job} =
      attrs
      |> Enum.into(%{
        label_type: :classification,
        name: "some name"
      })
      |> Hyacinth.Labeling.create_label_job()

    label_job
  end
end
