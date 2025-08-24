#!/bin/bash

## 必要に応じて変更
export GOOGLE_CLOUD_PROJECT="hanzawa-yuya"
export GOOGLE_CLOUD_LOCATION="global"
export WORKLOAD_IDENTITY_POOL="gemini-cli-pool"
export WORKLOAD_IDENTITY_PROVIDER="github"
export GITHUB_REPO="yuya-hanzawa/try-run-gemini-cli"
export SA_ID="gemini-cli"
export SA_EMAIL="${SA_ID}@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"

## 1. Workload Identity Poolの作成
gcloud iam workload-identity-pools create "${WORKLOAD_IDENTITY_POOL}" \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --location="${GOOGLE_CLOUD_LOCATION}"

## 2. Workload Identity Providerの作成
gcloud iam workload-identity-pools providers create-oidc "${WORKLOAD_IDENTITY_PROVIDER}" \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --location="${GOOGLE_CLOUD_LOCATION}" \
    --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'" \
    --issuer-uri="https://token.actions.githubusercontent.com"

WIF_POOL_ID=$(gcloud iam workload-identity-pools describe "${WORKLOAD_IDENTITY_POOL}" \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --location="${GOOGLE_CLOUD_LOCATION}" \
    --format="value(name)")

PRINCIPAL_SET="principalSet://iam.googleapis.com/${WIF_POOL_ID}/attribute.repository/${GITHUB_REPO}"

WIF_PROVIDER_FULL=$(gcloud iam workload-identity-pools providers describe "${WORKLOAD_IDENTITY_PROVIDER}" \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --location="${GOOGLE_CLOUD_LOCATION}" \
    --workload-identity-pool="${WORKLOAD_IDENTITY_POOL}" \
    --format="value(name)")

## 3. Workload Identityが借用するサービスアカウントの作成
gcloud iam service-accounts create "${SA_ID}" \
    --project="${GOOGLE_CLOUD_PROJECT}"

# 4. 必要な権限の付与
## Vertex AIを呼び出す権限をサービスアカウントに付与
gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
    --role="roles/aiplatform.user" \
    --member="serviceAccount:${SA_EMAIL}" \
    --condition=None

## 外部IDがサービスアカウントを借用する権限を付与
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
    --project="${GOOGLE_CLOUD_PROJECT}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="${PRINCIPAL_SET}"

# 5. GitHubのリポジトリに変数を追加
echo "GOOGLE_CLOUD_PROJECT: ${GOOGLE_CLOUD_PROJECT}"
echo "GOOGLE_CLOUD_LOCATION: ${GOOGLE_CLOUD_LOCATION}"
echo "SERVICE_ACCOUNT_EMAIL: ${SA_EMAIL}"
echo "GCP_WIF_PROVIDER: ${WIF_PROVIDER_FULL}"
