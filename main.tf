
locals {
  tmp_dir     = "${path.cwd}/.tmp"
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.resource_group_name
  name        = var.name != "" ? var.name : "${replace(local.name_prefix, "/[^a-zA-Z0-9_\\-\\.]/", "")}-${var.label}"
  key_name    = "${local.name}-key"
  role        = "Manager"
  service     = "sysdig-monitor"
}

resource null_resource print_names {
  provisioner "local-exec" {
    command = "echo 'Resource group: ${var.resource_group_name}'"
  }
}

data "ibm_resource_group" "tools_resource_group" {
  depends_on = [null_resource.print_names]

  name = var.resource_group_name
}

// SysDig - Monitoring
resource ibm_resource_instance sysdig_instance {
  count             = var.provision ? 1 : 0

  name              = local.name
  service           = local.service
  plan              = var.plan
  location          = var.region
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  tags              = setsubtract(var.tags, [""])

  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

data ibm_resource_instance sysdig_instance {
  depends_on        = [ibm_resource_instance.sysdig_instance]

  name              = local.name
  service           = local.service
  resource_group_id = data.ibm_resource_group.tools_resource_group.id
  location          = var.region
}

resource ibm_resource_key sysdig_instance_key {

  name                 = local.key_name
  resource_instance_id = data.ibm_resource_instance.sysdig_instance.id
  role                 = local.role

  timeouts {
    create = "15m"
    delete = "15m"
  }
}
