#!/bin/bash

# Define variables
BUCKET_NAME="ecs-results"
FILE_PATH="/opt/apache-jmeter-5.5/results.txt"
S3_KEY="results/results-a.txt"

cd bin
mkdir reports
sh jmeter -n -t /opt/apache-jmeter-5.5/test-plan-1.jmx \
  -JThreadNumber=10 \
  -JRampUpPeriod=1 \
  -Jiterations=10 \
  -l results.csv \
  -e \
  -o /opt/apache-jmeter-5.5/bin/reports/

echo "Tests finished"
#tail -f /dev/null
echo "Copying results on S3 bucket"
aws s3 cp "$FILE_PATH" "s3://$BUCKET_NAME/$S3_KEY"

if [ $? -eq 0 ]; then
  echo "File uploaded successfully to s3://$BUCKET_NAME/$S3_KEY"
else
  echo "File upload failed!"
  exit 1
fi
