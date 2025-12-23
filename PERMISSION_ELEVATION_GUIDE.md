# Permission Elevation Configuration Guide

## Overview

This guide explains how to configure and use permission elevation (sudo/su) for benchmark testing in the Robot Framework test suite.

## Architecture

The solution provides a **centralized, 3-tier priority system** for permission elevation:

1. **Test File Parameters** (Highest Priority): Explicitly passed parameters override everything
2. **VM Config File** (Medium Priority): Default values stored in `vm_config.json`
3. **Default NONE** (Lowest Priority): Falls back to NONE if not defined anywhere

## Configuration

### 1. VM Config File (`testdata/vm_config.json`)

Add permission elevation fields to Linux-based OSes where sudo/su is applicable:

```json
{
    "CIS": {
        "Oracle": {
            "19c": {
                "compliance": {
                    "server": {
                        "ip": "10.4.19.83",
                        "username": "administrator",
                        "password": "notpassword",
                        "permission_elevation_type": "NONE",
                        "permission_elevation_user": "",
                        "permission_elevation_password": ""
                    },
                    "database": {
                        "ip": "10.4.19.83",
                        "username": "sys as sysdba",
                        "password": "notpassword",
                        "domain": "orcl"
                    }
                }
            }
        }
    }
}
```

**Permission Elevation Types:**
- `NONE`: No elevation (default)
- `SUDO`: Use sudo command
- `SUDOSU`: Use sudo to switch to another user, then su
- `SU`: Use su command

**Fields:**
- `permission_elevation_type`: The elevation method (required if using elevation)
- `permission_elevation_user`: The target user for elevation (e.g., "root")
- `permission_elevation_password`: Password for elevation (if required)

### 2. Test Files (Optional Override)

You can override vm_config values by passing parameters explicitly in your test file:

```robotframework
*** Test Cases ***
Example With Permission Elevation Override
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_ORACLE_19C
    ...    vm_cred_types=compliance,server,database
    ...    perm_elevation_type=SUDOSU
    ...    perm_elevation_user=root
    ...    perm_elevation_password=rootpass
    ...    # ... other parameters
```

## Usage Examples

### Example 1: Use VM Config Defaults (Recommended)

**vm_config.json:**
```json
"RHEL": {
    "9": {
        "compliance": {
            "server": {
                "ip": "10.4.31.88888",
                "username": "root",
                "password": "notpassword",
                "permission_elevation_type": "SUDO",
                "permission_elevation_user": "",
                "permission_elevation_password": ""
            }
        }
    }
}
```

**Test File:**
```robotframework
*** Test Cases ***
RHEL 9 Test
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_RHEL_9
    ...    vm_cred_types=compliance,server
    ...    # No permission elevation params - uses vm_config defaults (SUDO)
```

**Result:** Site will be created with `permission_elevation_type=SUDO` from vm_config

### Example 2: Override VM Config in Test File

**vm_config.json:**
```json
"Oracle": {
    "19c": {
        "compliance": {
            "server": {
                "permission_elevation_type": "NONE"
            }
        }
    }
}
```

**Test File:**
```robotframework
*** Test Cases ***
Oracle 19c Test With Elevation
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_ORACLE_19C
    ...    vm_cred_types=compliance,server,database
    ...    perm_elevation_type=SUDOSU
    ...    perm_elevation_user=root
    ...    perm_elevation_password=rootpass
```

**Result:** Site will be created with `permission_elevation_type=SUDOSU` (test file overrides vm_config)

### Example 3: No Elevation (Default)

**vm_config.json:**
```json
"Windows": {
    "Windows-Server-2022": {
        "compliance": {
            "server": {
                "ip": "10.4.22.231",
                "username": "Administrator",
                "password": "N0tpassword!"
                // No permission_elevation_type defined
            }
        }
    }
}
```

**Test File:**
```robotframework
*** Test Cases ***
Windows Server 2022 Test
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_Windows_Server_2022
    ...    vm_cred_types=compliance,server
    ...    # No permission elevation params
```

**Result:** Site will be created with `permission_elevation_type=NONE` (default for Windows)

## When to Use Permission Elevation

### Use Permission Elevation For:
- **Linux systems** requiring root access
- **Apache Tomcat** deployments
- **Oracle Database** on Linux
- **PostgreSQL, MongoDB** on Linux
- Systems where the login user needs elevated privileges

