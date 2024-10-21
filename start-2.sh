#!/bin/bash
cd bin
mkdir reports
sh jmeter -n -t /opt/apache-jmeter-5.5/test-plan.jmx \
  -JThreadNumber=10 \
  -JRampUpPeriod=1 \
  -Jiterations=10 \
  -l results.csv \
  -e \
  -o /opt/apache-jmeter-5.5/bin/reports/

#tail -f /dev/null
