resource "google_dns_managed_zone" "dns_zone" {
  name     = format("toto-%s-zone", var.toto_environment)
  dns_name = format("%s.toto.nimatz.com.", var.toto_environment)
}