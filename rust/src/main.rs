use serde_json::{from_slice, Value};
use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};

fn handle_client(mut stream: TcpStream) {
    let mut buffer = [0; 1024];
    let mut request = String::new();

    loop {
        let bytes_read = stream.read(&mut buffer).unwrap_or(0);
        if bytes_read == 0 {
            break;
        }
        request.push_str(&String::from_utf8_lossy(&buffer[..bytes_read]));

        if request.contains("\r\n\r\n") {
            break;
        }
    }

    let body = request.split("\r\n\r\n").nth(1).unwrap_or("");
    let response = if let Ok(_json) = from_slice::<Value>(body.as_bytes()) {
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"success\"}"
    } else {
        "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\n\r\n{\"status\":\"error\"}"
    };

    stream.write_all(response.as_bytes()).unwrap();
    stream.flush().unwrap();
}

fn main() {
    let listener = TcpListener::bind("127.0.0.1:8080").unwrap();
    for stream in listener.incoming() {
        if let Ok(stream) = stream {
            handle_client(stream);
        }
    }
}
