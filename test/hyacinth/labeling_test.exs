defmodule Hyacinth.LabelingTest do
  use Hyacinth.DataCase

  alias Hyacinth.Labeling

  import Hyacinth.{AccountsFixtures, WarehouseFixtures, LabelingFixtures}

  alias Hyacinth.Labeling.{LabelJob, LabelSession, LabelElement, LabelEntry, Note}

  @invalid_label_job_attrs %{name: nil, type: nil, label_options_string: nil, dataset_id: nil}

  describe "list_label_jobs/0" do
    test "returns all label_jobs" do
      label_job = label_job_fixture()
      assert Labeling.list_label_jobs() == [label_job]
    end

    test "returns empty list if there are no jobs" do
      assert Labeling.list_label_jobs() == []
    end
  end

  describe "list_label_jobs/1" do
    test "returns all jobs for the given dataset" do
      dataset1 = root_dataset_fixture()
      dataset2 = root_dataset_fixture()

      job1 = label_job_fixture(%{}, dataset1)
      job2 = label_job_fixture(%{}, dataset1)

      jobs = Labeling.list_label_jobs(dataset1)
      assert length(jobs) == 2
      assert Enum.at(jobs, 0).id == job1.id
      assert Enum.at(jobs, 1).id == job2.id

      assert Labeling.list_label_jobs(dataset2) == []
    end

    test "returns empty list if there are no jobs" do
      dataset = root_dataset_fixture()
      assert Labeling.list_label_jobs(dataset) == []
    end
  end

  describe "get_label_job!/1" do
    test "returns the label_job with given id" do
      label_job = label_job_fixture()
      assert Labeling.get_label_job!(label_job.id) == label_job
    end
  end

  describe "get_label_job_with_blueprint/1" do
    test "returns the label_job with given id" do
      label_job = label_job_fixture()

      job_with_bp = Labeling.get_job_with_blueprint(label_job.id)
      assert job_with_bp.id == label_job.id
      assert Ecto.assoc_loaded?(job_with_bp.dataset)
      assert Ecto.assoc_loaded?(job_with_bp.blueprint)
      assert Ecto.assoc_loaded?(job_with_bp.blueprint.elements)
      assert Ecto.assoc_loaded?(hd(job_with_bp.blueprint.elements).objects)
    end
  end

  describe "create_label_job/1" do
    test "with valid data creates a label_job" do
      user = user_fixture()
      dataset = root_dataset_fixture()
      valid_attrs = %{
        name: "some name",
        description: "some description",
        prompt: "some prompt",
        label_options_string: "option 1, option 2, option 3",
        type: :classification,
        options: %{"randomize" => "false", "random_seed" => "9876"},
        dataset_id: dataset.id,
      }

      assert {:ok, %LabelJob{} = label_job} = Labeling.create_label_job(valid_attrs, user)
      assert label_job.name == "some name"
      assert label_job.description == "some description"
      assert label_job.prompt == "some prompt"
      assert label_job.label_options == ["option 1", "option 2", "option 3"]
      assert label_job.type == :classification
      assert label_job.options == %{"randomize" => false, "random_seed" => 9876}
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


  describe "list_sessions/1" do
    test "returns empty list when there are no sessions" do
      job = label_job_fixture()
      assert Labeling.list_sessions(job) == []
    end

    test "returns non-blueprint sessions for job" do
      job = label_job_fixture()
      sess1 = label_session_fixture(job)
      sess2 = label_session_fixture(job)
      _other_job_sess = label_session_fixture()

      job_sessions = Labeling.list_sessions(job)

      assert length(job_sessions) == 2
      assert Enum.at(job_sessions, 0).id == sess1.id
      assert Enum.at(job_sessions, 1).id == sess2.id
    end
  end

  describe "list_sessions_with_progress/1" do
    test "returns non-blueprint sessions with progress for job" do
      job = label_job_fixture()
      user = user_fixture()
      sess1 = label_session_fixture(job, user)
      sess2 = label_session_fixture(job, user)

      sess1 = Labeling.get_label_session_with_elements!(sess1.id)

      Labeling.create_label_entry!(Enum.at(sess1.elements, 0), user, "option 1")
      Labeling.create_label_entry!(Enum.at(sess1.elements, 0), user, "option 2")
      Labeling.create_label_entry!(Enum.at(sess1.elements, 1), user, "option 1")
      Labeling.create_label_entry!(Enum.at(sess1.elements, 2), user, "option 1")

      [{final_sess1, sess1_count}, {final_sess2, sess2_count}] = Labeling.list_sessions_with_progress(job)
      assert final_sess1.id == sess1.id
      assert sess1_count == 3
      assert final_sess2.id == sess2.id
      assert sess2_count == 0

      assert Ecto.assoc_loaded?(final_sess1.user)
      assert Ecto.assoc_loaded?(final_sess2.user)
    end

    test "returns empty list when there are no sessions for job" do
      job = label_job_fixture()
      assert Labeling.list_sessions_with_progress(job) == []
    end

    test "returns sessions with progress for user" do
      job1 = label_job_fixture()
      job2 = label_job_fixture()

      user = user_fixture()
      other_user = user_fixture()

      sess1 = label_session_fixture(job1, user)
      sess2 = label_session_fixture(job2, user)

      label_session_fixture(job1, other_user)

      sess1 = Labeling.get_label_session_with_elements!(sess1.id)
      Labeling.create_label_entry!(Enum.at(sess1.elements, 0), user, "option 1")
      Labeling.create_label_entry!(Enum.at(sess1.elements, 0), user, "option 2")
      Labeling.create_label_entry!(Enum.at(sess1.elements, 1), user, "option 1")
      Labeling.create_label_entry!(Enum.at(sess1.elements, 2), user, "option 1")

      [{s1, s1_count}, {s2, s2_count}] = Labeling.list_sessions_with_progress(user)
      assert s1.id == sess1.id
      assert s1_count == 3
      assert s2.id == sess2.id
      assert s2_count == 0

      assert Ecto.assoc_loaded?(s1.user)
      assert Ecto.assoc_loaded?(s1.job)
      assert Ecto.assoc_loaded?(s2.user)
      assert Ecto.assoc_loaded?(s2.job)
    end

    test "returns empty list when there are no sessions for user" do
      user = user_fixture()
      assert Labeling.list_sessions_with_progress(user) == []
    end
  end

  describe "get_label_session!/1" do
    test "returns session" do
      session = label_session_fixture()
      assert Labeling.get_label_session!(session.id) == session
    end
  end

  describe "get_label_session_with_elements!/1" do
    test "returns session with associations preloaded" do
      session = label_session_fixture()

      session_loaded = Labeling.get_label_session_with_elements!(session.id)

      assert session_loaded.id == session.id
      assert Ecto.assoc_loaded?(session_loaded.job)
      assert Ecto.assoc_loaded?(session_loaded.job.dataset)
      assert Ecto.assoc_loaded?(session_loaded.elements)
      assert Ecto.assoc_loaded?(hd(session_loaded.elements).objects)
      assert Ecto.assoc_loaded?(hd(session_loaded.elements).labels)
    end
  end

  describe "create_label_session/2" do
    test "creates a LabelSession" do
      job = label_job_fixture()
      user = user_fixture()

      session = Labeling.create_label_session(job, user)
      assert %LabelSession{} = session
      assert session.job_id == job.id
      assert session.user_id == user.id

      blueprint = Labeling.get_job_with_blueprint(job.id).blueprint
      elements = Labeling.get_label_session_with_elements!(session.id).elements
      assert length(elements) == length(blueprint.elements)
    end
  end

  describe "get_label_element!/1" do
    test "returns element" do
      session = label_session_fixture()
      element = hd(Labeling.get_label_session_with_elements!(session.id).elements)

      got_element = Labeling.get_label_element!(element.id)
      assert %LabelElement{} = got_element
      assert got_element.id == element.id
    end
  end

  describe "get_label_element_preloaded!/1" do
    test "returns element" do
      session = label_session_fixture()
      original_element = hd(Labeling.get_label_session_with_elements!(session.id).elements)

      element = Labeling.get_label_element_preloaded!(original_element.id)
      assert %LabelElement{} = element
      assert element.id == original_element.id

      assert Ecto.assoc_loaded?(element.objects)
      assert Ecto.assoc_loaded?(element.note)
    end

    test "raises if element does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Labeling.get_label_element_preloaded!(123)
      end
    end
  end

  describe "get_label_element/2" do
    test "returns element at given index from given session" do
      session = label_session_fixture()

      got_element = Labeling.get_label_element!(session, 2)
      assert %LabelElement{} = got_element
      assert got_element.element_index == 2
      assert got_element.session_id == session.id
    end

    test "raises if no element exists at given index" do
      session = label_session_fixture()

      assert_raise Ecto.NoResultsError, fn ->
        Labeling.get_label_element!(session, 100)
      end
    end
  end

  def setup_session(_context) do
    job = label_job_fixture(%{label_options_string: "valid option, another option, third option"})
    user = user_fixture()
    session = label_session_fixture(job, user)
    session = Labeling.get_label_session_with_elements!(session.id)

    %{
      user: user,
      session: session,
    }
  end

  def extract_element(%{session: %LabelSession{} = session}) do
    %{
      element: hd(session.elements),
    }
  end

  describe "create_label_entry!/3" do
    setup [:setup_session, :extract_element]

    test "creates LabelEntry", %{user: user, element: element} do
      label_entry = Labeling.create_label_entry!(element, user, "valid option")

      assert %LabelEntry{} = label_entry
      assert label_entry.element_id == element.id
      assert label_entry.value.option == "valid option"

      element_labels = Labeling.list_element_labels(element)
      assert length(element_labels) == 1
      assert hd(element_labels).id == label_entry.id
    end

    test "raises if label_value is invalid", %{user: user, element: element} do
      assert_raise MatchError, fn ->
        Labeling.create_label_entry!(element, user, "invalid option")
      end

      element_labels = Labeling.list_element_labels(element)
      assert length(element_labels) == 0
    end

    test "raises if session does not belong to user", %{element: element} do
      wrong_user = user_fixture()

      assert_raise MatchError, fn ->
        Labeling.create_label_entry!(element, wrong_user, "valid option")
      end

      element_labels = Labeling.list_element_labels(element)
      assert length(element_labels) == 0
    end
  end

  describe "list_element_labels/1" do
    setup [:setup_session, :extract_element]

    test "returns labels for element in descending order", %{user: user, element: element} do
      Labeling.create_label_entry!(element, user, "valid option")
      Labeling.create_label_entry!(element, user, "another option")
      Labeling.create_label_entry!(element, user, "third option")

      labels = Labeling.list_element_labels(element)
      assert length(labels) == 3
      assert Enum.at(labels, 0).value.option == "third option"
      assert Enum.at(labels, 1).value.option == "another option"
      assert Enum.at(labels, 2).value.option == "valid option"
    end

    test "returns empty list for element with no labels", %{element: element} do
      assert Labeling.list_element_labels(element) == []
    end
  end

  describe "create_note/3" do
    setup [:setup_session, :extract_element]

    test "creates note", %{user: user, element: element} do
      params = %{"text" => "some text"}
      {:ok, _values} = Labeling.create_note(user, element, params)

      assert Labeling.get_label_element_preloaded!(element.id).note.text == "some text"
    end

    test "fails if session does not belong to user", %{element: element} do
      wrong_user = user_fixture()

      params = %{"text" => "some text"}
      {:error, :validate_user, :wrong_label_session_user, _changes} = Labeling.create_note(wrong_user, element, params)

      assert Labeling.get_label_element_preloaded!(element.id).note == nil
    end
  end

  describe "update_note/3" do
    setup [:setup_session, :extract_element]

    setup %{user: user, element: element} do
      {:ok, %{note: %Note{} = note}} = Labeling.create_note(user, element, %{"text" => "some text"})
      %{note: note}
    end

    test "updates note", %{user: user, element: element, note: note} do
      params = %{"text" => "some updated text"}
      {:ok, _values} = Labeling.update_note(user, note, params)

      assert Labeling.get_label_element_preloaded!(element.id).note.text == "some updated text"
    end

    test "fails if session does not belong to user", %{element: element, note: note} do
      wrong_user = user_fixture()

      params = %{"text" => "some updated text"}
      {:error, :validate_user, :wrong_label_session_user, _changes} = Labeling.update_note(wrong_user, note, params)

      assert Labeling.get_label_element_preloaded!(element.id).note.text == "some text"
    end
  end
end
