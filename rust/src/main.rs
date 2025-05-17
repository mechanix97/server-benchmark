use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;
use serde_json::Value;

async fn handle_client(mut stream: tokio::net::TcpStream) -> tokio::io::Result<()> {
    let mut buffer = [0; 1024];
    let mut request = Vec::new();

    // Leer hasta el final del encabezado HTTP
    loop {
        let n = stream.read(&mut buffer).await?;
        if n == 0 {
            return Ok(()); // Conexión cerrada por el cliente
        }
        request.extend_from_slice(&buffer[..n]);
        let request_str = String::from_utf8_lossy(&request);
        if request_str.contains("\r\n\r\n") {
            break;
        }
    }

    // Extraer el cuerpo después de \r\n\r\n
    let request_str = String::from_utf8_lossy(&request);
    let body = request_str
        .split("\r\n\r\n")
        .nth(1)
        .unwrap_or("");

    // Parsear JSON y preparar respuesta
    let response = if let Ok(_json) = serde_json::from_str::<Value>(body) {
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\"status\":\"success\"}"
    } else {
        "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\"status\":\"error\"}"
    };

    // Enviar respuesta y cerrar conexión
    stream.write_all(response.as_bytes()).await?;
    stream.flush().await?;
    Ok(())
}

#[tokio::main]
async fn main() -> tokio::io::Result<()> {
    let listener = TcpListener::bind("127.0.0.1:8080").await?;
    println!("Server running on port 8080");

    loop {
        let (stream, _) = listener.accept().await?;
        // Manejar cada conexión en una tarea asíncrona
        tokio::spawn(async move {
            if let Err(e) = handle_client(stream).await {
                eprintln!("Error handling connection: {}", e);
            }
        });
    }
}
