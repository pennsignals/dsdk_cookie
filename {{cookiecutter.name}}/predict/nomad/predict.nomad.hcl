job "{{ cookiecutter.name }}_predict" {
  datacenters = ["dc1"]

  type="batch"

  periodic = {
    cron             = "{{ cookiecutter.predict_cron }}"
    prohibit_overlap = true
    time_zone        = "America/New_York"
  }

  group "default" {
    vault {
      policies = ["{{ cookiecutter.name }}"]
    }

    restart {
      attempts = 24
      delay    = "5m"
      interval = "24h"
      mode     = "fail"
    }

    task "predict" {
      config = {
        image = "{{ cookiecutter.registry }}/{{ cookiecutter.name }}.predict:[[ (.version) ]]"

        volumes = [
          "/deploy/models/{{ cookiecutter.name }}:/model:ro"
        ]
      }

      driver = "docker"

      env {
        CONFIG = "${NOMAD_TASK_DIR}/configuration.yaml"
        ENV = "${NOMAD_SECRETS_DIR}/secrets.env"
      }

      resources {
        cpu    = {{ cookiecutter.predict_cpu }}
        memory = {{ cookiecutter.predict_memory }}
      }

      template {
        data = <<EOH
{{ '{{' }} key "{{ cookiecutter.organization }}/{{ cookiecutter.name }}/predict/configuration.yaml" {{ '}}' }}
EOH
        destination = "${NOMAD_TASK_DIR}/configuration.yaml"
      }

      # *templating and vault policy* require the additional '/data' and '.data' seen here:
      template {
        data = <<EOH
{{ '{{' }} with secret "kv/data/{{ cookiecutter.organization }}/{{ cookiecutter.name }}/predict/secrets.env" {{ '}}' }}
{{ '{{' }} range $k, $v := .Data.data {{ '}}{{' }} $k {{ '}}={{' }} $v {{ '}}' }}
{{ '{{' }} end {{ '}}{{' }} end {{ '}}' }}
EOH
        destination = "${NOMAD_SECRETS_DIR}/secrets.env"
      }
    }
  }
}
