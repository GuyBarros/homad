job "pihole" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "system"

  group "pihole" {
    count = 1

    ephemeral_disk {
      migrate = true
      size    = 100
      sticky  = true
    }

    network {
      port "pihole" {
        to = 80
      }

      port "dns" {
        static = 53
      }
    }

    service {
      name = "pihole"
      port = "pihole"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.pihole.rule=Host(`pihole.homad.dsb.dev`)",
        "traefik.http.routers.pihole.entrypoints=https",
        "traefik.http.routers.pihole.tls.certresolver=cloudflare"
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "60s"
        timeout  = "30s"
      }
    }

    task "pihole" {
      driver = "docker"

      config {
        image = "pihole/pihole:2022.01.1"

        ports = [
          "dns",
          "pihole"
        ]

        volumes = [
          "local/storage/pihole:/etc/pihole",
          "local/storage/dnsmasq:/etc/dnsmasq.d",
        ]
      }

      logs {
        max_files = 1
      }

      template {
        destination = "local/pihole.env"
        env         = true
        data        = <<EOT
{{ range ls "homad/pihole" }}
{{.Key}}={{.Value}}
{{ end }}
EOT
      }
    }
  }
}