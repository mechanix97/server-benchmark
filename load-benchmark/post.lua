wrk.method = "POST"
wrk.headers["Content-Type"] = "application/json"
local file = io.open("correct_request.json", "r")
wrk.body = file:read("*all")
file:close()
