defmodule Fsocial.User do
  use GenServer

  require Logger

  @persist_interval_ms :timer.seconds(10)
  @persist_followers_every 1000

  @spec start_child(Fsocial.State.username()) :: DynamicSupervisor.on_start_child()
  def start_child(username) do
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {Fsocial.DynamicSupervisors, self()}},
      Fsocial.User.child_spec(username)
    )
  end

  @spec child_spec(Fsocial.State.username()) :: Supervisor.child_spec()
  def child_spec(username) do
    %{
      id: "#{__MODULE__}_#{username}",
      start: {__MODULE__, :start_link, [username]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  @spec start_link(Fsocial.State.username()) :: GenServer.on_start()
  def start_link(username) do
    case GenServer.start_link(__MODULE__, username, name: via_tuple(username)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  @spec follow(Fsocial.State.username()) :: :ok
  def follow(username) do
    GenServer.call(via_tuple(username), :follow)
  end

  @spec followers(Fsocial.State.username()) :: Fsocial.State.followers()
  def followers(username) do
    Fsocial.Storage.get(username)
  end

  @impl GenServer
  def init(username) do
    Process.flag(:trap_exit, true)
    followers = Fsocial.Repo.get(username, 0)
    Fsocial.Storage.put(username, followers)
    timer_ref = Process.send_after(self(), :persist, @persist_interval_ms)

    state =
      Fsocial.State.new(
        username: username,
        followers: followers,
        timer_ref: timer_ref
      )

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:follow, from, state) do
    GenServer.reply(from, :ok)

    state = Fsocial.State.followers(state, 1)
    username = Fsocial.State.username(state)
    followers = Fsocial.State.followers(state)

    Fsocial.Storage.put(username, followers)

    state =
      if rem(followers, @persist_followers_every) == 0 do
        timer_ref = Fsocial.State.timer_ref(state)
        Process.cancel_timer(timer_ref)
        Fsocial.Repo.get_and_update(username, followers)

        Fsocial.State.timer_ref(
          state,
          Process.send_after(self(), :persist, @persist_interval_ms)
        )
      else
        state
      end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:persist, state) do
    username = Fsocial.State.username(state)
    followers = Fsocial.State.followers(state)
    Fsocial.Repo.get_and_update(username, followers)
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state) do
    username = Fsocial.State.username(state)
    followers = Fsocial.State.followers(state)
    Fsocial.Repo.put(username, followers)
  end

  @spec via_tuple(Fsocial.State.username()) ::
          {:via, Registry, {Fsocial.UserRegistry, Fsocial.State.username()}}
  def via_tuple(username) do
    {:via, Registry, {Fsocial.UserRegistry, username}}
  end
end
