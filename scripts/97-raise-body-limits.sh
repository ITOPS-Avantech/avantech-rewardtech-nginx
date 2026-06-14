#!/bin/sh
# Runs at container startup (after the CRS image generates its ModSecurity config,
# e.g. 95-configure-rules.sh) and BEFORE nginx starts.
#
# Why: the image default SecRequestBodyNoFilesLimit is 128 KB, which rejects the
# LSTU saveLSTURecognition base64-PNG JSON upload with HTTP 400 (rule 200002 /
# REQBODY_ERROR). We raise the limits to 50 MB (matching client_max_body_size)
# and use ProcessPartial so oversize bodies are not hard-rejected. nginx
# (client_max_body_size 50M) and rule 9002002 still cap absolute size at 50 MB.
set -eu

LIMIT=52428800   # 50 MB

patch_file() {
    f="$1"
    [ -f "$f" ] || return 0
    sed -ri "s/^[[:space:]]*SecRequestBodyLimit[[:space:]]+[0-9]+/SecRequestBodyLimit ${LIMIT}/" "$f" || true
    sed -ri "s/^[[:space:]]*SecRequestBodyNoFilesLimit[[:space:]]+[0-9]+/SecRequestBodyNoFilesLimit ${LIMIT}/" "$f" || true
    sed -ri "s/^[[:space:]]*SecRequestBodyLimitAction[[:space:]]+[A-Za-z]+/SecRequestBodyLimitAction ProcessPartial/" "$f" || true
}

echo "raise-body-limits: patching ModSecurity request-body limits to ${LIMIT} bytes"

# Patch every config under /etc/modsecurity.d that declares the directive.
for f in $(grep -rlE 'SecRequestBodyNoFilesLimit|SecRequestBodyLimit ' /etc/modsecurity.d/ 2>/dev/null); do
    echo "raise-body-limits: patching $f"
    patch_file "$f"
done

echo "raise-body-limits: effective values:"
grep -rE 'SecRequestBody(Limit|NoFilesLimit|LimitAction) ' /etc/modsecurity.d/ 2>/dev/null || true
