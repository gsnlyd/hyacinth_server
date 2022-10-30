defmodule HyacinthWeb.LabelJobLive.Show do
  use HyacinthWeb, :live_view

  alias Hyacinth.Labeling
  alias Hyacinth.Warehouse.Object
  alias Hyacinth.Labeling.{LabelSession, LabelElement}

  defmodule SessionFilterOptions do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key false
    embedded_schema do
      field :search, :string, default: ""
      field :type, Ecto.Enum, values: [:all], default: :all
      field :sort_by, Ecto.Enum, values: [:user, :date_created], default: :date_created
      field :order, Ecto.Enum, values: [:ascending, :descending], default: :descending
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

      session_filter_changeset: SessionFilterOptions.changeset(%SessionFilterOptions{}, %{}),

      tab: :sessions,
    })
    {:ok, socket}
  end

  @spec filter_sessions([%LabelSession{}], %Ecto.Changeset{}) :: [%LabelSession{}]
  def filter_sessions(sessions, %Ecto.Changeset{} = filter_changeset) when is_list(sessions) do
    %SessionFilterOptions{} = options = Ecto.Changeset.apply_changes(filter_changeset)

    sessions_filtered =
      Enum.filter(sessions, fn {%LabelSession{} = sess, _labeled} ->
        (options.search == "" or String.contains?(String.downcase(sess.user.email), String.downcase(options.search)))
      end)

    sessions_sorted =
      case options.sort_by do
        :user -> Enum.sort_by(sessions_filtered, &(elem(&1, 0).user.email))
        :date_created -> Enum.sort_by(sessions_filtered, &(elem(&1, 0).inserted_at), DateTime)
      end

    case options.order do
      :ascending -> sessions_sorted
      :descending -> Enum.reverse(sessions_sorted)
    end
  end

  def handle_event("session_filter_updated", %{"session_filter_options" => params}, socket) do
    changeset = SessionFilterOptions.changeset(%SessionFilterOptions{}, params)
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
