job "postgres" {
  datacenters = ["homad"]
  type        = "service"
  region      = "global"

  group "postgres" {
    network {
      port "postgres" {
        to = 5432
      }
    }

    ephemeral_disk {
      migrate = true
      size    = 1024
      sticky  = true
    }

    service {
      name = "postgres"
      port = "postgres"
      task = "postgres"

      check {
        type     = "tcp"
        port     = "postgres"
        interval = "10s"
        timeout  = "30s"
      }
    }

    task "postgres" {
      driver = "docker"

      vault {
        policies      = ["postgres-reader"]
        change_mode   = "signal"
        change_signal = "SIGUSR1"
      }

      config {
        image = "postgres:13"
        ports = ["postgres"]

        volumes = [
          "local/data:/data"
        ]
      }

      template {
        destination = "secrets/postgres.env"
        env         = true
        data        = <<EOT
{{- with secret "postgres/data/root" }}
POSTGRES_USER={{.Data.data.user}}
POSTGRES_PASSWORD={{.Data.data.password}}
{{ end }}
EOT
      }

      template {
        destination = "local/postgres.env"
        env         = true
        data        = <<EOT
{{ range ls "homad/postgres" }}
{{.Key}}={{.Value}}
{{ end }}
EOT
      }

      logs {
        max_files = 1
      }
    }
  }
}