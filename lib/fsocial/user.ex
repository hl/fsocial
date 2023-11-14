defmodule Fsocial.User do
  use GenServer

  require Logger

  defstruct [:username, :followers, :timer]

  @flush_interval_ms :timer.seconds(10)
  @flush_followers_every 1000

  def start_child(username) do
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {Fsocial.DynamicSupervisors, self()}},
      child_spec(username)
    )
  end

  def child_spec(username) do
    %{
      id: "#{__MODULE__}_#{username}",
      start: {__MODULE__, :start_link, [username]},
      shutdown: 10_000,
      restart: :transient
    }
  end

  def start_link(username) do
    case GenServer.start_link(__MODULE__, username, name: via_tuple(username)) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("already started at #{inspect(pid)}, returning :ignore")
        :ignore
    end
  end

  def follow(username) do
    GenServer.call(via_tuple(username), :follow)
  end

  def followers(username) do
    Fsocial.Storage.get(username)
  end

  def init(username) do
    Process.flag(:trap_exit, true)
    followers = Fsocial.Repo.get(username, 0)
    Fsocial.Storage.put(username, followers)
    timer = Process.send_after(self(), :flush, @flush_interval_ms)
    {:ok, %{username: username, followers: followers, timer: timer}}
  end

  def handle_call(:follow, from, state) do
    GenServer.reply(from, :ok)

    state =
      Map.update!(state, :followers, fn followers ->
        followers + 1
      end)

    state =
      if rem(state.followers, @flush_followers_every) == 0 do
        flush(state)
        %{state | timer: Process.send_after(self(), :flush, @flush_interval_ms)}
      else
        state
      end

    Fsocial.Storage.put(state.username, state.followers)

    {:noreply, state}
  end

  def handle_info(:flush, state) do
    flush(state)
    state = %{state | timer: Process.send_after(self(), :flush, @flush_interval_ms)}
    {:noreply, state}
  end

  def terminate(_reason, state) do
    flush(state)
  end

  def flush(state) do
    Fsocial.Repo.put(state.username, state.followers)
  end

  def via_tuple(username) do
    {:via, Registry, {Fsocial.UserRegistry, username}}
  end
end
