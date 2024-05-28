FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive

WORKDIR /code

RUN rm -rf /var/lib/apt/lists/*
RUN apt update
RUN apt install -y ansible dos2unix dnsutils python3 python3-pip nano vim
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt
COPY collection.yml /tmp/collection.yml
COPY role.yml /tmp/role.yml
RUN ansible-galaxy collection install -r /tmp/collection.yml
RUN ansible-galaxy install -r /tmp/role.yml
RUN mkdir -p /etc/ansible/.ssh
COPY .ssh/ansible /etc/ansible/.ssh/ansible
RUN chmod 400 /etc/ansible/.ssh/ansible
