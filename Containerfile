FROM nginx:alpine

  RUN apk add --no-cache gettext make yq nginx-module-njs && \
    rm -f /etc/nginx/conf.d/default.conf && \
    rm -rf /usr/share/nginx/html/*

  WORKDIR /build
  COPY Makefile    .
  COPY scripts/    scripts/
  COPY templates/  templates/
  COPY snippets/   /etc/nginx/snippets/
  COPY nginx.conf  /etc/nginx/nginx.conf

  RUN chmod +x scripts/entrypoint.sh

  ENV CONF_D=/etc/nginx/conf.d
  ENV CUSTOM_D=/etc/nginx/custom
  ENV CONFIG=/config
  
  VOLUME /etc/nginx/certs
  VOLUME /config

  EXPOSE 80 443
  ENTRYPOINT ["scripts/entrypoint.sh"]