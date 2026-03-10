#!/bin/bash

if [ -z "$1" ]; then
echo "Uso: $0 http://site.com"
exit 1
fi

TARGET=$1
REPORT="js_report.txt"
TMPDIR=$(mktemp -d)

INDEX="$TMPDIR/index.html"
JSFILE="$TMPDIR/all_js.js"

echo "[+] Baixando página..."
curl -ks "$TARGET" -o "$INDEX"

echo "[+] Extraindo JS..."

grep -oE 'src="[^"]+\.js"' "$INDEX" | cut -d'"' -f2 | while read js
do

    if [[ $js == http* ]]; then
        curl -ks "$js" >> "$JSFILE"
        echo "" >> "$JSFILE"

    elif [[ $js == /* ]]; then
        DOMAIN=$(echo $TARGET | awk -F/ '{print $1"//"$3}')
        curl -ks "$DOMAIN$js" >> "$JSFILE"
        echo "" >> "$JSFILE"

    else
        BASE=$(echo $TARGET | sed 's/\/[^\/]*$//')
        curl -ks "$BASE/$js" >> "$JSFILE"
        echo "" >> "$JSFILE"
    fi

done

echo "[+] Gerando relatório..."

echo "===================================" > "$REPORT"
echo "       JAVASCRIPT RECON REPORT      " >> "$REPORT"
echo "===================================" >> "$REPORT"
echo "Target: $TARGET" >> "$REPORT"
echo "" >> "$REPORT"

section () {

RESULT=$(grep -Eo -- "$2" "$JSFILE" | sort -u)

if [ ! -z "$RESULT" ]; then
echo "" >> "$REPORT"
echo "========== $1 ==========" >> "$REPORT"
echo "$RESULT" >> "$REPORT"
fi

}

section "ALL URLS" "(https?://[^\"\'\`\s\<\>]+)"
section "API ENDPOINTS" "(/api/[^\"\'\`\s\<\>]+|/v[0-9]+/[^\"\'\`\s\<\>]+)"
section "S3 BUCKETS" "s3://[a-zA-Z0-9.-]+|[a-zA-Z0-9.-]+\.s3\.amazonaws\.com"
section "FIREBASE" "[a-zA-Z0-9-]+\.firebaseio\.com"
section "EMAILS" "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
section "JWT TOKENS" "eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*"
section "AWS KEYS" "(AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ABIA[0-9A-Z]{16}|ACCA[0-9A-Z]{16})"
section "GOOGLE API KEYS" "AIza[0-9A-Za-z\-_]{35}"
section "DISCORD WEBHOOKS" "https://discord\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+"
section "SLACK WEBHOOKS" "https://hooks\.slack\.com/services/T[a-zA-Z0-9_]+/B[a-zA-Z0-9_]+/[a-zA-Z0-9_]+"
section "GRAPHQL" "(graphql|gql|query|mutation)[^\"']*"
section "INTERNAL IPS" "(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})"
section "PRIVATE KEYS" "-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY( BLOCK)?-----"
section "GITHUB TOKENS" "(ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|ghu_[a-zA-Z0-9]{36}|ghs_[a-zA-Z0-9]{36}|ghr_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59})"
section "CREDENTIAL KEYWORDS" "(password|passwd|pwd|secret|api_key|apikey|token|auth)"

echo "" >> "$REPORT"
echo "===================================" >> "$REPORT"
echo "           END OF REPORT            " >> "$REPORT"
echo "===================================" >> "$REPORT"

echo ""
echo "[+] Relatório gerado: $REPORT"

rm -rf "$TMPDIR"
