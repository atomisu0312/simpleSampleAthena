#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION=$(aws configure get region)

echo "ACCOUNT_ID: ${ACCOUNT_ID}"
echo "REGION: ${REGION}"


aws glue start-crawler --name Crawler-${ACCOUNT_ID}-${REGION}

# クローラの状況をモニタリング
while true; do
    CRAWLER_STATUS=$(aws glue get-crawler --name Crawler-${ACCOUNT_ID}-${REGION} --query 'Crawler.State' --output text)

    if [ "$CRAWLER_STATUS" == "READY" ]; then
        echo "Crawler completed successfully!"
        break
    elif [ "$QUERY_STATUS" == "FAILED" ] || [ "$QUERY_STATUS" == "CANCELLED" ]; then
        echo "Query failed or was cancelled!"
        exit 1
    fi

    echo "Waiting for crawler to complete..."
    sleep 10
done

