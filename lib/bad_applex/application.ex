defmodule BadApplex.Application do
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    load_video_data()

    children = [
      {Phoenix.PubSub, name: BadApplex.PubSub},
      BadApplexWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: BadApplex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    BadApplexWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp load_video_data() do
    Logger.debug("Loading data")

    data =
      :code.priv_dir(:bad_applex)
      |> Path.join("image_data")
      |> File.read!()
      |> :erlang.binary_to_term()

    :persistent_term.put(:bad_apple, data)

    Logger.debug("Data loaded")
  end
end
