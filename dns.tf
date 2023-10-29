resource "google_dns_managed_zone" "dns_zone" {
  name     = format("toto-%s-zone", var.toto_environment)
  dns_name = "dev.nimatz.com."
}