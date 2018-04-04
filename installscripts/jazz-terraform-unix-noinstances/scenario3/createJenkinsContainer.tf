provider "docker" {
}

resource "docker_container" "jenkins" {
  image = "${docker_image.jenkins.latest}"
  name  = "jenkins"
  //hostname = ${ip}
  restart = "always"
  must_run = true
  ports {
    external = "443"
    internal = "443"
  }
  ports {
    external = "80"
    internal = "80"
  }
  ports {
    external = "2201"
    internal = "22"
  }
  volumes {
    # host_path = "/tmp/gitlab/configs"
    volume_name = "gitlab-configs"
    container_path = "/etc/gitlab"
  }
  volumes {
    # host_path = "/tmp/gitlab/logs"
    volume_name = "gitlab-logs"
    container_path = "/var/log/gitlab"
  }
  volumes {
    # host_path = "/tmp/gitlab/data"
    volume_name = "gitlab-data"
    container_path = "/var/opt/gitlab"
  }
  upload {
    file = "${var.gitlabCredsShUpload}"
    content = "${file("${var.gitlabCredsShSource}")}"
  }

  # provisioner "local-exec" {
  #   command = "sleep 30"
  # }
  # provisioner "local-exec" {
  #   command = "docker exec gitlab sh ${var.gitlabCredsShUpload} ${var.gitlabPassword} > credentials.txt"
  # }
  # provisioner "local-exec" {
  #   command = "sleep 30"
  # }
  # provisioner "local-exec" {
  #   command = "python privatetoken.py mytoken 2018-12-31 ${var.gitlabPassword}"
  # }

}

resource "docker_image" "jenkins" {
  name = "gitlab/gitlab-ce:latest"
}

output "gitlab_name" {
  value = "${docker_container.gitlab.name}"
}

output "gitlab_ip" {
  value = "${docker_container.gitlab.ip_address}"
}
