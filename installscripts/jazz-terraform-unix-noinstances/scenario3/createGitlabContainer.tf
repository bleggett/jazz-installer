provider "docker" {
}

resource "docker_container" "gitlab" {
  image = "${docker_image.gitlab.latest}"
  name  = "gitlab"
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
    file = "/root/gitlab.sh"
    content = "${file("/Users/blegget1/Source/jazz-installer/installscripts/dockerfiles/gitlab/gitlab.sh")}"
  }

  provisioner "local-exec" {
    command = "sleep 60"
  }
  provisioner "local-exec" {
    command = "docker exec gitlab sh /root/gitlab.sh abcd1234 > credentials.txt 2>&1"
  }
}

resource "docker_image" "gitlab" {
  name = "gitlab/gitlab-ce:latest"
}

output "gitlab_ip" {
  value = "${docker_container.gitlab.ip_address}"
}
