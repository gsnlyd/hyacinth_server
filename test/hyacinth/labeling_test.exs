defmodule Hyacinth.LabelingTest do
  use Hyacinth.DataCase

  alias Hyacinth.Labeling

  import Hyacinth.AccountsFixtures
  import Hyacinth.WarehouseFixtures

  describe "label_jobs" do
    alias Hyacinth.Labeling.LabelJob

    import Hyacinth.LabelingFixtures

    @invalid_attrs %{name: nil, label_type: nil, label_options_string: nil, dataset_id: nil}

    test "list_label_jobs/0 returns all label_jobs" do
      label_job = label_job_fixture()
      assert Labeling.list_label_jobs() == [label_job]
    end

    test "get_label_job!/1 returns the label_job with given id" do
      label_job = label_job_fixture()
      assert Labeling.get_label_job!(label_job.id) == label_job
    end

    test "create_label_job/1 with valid data creates a label_job" do
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

    test "create_label_job/1 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Labeling.create_label_job(@invalid_attrs, user)
    end

    test "update_label_job/2 with invalid data returns error changeset" do
      label_job = label_job_fixture()
      assert {:error, %Ecto.Changeset{}} = Labeling.update_label_job(label_job, @invalid_attrs)
      assert label_job == Labeling.get_label_job!(label_job.id)
    end

    test "delete_label_job/1 deletes the label_job" do
      label_job = label_job_fixture()
      assert {:ok, %LabelJob{}} = Labeling.delete_label_job(label_job)
      assert_raise Ecto.NoResultsError, fn -> Labeling.get_label_job!(label_job.id) end
    end

    test "change_label_job/1 returns a label_job changeset" do
      label_job = label_job_fixture()
      assert %Ecto.Changeset{} = Labeling.change_label_job(label_job)
    end
  end
end
