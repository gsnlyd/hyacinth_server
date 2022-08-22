defmodule Hyacinth.LabelingTest do
  use Hyacinth.DataCase

  alias Hyacinth.Labeling

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, LabelingFixtures}

  alias Hyacinth.Labeling.{LabelJob}

  @invalid_label_job_attrs %{name: nil, label_type: nil, label_options_string: nil, dataset_id: nil}

  describe "list_label_jobs/0" do
    test "returns all label_jobs" do
      label_job = label_job_fixture()
      assert Labeling.list_label_jobs() == [label_job]
    end
  end

  describe "get_label_job!/1" do
    test "returns the label_job with given id" do
      label_job = label_job_fixture()
      assert Labeling.get_label_job!(label_job.id) == label_job
    end
  end

  describe "create_label_job/1" do
    test "with valid data creates a label_job" do
      user = user_fixture()
      dataset = root_dataset_fixture()
      valid_attrs = %{
        name: "some name",
        label_type: :classification,
        label_options_string: "option 1, option 2, option 3",
        dataset_id: dataset.id,
      }

      assert {:ok, %LabelJob{} = label_job} = Labeling.create_label_job(valid_attrs, user)
      assert label_job.label_type == :classification
      assert label_job.name == "some name"
    end

    test "with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Labeling.create_label_job(@invalid_label_job_attrs, user)
    end
  end

  describe "update_label_job/2" do
    test "with invalid data returns error changeset" do
      label_job = label_job_fixture()
      assert {:error, %Ecto.Changeset{}} = Labeling.update_label_job(label_job, @invalid_label_job_attrs)
      assert label_job == Labeling.get_label_job!(label_job.id)
    end
  end

  describe "change_label_job/1" do
    test "returns a label_job changeset" do
      label_job = label_job_fixture()
      assert %Ecto.Changeset{} = Labeling.change_label_job(label_job)
    end
  end
end
