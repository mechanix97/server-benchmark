use hyper::{Body, Request, Response, Server, Method, StatusCode};
use hyper::service::{make_service_fn, service_fn};
use serde_json::Value;
use std::convert::Infallible;
use std::net::SocketAddr;

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    // Only accept POST requests
    if req.method() != Method::POST {
        return Ok(Response::builder()
            .status(StatusCode::BAD_REQUEST)
            .header("Content-Type", "application/json")
            .header("Content-Length", "21")
            .body(Body::from(r#"{"status":"error"}"#))
            .unwrap());
    }

    // Read and parse body
    let body_bytes = hyper::body::to_bytes(req.into_body()).await.unwrap();
    let response = match serde_json::from_slice::<Value>(&body_bytes) {
        Ok(_) => Response::builder()
            .status(StatusCode::OK)
            .header("Content-Type", "application/json")
            .header("Content-Length", "22")
            .body(Body::from(r#"{"status":"success"}"#))
            .unwrap(),
        Err(_) => Response::builder()
            .status(StatusCode::BAD_REQUEST)
            .header("Content-Type", "application/json")
            .header("Content-Length", "21")
            .body(Body::from(r#"{"status":"error"}"#))
            .unwrap(),
    };

    Ok(response)
}

#[tokio::main]
async fn main() {
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    let make_svc = make_service_fn(|_conn| async {
        Ok::<_, Infallible>(service_fn(handle_request))
    });
    let server = Server::bind(&addr)
        .http1_keepalive(true) // Explicitly enable keep-alive
        .serve(make_svc);

    println!("Server running on http://{}", addr);
    if let Err(e) = server.await {
        eprintln!("Server error: {}", e);
    }
}
