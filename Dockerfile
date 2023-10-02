FROM alpine:3

RUN apk --no-cache add \
    wireguard-tools iptables ip6tables inotify-tools iputils \
    python3 py3-pip py3-gunicorn py3-cffi\
    procps openresolv bc coredns gnupg net-tools libcap-utils

RUN apk add --no-cache --virtual=build-dependencies \
    build-base elfutils-dev linux-headers gcc git libffi libffi-dev
COPY src/requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt
RUN apk del --no-network build-dependencies

# default wireguard configuration
ENV CONFIGURATION_PATH="/etc/wireguard"
VOLUME /etc/wireguard/
RUN  cd /etc/wireguard/ && \
    echo "[Interface]" > wg0.conf && \
    echo "SaveConfig = true" >> wg0.conf && \
    echo -n "PrivateKey = " >> wg0.conf && \
    wg genkey >> wg0.conf && \
    echo "ListenPort = 51820" >> wg0.conf && \
    echo "Address = ${WG_ADDRESS}" >> wg0.conf && \
    echo "PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth+ -j MASQUERADE" >> wg0.conf && \
    echo "PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth+ -j MASQUERADE" >> wg0.conf && \
    chmod 700 wg0.conf

COPY ./src /opt/wgdashboard

RUN rm -f /opt/wgdashboard/gunicorn.conf.py
WORKDIR /opt/wgdashboard 
CMD ["gunicorn", "--bind", "0.0.0.0:10086", "dashboard:run_dashboard()"]

EXPOSE 10086/tcp
EXPOSE 51820/udp