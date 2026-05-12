#!/bin/bash
set -e

THRIFT_PORT=${THRIFT_PORT:-10000}
SPARK_HOME=${SPARK_HOME:-/opt/spark}

echo "=== Starting Spark SQL Thrift Server (HiveServer2) on port ${THRIFT_PORT} ==="

# Configure Derby metastore to /tmp (writable by spark user)
export SPARK_LOCAL_DIRS=/tmp/spark-local
export DERBY_HOME=/tmp/derby
mkdir -p /tmp/spark-local /tmp/derby /tmp/hive /tmp/spark-events

# Start the Thrift Server via spark-submit — redirect its output to this process's stdout/stderr
"${SPARK_HOME}/bin/spark-submit" \
  --class org.apache.spark.sql.hive.thriftserver.HiveThriftServer2 \
  --master "local[2]" \
  --driver-memory 1g \
  --hiveconf hive.server2.thrift.port=${THRIFT_PORT} \
  --hiveconf hive.server2.thrift.bind.host=0.0.0.0 \
  --hiveconf derby.system.home=/tmp/derby \
  --hiveconf hive.exec.scratchdir=/tmp/hive \
  --conf spark.sql.warehouse.dir=/tmp/spark-warehouse \
  --conf spark.local.dir=/tmp/spark-local \
  --conf spark.driver.extraJavaOptions="-Dderby.system.home=/tmp/derby" \
  2>&1 &

THRIFT_PID=$!
echo "Thrift Server started (PID=${THRIFT_PID}), waiting for it to be ready..."

# Wait for the Thrift Server port to open (up to 3 minutes)
MAX_WAIT=180
WAITED=0
while ! nc -z localhost ${THRIFT_PORT} 2>/dev/null; do
  sleep 3
  WAITED=$((WAITED+3))
  if [ ${WAITED} -ge ${MAX_WAIT} ]; then
    echo "ERROR: Thrift Server did not start within ${MAX_WAIT}s"
    break
  fi
  echo "  ... still waiting (${WAITED}s)"
done

if nc -z localhost ${THRIFT_PORT} 2>/dev/null; then
  echo "=== Thrift Server is up on port ${THRIFT_PORT} ==="

  # Run SparkSQL init scripts if present
  if [ -d "/opt/sparksql" ]; then
    for sql_file in /opt/sparksql/DS_SQL_PG.sql /opt/sparksql/DS_DOC_CSV.sql /opt/sparksql/DS_NoSQL_MongoDB.sql /opt/sparksql/SparkSQL_OLAP.sql; do
      if [ -f "${sql_file}" ]; then
        echo "==> Executing: ${sql_file}"
        "${SPARK_HOME}/bin/beeline" \
          -u "jdbc:hive2://localhost:${THRIFT_PORT}/default" \
          --silent=true \
          -f "${sql_file}" 2>&1 | tail -5 || echo "  (warnings/errors above — continuing)"
      fi
    done
    echo "=== SparkSQL view initialization complete ==="
  fi
fi

# Keep container alive by waiting on the Thrift Server process
wait ${THRIFT_PID}
