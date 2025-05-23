defmodule JsonServer do
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/" do
    case validate_json_rpc(conn.body_params) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{"status" => "success"}))
      :error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{"status" => "error"}))
    end
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(%{"status" => "error"}))
  end

  def start do
    Plug.Cowboy.http(__MODULE__, [], port: 8080)
  end

  defp validate_json_rpc(params) do
    with %{"jsonrpc" => jsonrpc, "method" => method, "params" => params, "id" => id} <- params,
         true <- is_binary(jsonrpc),
         true <- is_binary(method),
         true <- is_list(params) and Enum.all?(params, &is_binary/1),
         true <- is_integer(id) do
      :ok
    else
      _ -> :error
    end
  end
end
