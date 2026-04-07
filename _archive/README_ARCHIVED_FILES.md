# Archived Files - Legacy Implementation

This folder contains older/alternative implementations and configuration files that are no longer used in the active deployment.

## Why Archived?

The project went through several iterations:
1. **Initial approach**: Docker ORDS + Oracle APEX (not available in Free Edition)
2. **Alternative approaches**: Multiple server implementations
3. **Final approach**: Node.js Express + HTML Dashboard (current, in use)

## What's Archived

### old_servers/
- `server.js` - Earlier Node.js implementation (superseded by `server-simple.js`)
- `server-api.js` - Alternative server with different architecture

**Current server**: `server-simple.js` (in root)

### old_deployment_scripts/
- `DEPLOY.bat`, `DEPLOY.ps1`, `deploy.sh` - Old deployment automation
- `Install-OracleSecure.ps1`, `Login-OracleRegistry.ps1`, `VERIFY_ORACLE.ps1` - Registry/auth scripts
- User setup scripts (create_user*.sql, setup_user.sql, etc.)
- Verification/reference scripts (quick_verify.sql, populate_data.sql, etc.)

**Current deployment**: Docker Compose (`docker-compose.yml`)

### old_docker_configs/
- `docker-compose-db-only.yml` - Database only configuration
- `docker-compose-simple.yml` - Simplified setup
- `docker-compose-test.yml` - Test configuration
- `oracle_install.rsp` - Oracle Silent Install response file

**Current Docker config**: `docker-compose.yml` (in root)

### old_database_scripts/
- `TEMA_L2_COMPLETE.sql`, `TEMA_L2_FINAL.sql`, `TEMA_L2_FIX_VIEWS.sql` - Older federation implementations
- `TEMA_L2_VERIFY_DATA.sql`, `TEMA_L3_VERIFY.sql` - Verification scripts
- `TEMA_P3_ORDS_REST_SERVICES.sql` - ORDS REST (not available in Free Edition)
- `TEMA_P3_APEX_APPLICATION.sql` - APEX application (not available in Free Edition)
- `TEMA_L2_ORDS_REST_SERVICES.sql` - ORDS services (not available)
- `DEPLOY_TOURISM_SCHEMA.sql`, `init_db.sql`, `TEMA_SIMPLIFIED_DEPLOYMENT.sql` - Old setup scripts

**Current database scripts in use**:
- `database/TEMA_L2_COMPLETE_FINAL.sql` - Federation layer
- `database/TEMA_L3_OLAP_VIEWS.sql` - OLAP analytics

### old_documentation/
- Progress/completion reports from various phases
- Troubleshooting and setup guides from earlier iterations
- Deprecated project structure documentation

**Current documentation**:
- `README.md` - Main project overview
- `REPOSITORY_STRUCTURE.md` - Directory organization
- Under `1_Data_Sources/`, `2_Data_Models/`, `3_Integration_Model/`, `4_Web_Model/` - TEMA layer guides

## Restoration

If you need any archived file, files are safely preserved here. Just copy back to the appropriate location.

Example:
```bash
# To use an old server implementation:
cp _archive/old_servers/server.js ./

# To revert docker-compose config:
cp _archive/old_docker_configs/docker-compose-simple.yml ./docker-compose.yml
```

## Current Active Project Files

```
d:\Repositories\integration\
├── 1_Data_Sources/              ✓ TEMA L1
├── 2_Data_Models/               ✓ TEMA Schemas
├── 3_Integration_Model/         ✓ TEMA L2 & L3
├── 4_Web_Model/                 ✓ TEMA P3
│   ├── P3_REST_Web_Model_Guide.md
│   ├── server-simple.js         (⭐ ACTIVE)
│   └── dashboard-working.html
├── database/
│   ├── TEMA_L2_COMPLETE_FINAL.sql   (⭐ ACTIVE)
│   ├── TEMA_L2_FEDERATED_ACCESS.sql (reference)
│   └── TEMA_L3_OLAP_VIEWS.sql       (⭐ ACTIVE)
├── README.md                    (⭐ MAIN)
├── REPOSITORY_STRUCTURE.md
├── package.json
├── docker-compose.yml           (⭐ ACTIVE)
└── .gitignore
```

## Space Saved

By archiving (not deleting), you've:
- ✅ Cleaned up root directory (removed ~40 files)
- ✅ Kept legacy files for reference/rollback
- ✅ Made repository easier to navigate
- ✅ Organized project structure professionally

---

**Archive Date**: April 7, 2026  
**Status**: All active files remain in root and organized directories
