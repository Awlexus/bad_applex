defmodule BadApplexWeb.Index do
  use BadApplexWeb, :live_view

  require Logger

  def mount(_params, _session, socket) do
    assigns = :persistent_term.get(:bad_apple)
    assigns = Map.put(assigns, :tick_interval, assigns.duration / assigns.frame_count)

    {:ok, assign(socket, assigns) |> set_frame(0)}
  end

  def handle_event("playing", params, socket) do
    {:ok, timer} = :timer.send_interval(round(socket.assigns.tick_interval), :tick)
    {:noreply, assign(socket, :timer, timer) |> assign_time(params)}
  end

  def handle_event("pause", params, socket) do
    if timer = socket.assigns[:timer] do
      :timer.cancel(timer)
    end

    {:noreply, assign(socket, :timer, nil) |> assign_time(params)}
  end

  def handle_event("seeking", params, socket) do
    {:noreply, assign_time(socket, params)}
  end

  def handle_event("ended", _, socket) do
    if timer = socket.assigns[:timer] do
      :timer.cancel(timer)
    end

    {:noreply, assign(socket, :timer, nil) |> set_frame(0)}
  end

  def handle_info(:tick, socket) do
    current_time = timestamp() - socket.assigns.timestamp + socket.assigns.offset

    current_frame =
      min(
        round(socket.assigns.frame_count * current_time / socket.assigns.duration),
        socket.assigns.frame_count - 1
      )

    {:noreply, set_frame(socket, current_frame)}
  end

  defp assign_time(socket, %{"time" => time}) do
    time = round(time * 1000)

    current_frame =
      round(time / socket.assigns.tick_interval) |> min(socket.assigns.frame_count - 1)

    socket
    |> assign(timestamp: timestamp(), offset: time)
    |> set_frame(current_frame)
  end

  defp timestamp(), do: System.os_time(:millisecond)

  defp set_frame(socket, index) do
    assign(socket,
      current_frame_index: index,
      current_frame_data: Enum.at(socket.assigns.frames, index)
    )
  end
end
