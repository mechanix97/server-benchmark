package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type JsonRpcRequest struct {
	Jsonrpc string   `json:"jsonrpc"`
	Method  string   `json:"method"`
	Params  []string `json:"params"`
	Id      int      `json:"id"`
}

func handler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, `{"status":"error"}`, http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, `{"status":"error"}`, http.StatusBadRequest)
		return
	}

	var req JsonRpcRequest
	if err := json.Unmarshal(body, &req); err != nil {
		http.Error(w, `{"status":"error"}`, http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	fmt.Fprint(w, `{"status":"success"}`)
}

func main() {
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}
