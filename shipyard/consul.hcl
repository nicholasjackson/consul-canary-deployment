module "consul" {
  source = "github.com/nicholasjackson/hashicorp-shipyard-modules//modules/consul"
}

module "smi_controller" {
  depends_on = ["module.consul"]
  source = "github.com/nicholasjackson/hashicorp-shipyard-modules//modules/smi-controller"
}