FROM alpine:3
RUN apk --no-cache add wireguard-tools iptables ip6tables inotify-tools python3 py3-pip py3-gunicorn procps openresolv

COPY src/requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# default wireguard configuration
VOLUME /etc/wireguard/
RUN  cd /etc/wireguard/ && \
    echo "[Interface]" > wg0.conf && \
    echo "SaveConfig = true" >> wg0.conf && \
    echo -n "PrivateKey = " >> wg0.conf && \
    wg genkey >> wg0.conf && \
    echo  "ListenPort = 51820" >> wg0.conf && \
    echo  "Address = ${WG_ADDRESS}" >> wg0.conf && \
    chmod 700 wg0.conf

COPY ./src /opt/wgdashboard
WORKDIR /opt/wgdashboard 

# FIXME
CMD ["python3", "dashboard.py"] 

EXPOSE 10086/tcp
EXPOSE 51820/udp