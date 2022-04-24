defmodule BadApplexWeb.Router do
  use BadApplexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BadApplexWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", BadApplexWeb do
    pipe_through :browser

    live "/", Index, :index, as: :index
  end
end
