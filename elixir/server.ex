defmodule JsonRpcServer do
  require Logger

  def start do
    {:ok, socket} = :gen_tcp.listen(8080, [:binary, packet: :http_bin, active: false, reuseaddr: true])
    Logger.info("Server started on port 8080")
    accept_loop(socket)
  end

  defp accept_loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    accept_loop(socket)
  end

  defp serve(client) do
    case read_request(client, []) do
      {:ok, body} ->
        case :json.decode(body) do
          {:ok, _json} ->
            :gen_tcp.send(client, "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\"}\r\n")
          {:error, _} ->
            :gen_tcp.send(client, "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\"}\r\n")
        end
      _ ->
        :gen_tcp.send(client, "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\"}\r\n")
    end
    :gen_tcp.close(client)
  end

  defp read_request(client, acc) do
    case :gen_tcp.recv(client, 0) do
      {:ok, :http_eoh} -> {:ok, Enum.join(acc, "")}
      {:ok, {:http_request, :POST, _, _}} -> read_request(client, acc)
      {:ok, {:http_header, _, _, _, _}} -> read_request(client, acc)
      {:ok, data} -> read_request(client, [data | acc])
      {:error, _} -> :error
    end
  end
end

JsonRpcServer.start()
