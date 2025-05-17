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
    Logger.info("JSON-RPC server started on port 8080")
    {:ok, _} = Task.Supervisor.start_link(name: JsonRpcServer.TaskSupervisor)
    send(self(), :accept)
    {:ok, %{socket: socket}}
  end

  def handle_info(:accept, state = %{socket: socket}) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        Logger.debug("Accepted client: #{inspect(client)}")
        send(self(), :accept)
        {:noreply, state}
      {:error, reason} ->
        Logger.error("Accept failed: #{inspect(reason)}")
        {:stop, reason, state}
    end
  end

  def handle_info({:http, client, {:http_request, :POST, _, _}}, state) do
    {:ok, _pid} = Task.Supervisor.start_child(
      JsonRpcServer.TaskSupervisor,
      fn -> serve(client) end
    )
    {:noreply, state}
  end

  def handle_info({:http, _client, {:http_header, _, _, _, _}}, state) do
    {:noreply, state}
  end

  def handle_info({:http, _client, :http_eoh}, state) do
    {:noreply, state}
  end

  def handle_info({:http, client, {:http_error, _}}, state) do
    Logger.warn("HTTP error on client: #{inspect(client)}")
    :gen_tcp.close(client)
    {:noreply, state}
  end

  def handle_info({:tcp_closed, client}, state) do
    Logger.debug("Client closed: #{inspect(client)}")
    :gen_tcp.close(client)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warn("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp serve(client) do
    case read_request(client, []) do
      {:ok, body} ->
        handle_jsonrpc_request(client, body)
      _ ->
        send_jsonrpc_error(client, nil, -32700, "Parse error")
    end
    :gen_tcp.close(client)
  end

  defp read_request(client, acc) do
    receive do
      {:http, ^client, :http_eoh} ->
        {:ok, Enum.join(acc, "")}
      {:http, ^client, {:http_request, :POST, _, _}} ->
        read_request(client, acc)
      {:http, ^client, {:http_header, _, _, _, _}} ->
        read_request(client, acc)
      {:http, ^client, data} when is_binary(data) ->
        read_request(client, [data | acc])
      {:http, ^client, {:http_error, _}} ->
        :error
      {:tcp_closed, ^client} ->
        :error
    after
      5_000 -> :error
    end
  end

  defp handle_jsonrpc_request(client, body) do
    case Jason.decode(body) do
      {:ok, %{"jsonrpc" => "2.0", "method" => method, "id" => id} = request} ->
        params = Map.get(request, "params", [])
        process_method(client, method, params, id)
      {:ok, _} ->
        send_jsonrpc_error(client, nil, -32600, "Invalid Request")
      {:error, _} ->
        send_jsonrpc_error(client, nil, -32700, "Parse error")
    end
  end

  defp process_method(client, "eth_chainId", _params, id) do
    send_jsonrpc_response(client, id, "0x1")
  end

  defp process_method(client, _method, _params, id) do
    send_jsonrpc_error(client, id, -32601, "Method not found")
  end

  defp send_jsonrpc_response(client, id, result) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => result
    }
    send_response(client, 200, response)
  end

  defp send_jsonrpc_error(client, id, code, message) do
    response = %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{
        "code" => code,
        "message" => message
      }
    }
    send_response(client, 200, response)
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
