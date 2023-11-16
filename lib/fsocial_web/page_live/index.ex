defmodule FsocialWeb.PageLive.Index do
  use FsocialWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      FakeSocialClub
      <:subtitle>Get all the followers you need!</:subtitle>
    </.header>

    <.modal :if={@live_action == :show} id="follow-modal" show on_cancel={JS.patch(~p"/")}>
      <.header>@<%= @username %></.header>
      <p>Followers <%= @followers %></p>

      <.button
        phx-click="follow"
        class="bg-pink-500 text-white active:bg-pink-600 font-bold uppercase text-base px-20 py-5 rounded-md shadow-md hover:shadow-lg outline-none focus:outline-none mr-1 mb-1 ease-linear transition-all duration-150"
      >
        FOLLOW
      </.button>
    </.modal>
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
    followers = Fsocial.User.followers(socket.assigns.username)
    FsocialWeb.Endpoint.broadcast(socket.assigns.username, "follow", %{followers: followers})
    {:noreply, socket}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, assign(socket, :followers, format_numbers(msg.payload.followers))}
  end

  def apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "FakeSocialClub")
    |> assign(:username, nil)
    |> assign(:followers, nil)
  end

  def apply_action(socket, :show, %{"username" => username}) do
    username = slugify(username)
    followers = Fsocial.User.followers(username)

    socket
    |> assign(:username, username)
    |> assign(:followers, format_numbers(followers))
    |> assign(:page_title, "FakeSocialClub - Follow #{username}")
  end

  def slugify(username) do
    username && Slug.slugify(username, truncate: 255, lowercase: false)
  end

  def format_numbers(followers) do
    followers
    |> to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse(&1))
    |> Enum.reverse()
    |> Enum.join(",")
  end
end
