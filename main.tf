locals {
    projenv  = "${var.project}-${var.environment_name}"
    vmss     = "${var.project}-${var.environment_name}-${var.prefix}"
}

data "azurerm_resource_group" "env" {
  name = "${var.resource_group == "" ? local.projenv : var.resource_group}"
}

data "azurerm_subnet" "env" {
  name                 = "${local.projenv}"
  virtual_network_name = "${local.projenv}"
  resource_group_name  = "${data.azurerm_resource_group.env.name}"
}

data "azurerm_application_security_group" "asg" {
  name                 = "${var.asg == "" ? local.vmss : var.asg}"
  resource_group_name  = "${data.azurerm_resource_group.env.name}"
}

resource "azurerm_lb" "azlb" {
  name                = "${local.vmss}-lb"
  location            = "${data.azurerm_resource_group.env.location}"
  resource_group_name = "${data.azurerm_resource_group.env.name}"
  tags                = "${var.tags}"

  frontend_ip_configuration {
    name                          = "FrontEndIpConfig"
    subnet_id                     = "${data.azurerm_subnet.env.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "azlb" {
  resource_group_name = "${data.azurerm_resource_group.env.name}"
  loadbalancer_id     = "${azurerm_lb.azlb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "azlb" {
  resource_group_name = "${data.azurerm_resource_group.env.name}"
  loadbalancer_id     = "${azurerm_lb.azlb.id}"
  count               = "${length(var.lb_port)}"
  name                = "${element(keys(var.lb_port), count.index)}"
  protocol            = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  port                = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
}

resource "azurerm_lb_rule" "azlb" {
  resource_group_name            = "${data.azurerm_resource_group.env.name}"
  loadbalancer_id                = "${azurerm_lb.azlb.id}"
  count                          = "${length(var.lb_port)}"
  name                           = "${element(keys(var.lb_port), count.index)}"
  frontend_ip_configuration_name = "FrontEndIpConfig"

  protocol                       = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  frontend_port                  = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 0)}"
  backend_port                   = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"

  probe_id                       = "${element(azurerm_lb_probe.azlb.*.id,count.index)}"

  depends_on                     = ["azurerm_lb_probe.azlb"]
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "${local.vmss}"
  location            = "${data.azurerm_resource_group.env.location}"
  resource_group_name = "${data.azurerm_resource_group.env.name}"
  tags                = "${var.tags}"

  count               = "${var.vmcount}"

  # automatic rolling upgrade
  automatic_os_upgrade = false
  upgrade_policy_mode  = "Manual"

/*
  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = "${element(azurerm_lb_probe.azlb.*.id, 0)}"
  */

  sku {
    name     = "${var.vmsize}"
    capacity = "${var.vmcount}"
    tier     = "Standard"
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "${var.prefix}"
    admin_username       = "overlord"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/overlord/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  network_profile {
    name                    = "networkprofile"
    primary                 = true
    accelerated_networking  = "${var.accelerated}"

    ip_configuration {
      name                                   = "IpConfiguration"
      primary                                = true
      subnet_id                              = "${data.azurerm_subnet.env.id}"
      load_balancer_backend_address_pool_ids = [ "${azurerm_lb_backend_address_pool.azlb.id}" ]
      application_security_group_ids         = [ "${data.azurerm_application_security_group.asg.id}" ]
    }
  }
}

resource "azurerm_monitor_autoscale_setting" "vmss" {
  name                = "${local.vmss}"
  resource_group_name = "${data.azurerm_resource_group.env.name}"
  location            = "${data.azurerm_resource_group.env.location}"

  target_resource_id  = "${element(azurerm_virtual_machine_scale_set.vmss.*.id, 0)}"

  profile {
    name = "defaultProfile"

    capacity {
      default = "${var.vmcount}"
      minimum = "${var.vmmin}"
      maximum = "${var.vmmax}"
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "${element(azurerm_virtual_machine_scale_set.vmss.*.id, 0)}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = "${element(azurerm_virtual_machine_scale_set.vmss.*.id, 0)}"
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = "${var.emails}"
    }
  }

  depends_on = [ "azurerm_virtual_machine_scale_set.vmss" ]
}