local_ingress "connector-http" {
  target = "k8s_cluster.dc1"
  destination = "localhost"

  port {
    remote = 9090
    local = 30002
  }
}

k8s_ingress "connector-http" {
  cluster = "k8s_cluster.dc1"
  service  = "connector-http"
  namespace = "shipyard"

  network {
    name = "network.dc1"
  }

  port {
    local  = 9090
    remote = 9090
    host   = 10000
  }
}

// ingress to K3s service connector
// sends traffic to an existing service
//ingress "bla" {
//  driver = "k8s"
//
//  config = {
//    cluster = "dc1"
//  }
//  
//  port {
//    remote = 9090
//    local = 30002
//  }
// 
//  // traffic sent to bla is forwarded to this address
//  destination = "connector.shipyard.svc.local"
//}
//
//// ingress from K3s cluster to local machine
//// creates a service called bla in namespace shipyard
//ingress "bla" {
//  driver = "local"
//  
//  port {
//    remote = 9090
//    local = 30002
//  }
//  
//  // traffic sent to bla is forwarded to this address
//  destination = "localhost"
//}
