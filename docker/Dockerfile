FROM anapsix/alpine-java
ENV INSTALL_DIR /tmp/jazz_installer
ENV ATLASSIAN_CLI_URL "https://bobswift.atlassian.net/wiki/download/attachments/16285777/atlassian-cli-6.7.1-distribution.zip"
ENV TERRAFORM_URL "https://releases.hashicorp.com/terraform/0.9.11/terraform_0.9.11_linux_amd64.zip?_ga=2.191030627.850923432.1499789921-755991382.1496973261"
RUN apk add --no-cache \
    curl \
    unzip \
    python \
    python-dev \
    py-pip \
    build-base \
    libffi-dev \
    openssl-dev \
    libxml2
    git \
  && pip --no-cache-dir install awscli beautifulsoup4 requests lxml \
  && apk del --no-cache \
     python-dev \
     build-base \
     libffi-dev \
     openssl-dev \
  && mkdir $INSTALL_DIR \
  && curl -L $ATLASSIAN_CLI_URL -o $INSTALL_DIR/atlassian-cli-6.7.1-distribution.zip \
  && unzip -o $INSTALL_DIR/atlassian-cli-6.7.1-distribution.zip -d $INSTALL_DIR \
  && rm $INSTALL_DIR/atlassian-cli-6.7.1-distribution.zip \
  && curl -v -L $TERRAFORM_URL -o $INSTALL_DIR/terraform.zip \
  && unzip -o $INSTALL_DIR/terraform.zip -d /usr/bin \
  && rm $INSTALL_DIR/terraform.zip \
