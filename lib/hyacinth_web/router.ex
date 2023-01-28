defmodule HyacinthWeb.Router do
  use HyacinthWeb, :router

  import HyacinthWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HyacinthWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HyacinthWeb do
    pipe_through :browser

    get "/jobs/:label_job_id/sessions/new", LabelSessionController, :new

    get "/object-image/:object_id", ImageController, :show

    get "/session-labels/:session_id", ExportLabelsController, :show
  end

  live_session :authenticated, on_mount: {HyacinthWeb.UserLiveAuth, :user} do
    scope "/", HyacinthWeb do
      pipe_through [:browser, :require_authenticated_user]

      live "/", HomeLive.Index

      live "/users", UserLive.Index
      live "/users/:user_id", UserLive.Show

      live "/datasets", DatasetLive.Index
      live "/datasets/:dataset_id", DatasetLive.Show

      live "/pipelines", PipelineLive.Index
      live "/pipelines/new", PipelineLive.New
      live "/pipelines/:pipeline_id", PipelineLive.Show

      live "/runs/:pipeline_run_id", PipelineRunLive.Show

      live "/jobs", LabelJobLive.Index
      live "/jobs/new", LabelJobLive.New
      live "/jobs/:label_job_id", LabelJobLive.Show

      live "/sessions/:label_session_id", LabelSessionLive.Show
      live "/sessions/:label_session_id/label/:element_index", LabelSessionLive.Label

      live "/viewer/:object_id", ViewerLive.Show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", HyacinthWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HyacinthWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", HyacinthWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/account/register", UserRegistrationController, :new
    post "/account/register", UserRegistrationController, :create
    get "/account/log_in", UserSessionController, :new
    post "/account/log_in", UserSessionController, :create
    get "/account/reset_password", UserResetPasswordController, :new
    post "/account/reset_password", UserResetPasswordController, :create
    get "/account/reset_password/:token", UserResetPasswordController, :edit
    put "/account/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", HyacinthWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/account/settings", UserSettingsController, :edit
    put "/account/settings", UserSettingsController, :update
    get "/account/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", HyacinthWeb do
    pipe_through [:browser]

    delete "/account/log_out", UserSessionController, :delete
    get "/account/confirm", UserConfirmationController, :new
    post "/account/confirm", UserConfirmationController, :create
    get "/account/confirm/:token", UserConfirmationController, :edit
    post "/account/confirm/:token", UserConfirmationController, :update
  end
end
