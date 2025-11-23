listener "tcp" {
  address         = "0.0.0.0:8200"   # UI+API внутри контейнера
  cluster_address = "0.0.0.0:8201"   # кластерный порт (внутренний)
  tls_disable     = 1
}

storage "raft" {
  path = "/vault/data"                # персистентный том
}

api_addr     = "http://vault:8200"   # адрес для клиентов внутри сети docker
cluster_addr = "http://vault:8201"

ui = true
disable_mlock = true