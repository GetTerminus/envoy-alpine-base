# 3f59fb5c0f6554f8b3f2e73ab4c1437a63d42668 is the commit for Envoy 1.7.0
FROM envoyproxy/envoy-alpine:3f59fb5c0f6554f8b3f2e73ab4c1437a63d42668

# Set the following env vars at run time
# ENVOY_DOMAIN # The local domain that envoy listens on, this should be a loopback, such as lvh.me

# Default env vars, override at run time if desired
ENV ENVOY_LOG_LEVEL warn

# install requisite packages
RUN apk --no-cache add \
    bind-tools \
    python \
    py-pip \
    tini \
 && pip install --upgrade \
    Jinja2 \
    pip \
    supervisor

# copy the config files for envoy, and the startup files for supervisord
COPY etc/ /etc/

# copy bin
COPY bin/* /usr/local/bin/

ENTRYPOINT [ "/sbin/tini", "--" ]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
