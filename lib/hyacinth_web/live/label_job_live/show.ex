defmodule HyacinthWeb.LabelJobLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelSession, LabelElement}

  defmodule SessionFilterForm do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :type, Ecto.Enum, values: [:all], default: :all
      field :sort_by, Ecto.Enum, values: [:user, :date_created], default: :date_created
      field :order, Ecto.Enum, values: [:asc, :desc], default: :desc
    end

    @doc false
    def changeset(filter_options, attrs) do
      filter_options
      |> cast(attrs, [:search, :type, :sort_by, :order])
      |> validate_required([:search, :type, :sort_by, :order])
    end
  end

  def mount(params, _session, socket) do
    job = Labeling.get_job_with_blueprint(params["label_job_id"])
    socket = assign(socket, %{
      job: job,
      sessions: Labeling.list_sessions_with_progress(job),

      session_filter_changeset: SessionFilterForm.changeset(%SessionFilterForm{}, %{}),

      tab: :sessions,
    })
    {:ok, socket}
  end

  def filter_sessions(sessions, %Ecto.Changeset{} = changeset) when is_list(sessions) do
    %SessionFilterForm{} = form = Ecto.Changeset.apply_changes(changeset)

    filter_func = fn {%LabelSession{} = session, _} ->
      contains_search?(session.user.email, form.search)
    end

    {sort_func, sorter} =
      case form.sort_by do
        :user -> {&(elem(&1, 0).user.email), form.order}
        :date_created -> {&(elem(&1, 0).inserted_at), {form.order, DateTime}}
      end

    sessions
    |> Enum.filter(filter_func)
    |> Enum.sort_by(sort_func, sorter)
  end

  def handle_event("session_filter_updated", %{"session_filter_form" => params}, socket) do
    changeset = SessionFilterForm.changeset(%SessionFilterForm{}, params)
    {:noreply, assign(socket, :session_filter_changeset, changeset)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    tab = case tab do
      "sessions" -> :sessions
      "elements" -> :elements
    end
    {:noreply, assign(socket, :tab, tab)}
  end
end
