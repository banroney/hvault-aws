storage "dynamodb"

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

listener "tcp" {
  address = "127.0.0.1:8200"
  tls_disable = 1
}

ui = true