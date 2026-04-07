# Quick Start: Oracle Container Registry Authentication → Docker Deploy

## 📋 Complete Step-by-Step Process

### Phase 1: Generate Auth Token (5 minutes)

#### ① Visit Oracle Container Registry
```
https://container-registry.oracle.com
```

#### ② Sign In or Create Account
- Use your Oracle account (create free one if needed)

#### ③ Generate Auth Token
1. Click your **profile name** (top right corner)
2. Select **Auth Tokens** or **My Account**
3. Look for button: **Generate Secret Key** or **Generate Token**
4. Click to generate
5. **COPY the token immediately** - shown only once!

**Token format example**:
```
abc123def456ghi789jkl012mnopqr...
```

✅ Save this somewhere temporarily (clipboard is fine)

---

### Phase 2: Authenticate Docker (2 minutes)

#### ④ Open PowerShell Terminal

In VS Code or Windows PowerShell:

```powershell
# Navigate to project directory
cd d:\Repositories\integration

# Run authentication script (EASIEST):
.\Login-OracleRegistry.ps1
```

**Script will prompt**:
- **Username**: Your Oracle SSO email/username  
- **Password**: Paste the Auth Token you generated in Phase 1

**OR manually login**:
```powershell
docker login container-registry.oracle.com
# Username: your.email@oracle.com
# Password: [Paste Auth Token]
```

✅ **Success**: Should say `Login Succeeded`

---

### Phase 3: Pull and Run Database (5 minutes)

#### ⑤ Verify Authentication Works

```powershell
# Test image pull
docker pull container-registry.oracle.com/database/free:latest
```

Should complete without "denied/access" errors.

#### ⑥ Start Docker Compose

```powershell
# Start the database container
docker-compose -f docker-compose-db-only.yml -p tourism-platform up -d

# Check status
docker ps
```

**Expect output**:
```
CONTAINER ID  IMAGE                                        STATUS
abcd1234...   container-registry.oracle.com/database/free  Up X seconds (health: starting)
```

#### ⑦ Wait for Database to Initialize

```powershell
# Option A: Watch health check
docker ps --format "table {{.Names}}\t{{.Status}}"

# Option B: Watch logs
docker logs -f tourism-oracle-db
```

⏳ **Wait 2-3 minutes** until status shows `(healthy)`

---

## 🎯 After Database is Ready

Once health check passes:

### Step 1: Create TOURISM_ADMIN User
```powershell
sqlplus system/TourismDB2025!@localhost:1521/FREE @database/init_db.sql
```

### Step 2: Deploy Federation Layer (TEMA L2)
```powershell
sqlplus TOURISM_ADMIN/Tourism2025!@localhost:1521/FREE @database/TEMA_L2_FEDERATED_ACCESS.sql
```

### Step 3: Deploy Analytics Layer (TEMA L3)
```powershell
sqlplus TOURISM_ADMIN/Tourism2025!@localhost:1521/FREE @database/TEMA_L3_OLAP_VIEWS.sql
```

### Step 4: Verify Installation
```powershell
sqlplus TOURISM_ADMIN/Tourism2025!@localhost:1521/FREE @database/TEMA_L3_VERIFY.sql
```

---

## 📍 Quick Reference: Connection Strings

**Database Free Edition**:
- Host: `localhost`
- Port: `1521`
- SID/Database: `FREE` or `FREEPDB1`
- System Password: `TourismDB2025!`
- App User: `TOURISM_ADMIN`
- App Password: `Tourism2025!`

**SQL*Plus Examples**:
```powershell
# System user
sqlplus system/TourismDB2025!@localhost:1521/FREE

# Application user
sqlplus TOURISM_ADMIN/Tourism2025!@localhost:1521/FREE

# Or with connection string
sqlplus TOURISM_ADMIN/Tourism2025!@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SID=FREE)))"
```

---

## ❌ Troubleshooting

### "denied: requested access is denied"

**Cause**: Not authenticated or authentication failed  
**Solution**:
```powershell
# Try again:
.\Login-OracleRegistry.ps1

# OR manually:
docker logout container-registry.oracle.com
docker login container-registry.oracle.com
```

### "Cannot find specified image"

**Cause**: Image path wrong or authentication failed  
**Verify**:
```powershell
# Check exact path:
docker image ls | findstr oracle

# Should show:
# container-registry.oracle.com/database/free   latest   [IMAGE_ID]
```

### "no suitable servers found"

**Cause**: Docker daemon not running  
**Solution**: Start Docker Desktop

### "Health check failing after startup"

This is normal for first 2 minutes. Database is initializing.  
**Wait longer**:
```powershell
docker logs tourism-oracle-db | tail -20
```

Look for: `Database opened` or similar success message

### "Out of memory / No space left"

**Cause**: Insufficient disk space  
**Need**: ~20GB free disk space  
**Solution**: Free up disk space, restart container

---

## 📚 Files Created

- `ORACLE_CONTAINER_REGISTRY_SETUP.md` - Detailed setup guide
- `Login-OracleRegistry.ps1` - Interactive authentication script  
- `docker-compose-db-only.yml` - Updated with correct image path

---

## ✅ Checklist

- [ ] Generated Auth Token from https://container-registry.oracle.com
- [ ] Ran `Login-OracleRegistry.ps1` and got "Login Succeeded"
- [ ] Successfully pulled image: `docker pull container-registry.oracle.com/database/free:latest`
- [ ] Docker Compose started: `docker-compose -f docker-compose-db-only.yml -p tourism-platform up -d`
- [ ] Database health check shows `(healthy)` after 2-3 minutes
- [ ] Can connect: `sqlplus system/TourismDB2025!@localhost:1521/FREE`
- [ ] Ready to deploy SQL scripts!

---

## 🚀 You're All Set!

Once the database is ready and accessible, proceed with SQL deployments to complete TEMA L2 and L3.
