#!/bin/bash

ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION=$(aws configure get region)

echo "ACCOUNT_ID: ${ACCOUNT_ID}"
echo "REGION: ${REGION}"


# クエリを実行して実行IDを変数に保存
QUERY_EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "SELECT * FROM \"database-${ACCOUNT_ID}-${REGION}\".\"sample-tabledata\" ORDER BY name DESC" \
    --query-execution-context "Database=database-${ACCOUNT_ID}-${REGION}" \
    --result-configuration "OutputLocation=s3://data-athena-${ACCOUNT_ID}/athena-output/" \
    --query 'QueryExecutionId' \
    --output text)

echo "Query Execution ID: $QUERY_EXECUTION_ID"


# クエリの実行状況をモニタリング
while true; do
    QUERY_STATUS=$(aws athena get-query-execution --query-execution-id $QUERY_EXECUTION_ID --query 'QueryExecution.Status.State' --output text)
    echo "Query Status: $QUERY_STATUS"

    if [ "$QUERY_STATUS" == "SUCCEEDED" ]; then
        echo "Query completed successfully!"
        break
    elif [ "$QUERY_STATUS" == "FAILED" ] || [ "$QUERY_STATUS" == "CANCELLED" ]; then
        echo "Query failed or was cancelled!"
        exit 1
    fi
    
    echo "Waiting for query to complete..."
    sleep 3
done

# JSONとしてダンプ
aws athena get-query-results --query-execution-id $QUERY_EXECUTION_ID > "result/${QUERY_EXECUTION_ID}.json"