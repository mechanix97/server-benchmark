defmodule JsonRpcServer do
  require Logger
  use GenServer

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, socket} = :gen_tcp.listen(8080, [
      :binary,
      packet: :http_bin,
      active: true,
      reuseaddr: true,
      nodelay: true
    ])
    Logger.info("Server started on port 8080")
    {:ok, _} = Task.Supervisor.start_link(name: JsonRpcServer.TaskSupervisor)
    send(self(), :accept)
    {:ok, %{socket: socket}}
  end

  def handle_info(:accept, state = %{socket: socket}) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        {:ok, _pid} = Task.Supervisor.start_child(
          JsonRpcServer.TaskSupervisor,
          fn -> serve(client) end
        )
        send(self(), :accept)
        {:noreply, state}
      {:error, reason} ->
        Logger.error("Accept failed: #{inspect(reason)}")
        {:stop, reason, state}
    end
  end

  def handle_info({:tcp, client, packet}, state) do
    # Handle TCP messages if needed for active mode
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _client}, state) do
    {:noreply, state}
  end

  defp serve(client) do
    case read_request(client, []) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, _json} ->
            send_response(client, 200, %{"status" => "success"})
          {:error, _} ->
            send_response(client, 400, %{"status" => "error"})
        end
      _ ->
        send_response(client, 400, %{"status" => "error"})
    end
    :gen_tcp.close(client)
  end

  defp read_request(client, acc) do
    receive do
      {:tcp, ^client, :http_eoh} ->
        {:ok, Enum.join(acc, "")}
      {:tcp, ^client, {:http_request, :POST, _, _}} ->
        read_request(client, acc)
      {:tcp, ^client, {:http_header, _, _, _, _}} ->
        read_request(client, acc)
      {:tcp, ^client, data} ->
        read_request(client, [data | acc])
      {:tcp_closed, ^client} ->
        :error
    after
      5_000 -> :error
    end
  end

  defp send_response(client, status_code, body) do
    response = Jason.encode!(body)
    headers = [
      "HTTP/1.1 #{status_code} #{status_text(status_code)}\r\n",
      "Content-Type: application/json\r\n",
      "Content-Length: #{byte_size(response)}\r\n",
      "\r\n",
      response
    ]
    :gen_tcp.send(client, headers)
  end

  defp status_text(200), do: "OK"
  defp status_text(400), do: "Bad Request"
end