### Do NOT Use Permission Elevation For:
- **Windows systems** (use native Administrator account)
- **Network devices** (Cisco, Palo Alto, etc.)
- **Database credentials** (they have their own authentication)
- Systems where the login user already has full privileges

## API Payload Structure

### Without Permission Elevation (NONE)
```json
{
  "site_credentials": [
    {
      "id": -1,
      "name": "SSH Credential",
      "service": "ssh",
      "user_name": "administrator",
      "password": "notpassword",
      "permission_elevation_type": "NONE",
      "enabled": true,
      "scope": "S"
    }
  ]
}
```

### With Permission Elevation (SUDO)
```json
{
  "site_credentials": [
    {
      "id": -1,
      "name": "SSH Credential",
      "service": "ssh",
      "user_name": "root",
      "password": "notpassword",
      "permission_elevation_type": "SUDO",
      "enabled": true,
      "scope": "S"
    }
  ]
}
```

### With Permission Elevation (SUDOSU)
```json
{
  "site_credentials": [
    {
      "id": -1,
      "name": "SSH Credential",
      "service": "ssh",
      "user_name": "user",
      "password": "notpassword",
      "permission_elevation_type": "SUDOSU",
      "permission_elevation_user": "root",
      "permission_elevation_password": "rootpassword",
      "enabled": true,
      "scope": "S"
    }
  ]
}
```

## Implementation Details

### Automatic Handling in `site.robot`

The `Create Site With VM Config` and `Update Site With VM Config` keywords automatically:

1. **Read** permission elevation from vm_config (if present)
2. **Check** if test file passed override parameters
3. **Apply** the correct values with priority: Test File > VM Config > NONE
4. **Log** which source was used for transparency

```robotframework
# Priority logic in site.robot
IF    '${perm_elevation_type}' != '${EMPTY}'
    # Use test file parameters
ELSE IF    '${vm_perm_type}' != 'NONE'
    # Use vm_config values
ELSE
    # Default to NONE
END
```

## Benefits

✅ **Centralized Configuration**: All permission settings in one place  
✅ **Flexible Override**: Test files can override when needed  
✅ **OS-Specific**: Only applies to OSes where it makes sense  
✅ **Backward Compatible**: Existing tests work without changes  
✅ **Clear Logging**: Shows which source was used  
✅ **Safe Defaults**: Falls back to NONE if not specified  

## Troubleshooting

### Issue: Permission Elevation Not Applied
**Check:**
1. Is `permission_elevation_type` defined in vm_config for that OS?
2. Is it spelled correctly? (case-sensitive: `NONE`, `SUDO`, `SUDOSU`, `SU`)
3. Check console logs for "Added permission elevation from..." messages

### Issue: Wrong Permission Elevation Used
**Check:**
1. Priority order: Test file > VM config > Default NONE
2. If test file passes `perm_elevation_type`, it always wins
3. Check console logs to see which source was used

### Issue: Database Credentials Have Permission Elevation
**Solution:** Database credentials should NOT have permission elevation (except for the default `NONE`). Only server credentials should have elevation.

## Examples from Your Environment

### Oracle 19c (Currently Configured)
```json
"Oracle": {
    "19c": {
        "compliance": {
            "server": {
                "permission_elevation_type": "NONE",
                "permission_elevation_user": "",
                "permission_elevation_password": ""
            }
        }
    }
}
```

### RHEL 9 (Configured with SUDO)
```json
"RHEL": {
    "9": {
        "compliance": {
            "server": {
                "permission_elevation_type": "SUDO",
                "permission_elevation_user": "",
                "permission_elevation_password": ""
            }
        }
    }
}
```

### Ubuntu 20.04 (Configured with SUDO)
```json
"Ubuntu": {
    "Ubuntu-20-04": {
        "compliance": {
            "server": {
                "permission_elevation_type": "SUDO",
                "permission_elevation_user": "",
                "permission_elevation_password": ""
            }
        }
    }
}
```

## Next Steps

1. **Review** your vm_config.json and add permission elevation to OSes that need it
2. **Test** with Oracle 19c benchmark: `robot tests/CIS/Oracle/oracle19cbenchmark.robot`
3. **Monitor** console logs to verify correct elevation is applied
4. **Update** other OS configurations as needed

---

**Created:** December 2025  
**Last Updated:** December 2025
