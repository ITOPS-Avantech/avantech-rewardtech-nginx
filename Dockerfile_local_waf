# OWASP ModSecurity CRS image bundles:
#   - nginx (mainline)
#   - ModSecurity v3 connector
#   - OWASP Core Rule Set (CRS)
FROM owasp/modsecurity-crs:nginx-alpine

USER root

# Remove the default server block template so our nginx.conf.template takes over
RUN rm -f /etc/nginx/templates/conf.d/default.conf.template

# Copy custom nginx.conf as a template so envsubst can process it correctly
COPY nginx.conf /etc/nginx/templates/nginx.conf.template

# Copy ModSecurity custom overrides & exclusions (loaded after CRS rules)
COPY modsecurity-override.conf /etc/modsecurity.d/modsecurity-override.conf

# Copy SSL certificates (self-signed for dev)
COPY localhost+2.pem /etc/ssl/certs/server.crt
COPY localhost+2-key.pem /etc/ssl/private/server.key

EXPOSE 443
EXPOSE 80
