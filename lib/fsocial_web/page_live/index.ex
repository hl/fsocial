defmodule FsocialWeb.PageLive.Index do
  use FsocialWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""

    """
  end

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket) && params["username"] do
      username = slugify(params["username"])
      Fsocial.User.start_child(username)
      FsocialWeb.Endpoint.subscribe(username)
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("follow", _params, socket) do
    Fsocial.User.follow(socket.assigns.username)
    {:noreply, socket}
  end

  def apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "FakeSocialClub")
  end

  def apply_action(socket, :show, %{"username" => username}) do
    socket
    |> assign(:username, username)
    |> assign(:page_title, "FakeSocialClub - Follow #{username}")
  end

  def slugify(username) do
    username && Slug.slugify(username, truncate: 255, lowercase: false)
  end
end
