TABLE_NAME="test_table"

# create table and enable dynamodb stream
awslocal dynamodb create-table --table-name $TABLE_NAME \
                               --attribute-definitions \
                                 AttributeName=id,AttributeType=S \
                               --key-schema \
                                 AttributeName=id,KeyType=HASH \
                               --provisioned-throughput \
                                 ReadCapacityUnits=1,WriteCapacityUnits=1 \
                               --stream-specification \
                                 StreamEnabled=true,StreamViewType='NEW_IMAGE'

# get stream arn
STREAM_ARN=`awslocal dynamodbstreams list-streams --table-name=$TABLE_NAME | jq -r '.Streams[].StreamArn'`

# create lamba function
zip -j sample_lambda.zip /docker-entrypoint-initaws.d/lambda/example.py

awslocal lambda create-function --function-name sample_lambda \
                                --role arn:aws:iam::1234567:role/anything \
                                --zip-file fileb://sample_lambda.zip \
                                --runtime python3.6 \
                                --handler example.lambda_handler

awslocal lambda create-event-source-mapping --function-name sample_lambda \
                                            --event-source $STREAM_ARN \
                                            --batch-size 10 \
                                            --starting-position TRIM_HORIZON
