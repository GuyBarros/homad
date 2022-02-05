job "grafana" {
  datacenters = ["dc1"]
  type        = "service"
  region      = "global"

  group "grafana" {
    network {
      port "grafana" {
        to = 3000
      }
    }

    ephemeral_disk {
      migrate = true
      size    = 100
      sticky  = true
    }

    service {
      name = "grafana"
      port = "grafana"
      task = "grafana"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.grafana.rule=Host(`grafana.homad.dsb.dev`)",
        "traefik.http.routers.grafana.entrypoints=https",
        "traefik.http.routers.grafana.tls.certresolver=cloudflare"
      ]

      check {
        type     = "http"
        path     = "/api/health"
        interval = "10s"
        timeout  = "30s"
      }
    }

    task "grafana" {
      driver = "docker"

      vault {
        policies      = ["grafana-reader"]
        change_mode   = "signal"
        change_signal = "SIGUSR1"
      }

      config {
        image = "grafana/grafana:8.3.4"
        ports = ["grafana"]

        volumes = [
          "local/data:/grafana",
          "local/grafana.ini:/etc/grafana/grafana.ini",
        ]
      }

      template {
        destination = "secrets/grafana.env"
        env         = true
        data        = <<EOT
{{- with secret "grafana/data/auth" }}
GF_SECURITY_ADMIN_USER={{.Data.data.username}}
GF_SECURITY_ADMIN_PASSWORD={{.Data.data.password}}
{{ end }}
EOT
      }

      template {
        destination = "local/grafana.ini"
        data        = <<EOT
{{- key "homad/grafana/grafana.ini" }}
EOT
      }

      logs {
        max_files = 1
      }
    }
  }
}