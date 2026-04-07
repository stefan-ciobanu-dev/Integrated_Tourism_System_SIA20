#!/bin/bash
# Deploy TEMA L2
echo "=========================================="
echo "Deploying TEMA L2 - Federation Layer"
echo "=========================================="

cat > /tmp/deploy_l2.sql << 'SQLEOF'
SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 32767;
@/tmp/TEMA_L2_FEDERATED_ACCESS.sql
EXIT;
SQLEOF

sqlplus TOURISM_ADMIN/Tourism2025 << BASHEOF
@/tmp/deploy_l2.sql
BASHEOF

echo "=========================================="
echo "TEMA L2 Deployment Complete"
echo "=========================================="

# Deploy TEMA L3
echo "=========================================="
echo "Deploying TEMA L3 - Analytics Layer"
echo "=========================================="

cat > /tmp/deploy_l3.sql << 'SQLEOF'
SET ECHO OFF FEEDBACK OFF HEADING OFF PAGESIZE 0 LINESIZE 32767;
@/tmp/TEMA_L3_OLAP_VIEWS.sql
EXIT;
SQLEOF

sqlplus TOURISM_ADMIN/Tourism2025 << BASHEOF
@/tmp/deploy_l3.sql
BASHEOF

echo "=========================================="
echo "TEMA L3 Deployment Complete"
echo "=========================================="
