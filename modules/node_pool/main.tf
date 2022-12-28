/**
 * # node_pool
 * Creates
 * - Autoscaling Group for agent nodes
 * - (Spot)Fleet for the first control plane node(seed)
 * - (Spot)Fleet for the other control plane node
 */

terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = ">= 4.14"
  }
}
