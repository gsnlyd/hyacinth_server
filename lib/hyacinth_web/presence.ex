defmodule HyacinthWeb.Presence do
  use Phoenix.Presence,
    otp_app: :hyacinth,
    pubsub_server: Hyacinth.PubSub
end
