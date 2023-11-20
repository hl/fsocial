defmodule Fsocial.State do
  defstruct [:username, :followers, :timer_ref, :avatar]

  @type username :: String.t()
  @type followers :: non_neg_integer()
  @opaque t :: %__MODULE__{
            username: username() | nil,
            followers: followers() | nil,
            timer_ref: reference() | nil,
            avatar: String.t() | nil
          }

  @spec new(map() | Keyword.t()) :: t()
  def new(attrs \\ []) do
    struct!(__MODULE__, attrs)
  end

  @spec username(t()) :: username()
  def username(%__MODULE__{username: username}), do: username

  @spec followers(t()) :: followers()
  def followers(%__MODULE__{followers: followers}), do: followers

  @spec followers(t(), non_neg_integer()) :: t()
  def followers(state, followers) do
    Map.update!(state, :followers, fn current_followers ->
      current_followers + followers
    end)
  end

  @spec timer_ref(t()) :: reference()
  def timer_ref(%__MODULE__{timer_ref: timer_ref}), do: timer_ref

  @spec timer_ref(t(), reference()) :: t()
  def timer_ref(%__MODULE__{} = state, timer_ref), do: %{state | timer_ref: timer_ref}
end
