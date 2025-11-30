FROM alpine:latest AS builder
ARG CNI_VERSION=v1.8.0
RUN apk add --no-cache curl && mkdir -p /opt/cni-plugins
RUN curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -xz -C /opt/cni-plugins

FROM alpine:latest
ENV PRE_EXTRACTED_DIR="/opt/cni-plugins"
COPY --from=builder /opt/cni-plugins ${PRE_EXTRACTED_DIR}
COPY install.sh /
ENTRYPOINT ["/install.sh"]
