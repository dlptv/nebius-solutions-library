locals {
  # Sizing tier. Auto-derived from worker_count unless forced via sizing_tier_override.
  # The bucket boundaries below are the single source of truth for the worker-count -> tier mapping.
  sizing_tier = coalesce(
    var.sizing_tier_override,
    var.worker_count < 10 ? "XS" :
    var.worker_count < 100 ? "S" :
    var.worker_count < 500 ? "M" :
    var.worker_count < 2000 ? "L" : "XL"
  )

  # Per-component pod resources for the system/observability components that fall over on big clusters.
  # Keyed component-major (component -> tier -> value) so each component's ramp across tiers is easy to read and tune.
  # Numeric entries (cpu cores / GiB) feed the SlurmCluster CR; string entries (e.g. "24Gi", "6000m") feed the
  # soperator-fluxcd Helm values.
  component_presets = {
    exporter = {
      XS = { cpu = 0.25, memory = 0.25, ephemeral_storage = 0.5 }
      S  = { cpu = 0.5, memory = 0.5, ephemeral_storage = 0.5 }
      M  = { cpu = 1, memory = 1, ephemeral_storage = 1 }
      L  = { cpu = 1, memory = 1, ephemeral_storage = 1 }
      XL = { cpu = 2, memory = 2, ephemeral_storage = 2 }
    }
    rest = {
      XS = { cpu = 2, memory = 8, ephemeral_storage = 0.5 }
      S  = { cpu = 3, memory = 12, ephemeral_storage = 0.5 }
      M  = { cpu = 6, memory = 24, ephemeral_storage = 2 }
      L  = { cpu = 12, memory = 64, ephemeral_storage = 5 }
      XL = { cpu = 20, memory = 120, ephemeral_storage = 5 }
    }
    mariadb = {
      # In practice, it uses up to 4GB memory, and almost no CPU, maybe we overprovision here.
      XS = { cpu = 2, memory = 12, ephemeral_storage = 16 }
      S  = { cpu = 2, memory = 12, ephemeral_storage = 16 }
      M  = { cpu = 2, memory = 12, ephemeral_storage = 16 }
      L  = { cpu = 6, memory = 32, ephemeral_storage = 32 }
      XL = { cpu = 8, memory = 48, ephemeral_storage = 32 }
    }
    node_configurator = {
      XS = { requests = { cpu = 0.5, memory = 0.25 }, limits = { memory = 0.25 } }
      S  = { requests = { cpu = 0.5, memory = 0.25 }, limits = { memory = 0.25 } }
      M  = { requests = { cpu = 0.5, memory = 0.25 }, limits = { memory = 0.25 } }
      L  = { requests = { cpu = 0.5, memory = 0.5 }, limits = { memory = 0.5 } }
      XL = { requests = { cpu = 1, memory = 1 }, limits = { memory = 1 } }
    }
    slurm_operator = {
      XS = { requests = { cpu = 1, memory = 2 }, limits = { memory = 2 } }
      S  = { requests = { cpu = 1, memory = 2 }, limits = { memory = 2 } }
      M  = { requests = { cpu = 1, memory = 2 }, limits = { memory = 2 } }
      L  = { requests = { cpu = 1, memory = 3 }, limits = { memory = 3 } }
      XL = { requests = { cpu = 1, memory = 4 }, limits = { memory = 4 } }
    }
    slurm_checks = {
      XS = { requests = { cpu = 0.5, memory = 2 }, limits = { memory = 2 } }
      S  = { requests = { cpu = 0.5, memory = 2 }, limits = { memory = 2 } }
      M  = { requests = { cpu = 1, memory = 2 }, limits = { memory = 2 } }
      L  = { requests = { cpu = 1, memory = 3 }, limits = { memory = 3 } }
      XL = { requests = { cpu = 1, memory = 4 }, limits = { memory = 4 } }
    }
    kruise_daemon = {
      XS = { cpu = 0.05, memory = 0.128 }
      S  = { cpu = 0.1, memory = 0.25 }
      M  = { cpu = 0.25, memory = 0.5 }
      L  = { cpu = 0.5, memory = 1 }
      XL = { cpu = 1, memory = 4 }
    }
    dcgm_exporter = {
      XS = { cpu = 0.05, memory = 0.5 }
      S  = { cpu = 0.05, memory = 0.5 }
      M  = { cpu = 0.05, memory = 0.5 }
      L  = { cpu = 0.05, memory = 0.5 }
      XL = { cpu = 0.05, memory = 0.5 }
    }
    nfs_server = {
      XS = { cpu = 1, memory = 1 }
      S  = { cpu = 1, memory = 1 }
      M  = { cpu = 1, memory = 2 }
      L  = { cpu = 2, memory = 4 }
      XL = { cpu = 2, memory = 4 }
    }
    spo = {
      XS = { daemon = { cpu = "100m", memory = "128Mi" }, controller = { cpu = "500m", memory = "3Gi" } }
      S  = { daemon = { cpu = "100m", memory = "128Mi" }, controller = { cpu = "500m", memory = "3Gi" } }
      M  = { daemon = { cpu = "100m", memory = "128Mi" }, controller = { cpu = "500m", memory = "3Gi" } }
      L  = { daemon = { cpu = "150m", memory = "256Mi" }, controller = { cpu = "750m", memory = "4Gi" } }
      XL = { daemon = { cpu = "200m", memory = "512Mi" }, controller = { cpu = "1000m", memory = "6Gi" } }
    }
    kruise_manager = {
      XS = { cpu = "1", memory = "2Gi" }
      S  = { cpu = "1", memory = "2Gi" }
      M  = { cpu = "2", memory = "4Gi" }
      L  = { cpu = "3", memory = "8Gi" }
      XL = { cpu = "8", memory = "16Gi" }
    }
    vm_single = {
      XS = { memory = "24Gi", cpu = "6000m", size = "512Gi", gomaxprocs = 6 }
      S  = { memory = "24Gi", cpu = "6000m", size = "512Gi", gomaxprocs = 6 }
      M  = { memory = "24Gi", cpu = "8000m", size = "512Gi", gomaxprocs = 8 }
      L  = { memory = "24Gi", cpu = "12000m", size = "512Gi", gomaxprocs = 12 }
      XL = { memory = "24Gi", cpu = "25000m", size = "512Gi", gomaxprocs = 25 }
    }
    vm_agent = {
      XS = { memory = "10Gi", cpu = "5000m" }
      S  = { memory = "10Gi", cpu = "5000m" }
      M  = { memory = "12Gi", cpu = "6000m" }
      L  = { memory = "16Gi", cpu = "8000m" }
      XL = { memory = "25Gi", cpu = "12000m" }
    }
    vm_logs = {
      XS = { memory = "2Gi", cpu = "1000m", size = "256Gi" }
      S  = { memory = "2Gi", cpu = "1000m", size = "256Gi" }
      M  = { memory = "4Gi", cpu = "1000m", size = "256Gi" }
      L  = { memory = "4Gi", cpu = "2000m", size = "512Gi" }
      XL = { memory = "8Gi", cpu = "4000m", size = "512Gi" }
    }
    events_collector = {
      XS = { memory = "128Mi", cpu = "100m" }
      S  = { memory = "128Mi", cpu = "100m" }
      M  = { memory = "256Mi", cpu = "150m" }
      L  = { memory = "256Mi", cpu = "250m" }
      XL = { memory = "512Mi", cpu = "500m" }
    }
    logs_collector = {
      XS = { memory = "200Mi", cpu = "200m" }
      S  = { memory = "200Mi", cpu = "200m" }
      M  = { memory = "256Mi", cpu = "250m" }
      L  = { memory = "384Mi", cpu = "400m" }
      XL = { memory = "512Mi", cpu = "750m" }
    }
    jail_logs_collector = {
      XS = { memory = "1Gi", cpu = "1000m" }
      S  = { memory = "1Gi", cpu = "1000m" }
      M  = { memory = "1Gi", cpu = "1000m" }
      L  = { memory = "2Gi", cpu = "2000m" }
      XL = { memory = "4Gi", cpu = "4000m" }
    }
    nccl_profiles_collector = {
      XS = { memory = "200Mi", cpu = "500m" }
      S  = { memory = "200Mi", cpu = "500m" }
      M  = { memory = "200Mi", cpu = "500m" }
      L  = { memory = "256Mi", cpu = "500m" }
      XL = { memory = "512Mi", cpu = "1000m" }
    }
  }

  # Node VM presets (cpu-d3) for the single-pod-per-node CPU nodesets, whose pod size == node size.
  # Values must be valid cpu-d3 presets from modules/available_resources.
  node_presets = {
    controller = {
      XS = "16vcpu-64gb"
      S  = "16vcpu-64gb"
      M  = "16vcpu-64gb"
      L  = "16vcpu-64gb"
      XL = "16vcpu-64gb"
    }
    accounting = {
      XS = "8vcpu-32gb"
      S  = "8vcpu-32gb"
      M  = "8vcpu-32gb"
      L  = "16vcpu-64gb"
      XL = "32vcpu-128gb"
    }
    nfs = {
      XS = "32vcpu-128gb"
      S  = "32vcpu-128gb"
      M  = "32vcpu-128gb"
      L  = "64vcpu-256gb"
      XL = "128vcpu-512gb"
    }
    system = {
      XS = "16vcpu-64gb"
      S  = "16vcpu-64gb"
      M  = "16vcpu-64gb"
      L  = "32vcpu-128gb"
      XL = "64vcpu-256gb"
    }
  }

  # Effective per-component resources: an explicit component_overrides entry replaces the tier value wholesale;
  # everything else takes the resolved tier's column.
  preset = {
    exporter                = coalesce(var.component_overrides.exporter, local.component_presets.exporter[local.sizing_tier])
    rest                    = coalesce(var.component_overrides.rest, local.component_presets.rest[local.sizing_tier])
    mariadb                 = coalesce(var.component_overrides.mariadb, local.component_presets.mariadb[local.sizing_tier])
    node_configurator       = coalesce(var.component_overrides.node_configurator, local.component_presets.node_configurator[local.sizing_tier])
    slurm_operator          = coalesce(var.component_overrides.slurm_operator, local.component_presets.slurm_operator[local.sizing_tier])
    slurm_checks            = coalesce(var.component_overrides.slurm_checks, local.component_presets.slurm_checks[local.sizing_tier])
    kruise_daemon           = coalesce(var.component_overrides.kruise_daemon, local.component_presets.kruise_daemon[local.sizing_tier])
    dcgm_exporter           = coalesce(var.component_overrides.dcgm_exporter, local.component_presets.dcgm_exporter[local.sizing_tier])
    nfs_server              = coalesce(var.component_overrides.nfs_server, local.component_presets.nfs_server[local.sizing_tier])
    spo                     = coalesce(var.component_overrides.spo, local.component_presets.spo[local.sizing_tier])
    kruise_manager          = coalesce(var.component_overrides.kruise_manager, local.component_presets.kruise_manager[local.sizing_tier])
    vm_single               = coalesce(var.component_overrides.vm_single, local.component_presets.vm_single[local.sizing_tier])
    vm_agent                = coalesce(var.component_overrides.vm_agent, local.component_presets.vm_agent[local.sizing_tier])
    vm_logs                 = coalesce(var.component_overrides.vm_logs, local.component_presets.vm_logs[local.sizing_tier])
    events_collector        = coalesce(var.component_overrides.events_collector, local.component_presets.events_collector[local.sizing_tier])
    logs_collector          = coalesce(var.component_overrides.logs_collector, local.component_presets.logs_collector[local.sizing_tier])
    jail_logs_collector     = coalesce(var.component_overrides.jail_logs_collector, local.component_presets.jail_logs_collector[local.sizing_tier])
    nccl_profiles_collector = coalesce(var.component_overrides.nccl_profiles_collector, local.component_presets.nccl_profiles_collector[local.sizing_tier])
  }

  # Node VM preset per CPU nodeset for the resolved tier
  # (overridden per nodeset by the caller via the nodeset's own `preset` field).
  node_preset = {
    system     = local.node_presets.system[local.sizing_tier]
    controller = local.node_presets.controller[local.sizing_tier]
    accounting = local.node_presets.accounting[local.sizing_tier]
    nfs        = local.node_presets.nfs[local.sizing_tier]
  }
}
