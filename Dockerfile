FROM alpine/git AS builder

RUN git clone https://github.com/acmesh-official/acme.sh.git /install_acme.sh/

FROM alpine:latest

RUN apk --no-cache add -f \
  bash \
  bind-tools \
  coreutils \
  curl \
  jq \
  libidn \
  oath-toolkit-oathtool \
  openssl \
  openssh-client \
  python3 \
  sed \
  socat \
  tzdata \
  tar

# Install Google Cloud SDK
RUN curl -sSL https://sdk.cloud.google.com | bash > /dev/null
ENV PATH $PATH:/root/google-cloud-sdk/bin

# Remove unncessary packages
RUN apk del \
    bash

# Environment variables for acme.sh
ENV LE_CONFIG_HOME /acme.sh
ARG AUTO_UPGRADE=1
ENV AUTO_UPGRADE $AUTO_UPGRADE

#Install acme.sh
COPY --from=builder /install_acme.sh/* /install_acme.sh/
RUN cd /install_acme.sh && ([ -f /install_acme.sh/acme.sh ] && /install_acme.sh/acme.sh --install || curl https://get.acme.sh | sh) && rm -rf /install_acme.sh/
RUN ln -s  /root/.acme.sh/acme.sh  /usr/local/bin/acme.sh && crontab -l | grep acme.sh | sed 's#> /dev/null##' | crontab -

RUN for verb in help \
  version \
  install \
  uninstall \
  upgrade \
  issue \
  signcsr \
  deploy \
  install-cert \
  renew \
  renew-all \
  revoke \
  remove \
  list \
  info \
  showcsr \
  install-cronjob \
  uninstall-cronjob \
  cron \
  toPkcs \
  toPkcs8 \
  update-account \
  register-account \
  create-account-key \
  create-domain-key \
  createCSR \
  deactivate \
  deactivate-account \
  set-notify \
  set-default-ca \
  set-default-chain \
  ; do \
    printf -- "%b" "#!/usr/bin/env sh\n/root/.acme.sh/acme.sh --${verb} --config-home /acme.sh \"\$@\"" >/usr/local/bin/--${verb} && chmod +x /usr/local/bin/--${verb} \
  ; done

RUN printf "%b" '#!'"/usr/bin/env sh\n \
if [ \"\$1\" = \"daemon\" ];  then \n \
 trap \"echo stop && killall crond && exit 0\" SIGTERM SIGINT \n \
 crond && sleep infinity &\n \
 wait \n \
else \n \
 exec -- \"\$@\"\n \
fi" >/entry.sh && chmod +x /entry.sh

VOLUME /acme.sh

ENTRYPOINT ["/entry.sh"]
CMD ["--help"]