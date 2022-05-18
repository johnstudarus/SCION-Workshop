resource "metal_device" "this" {

  hostname         = "${var.name}"
  plan             = "c3.small.x86"
  metro            = "${var.metro}"
  operating_system = "ubuntu_22_04"
  billing_cycle    = "hourly"
  project_id       = "${var.project_id}"

  user_data        = "#cloud-config\n\nssh_authorized_keys:\n  - \"${var.public_key_str}\""

  connection {
    type        = "ssh"
    host        = self.access_public_ipv4
    user        = "root"
    private_key = "${var.private_key_str}"
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i 's/127.0.0.1.*/127.0.0.1 localhost/' /etc/hosts",
    ]
  }

  provisioner "file" {
    content     = data.template_file.CommonServerSetup.rendered
    destination = "CommonServerSetup.sh"
  }

  provisioner "file" {
    content     = data.template_file.ControllerKeystone.rendered
    destination = "ControllerKeystone.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash CommonServerSetup.sh > CommonServerSetup.out",
      "bash ControllerKeystone.sh > ControllerKeystone.out",
    ]
  }
}

data "template_file" "CommonServerSetup" {
  template = file("${path.module}/templates/CommonServerSetup.sh")

  vars = {
    KEYSTONE_HOSTNAME = "${var.name}",
    ADMIN_PASS = "${var.admin_password.result}",
    DEMO_PASS = "${var.demo_password.result}",
    RABBIT_PASS = "${random_password.rabbit_password.result}",
    KEYSTONE_DBPASS = "${random_password.keystone_dbpass.result}",
  }
}

data "template_file" "ControllerKeystone" {
  template = file("${path.module}/templates/ControllerKeystone.sh")

  vars = {
    KEYSTONE_HOSTNAME = "${var.name}",
    ADMIN_PASS = "${var.admin_password.result}",
    DEMO_PASS = "${var.demo_password.result}",
    RABBIT_PASS = "${random_password.rabbit_password.result}",
    KEYSTONE_DBPASS = "${random_password.keystone_dbpass.result}",
  }
}
