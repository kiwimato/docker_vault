signed_request=$(python aws.py 127.0.0.1)
iam_request_url=$(echo $signed_request | jq -r .iam_request_url)
iam_request_body=$(echo $signed_request | jq -r .iam_request_body)
iam_request_headers=$(echo $signed_request | jq -r .iam_request_headers) # The role name necessary here is the Vault Role name

# not the AWS IAM Role name
data=$(cat <<EOF
{
  "role":"example-role-name",
  "iam_http_request_method": "POST",
  "iam_request_url": "$iam_request_url",
  "iam_request_body": "$iam_request_body",
  "iam_request_headers": "$iam_request_headers"
}
EOF
)

curl -v --fail \
  --request POST \
  --data "$data" \
  "https://127.0.0.1:8200/v1/auth/aws/login"
