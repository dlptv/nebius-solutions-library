output "sizing_tier" {
  description = "The resolved sizing tier (XS..XL)."
  value       = local.sizing_tier
}

output "preset" {
  description = "Effective per-component pod resources: the resolved tier's column with component_overrides applied."
  value       = local.preset
}

output "node_preset" {
  description = "Node VM preset per CPU nodeset for the resolved tier (controller/accounting/nfs/system -> preset string)."
  value       = local.node_preset
}

output "all_component_presets" {
  description = "The full component-major pod-resource table (component -> tier -> resources)."
  value       = local.component_presets
}

output "all_node_presets" {
  description = "The full component-major node-preset table (nodeset -> tier -> preset string)."
  value       = local.node_presets
}
