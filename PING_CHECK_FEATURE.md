# Ping Check Feature for Site Creation

## Overview

The site creation workflow now includes an **automatic host reachability check** using ping before creating a site. This prevents wasting time creating sites and waiting for scans on unreachable hosts.

## How It Works

### Automatic Ping Check
When you call `Create Site With VM Config`, it will:
1. Extract the IP address from the VM config
2. Ping the host with a **10-minute timeout** (default)
3. Retry every 5 seconds until the host responds or timeout is reached
4. If the host is reachable, proceed with site creation
5. If the host is NOT reachable after 10 minutes, **fail the test** with a clear error message

### Benefits
- ✅ **Saves time**: No more waiting for scans on unreachable hosts
- ✅ **Early failure detection**: Know immediately if a host is down
- ✅ **Configurable timeout**: Adjust the wait time based on your needs
- ✅ **Detailed logging**: See exactly when the host becomes reachable

## Usage

### Default Behavior (10-minute timeout)
```robot
# Automatically checks if 10.4.31.8 is reachable before creating site
${site_id}=    Create Site With VM Config
...    My RHEL9 Site
...    CIS_RHEL_9
...    server
...    scan_template=cis-red-hat-enterprise-linux-9-benchmark-v2-0-0-level-1-server
...    scope=S
...    engine_id=3
...    service=ssh
```

### Custom Timeout (e.g., 5 minutes)
```robot
# Wait up to 5 minutes (300 seconds) for host to be reachable
${site_id}=    Create Site With VM Config
...    My RHEL9 Site
...    CIS_RHEL_9
...    server
...    scan_template=cis-red-hat-enterprise-linux-9-benchmark-v2-0-0-level-1-server
...    scope=S
...    engine_id=3
...    service=ssh
...    ping_timeout=300
```

### Skip Ping Check (Not Recommended)
```robot
# Skip the ping check entirely (use only if you're sure the host is up)
${site_id}=    Create Site With VM Config
...    My RHEL9 Site
...    CIS_RHEL_9
...    server
...    scan_template=cis-red-hat-enterprise-linux-9-benchmark-v2-0-0-level-1-server
...    scope=S
...    engine_id=3
...    service=ssh
...    skip_ping_check=${True}
```

## Configuration Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ping_timeout` | integer | 600 | Maximum time in seconds to wait for host (600s = 10 minutes) |
| `skip_ping_check` | boolean | False | Set to True to bypass ping check (not recommended) |

## Examples

### Example 1: Wait 15 minutes for host to come online
```robot
${site_id}=    Create Site With VM Config
...    Oracle 19c Site
...    CIS_Oracle_19c
...    server
...    database
...    scan_template=cis-oracle-database-19c-benchmark-v2-0-0-level-1-rdbms-for-windows
...    scope=S
...    engine_id=3
...    service=cifs
...    db_service=oracle
...    db_sid=orcl
...    db_domain=ORACLE.LOCAL
...    ping_timeout=900
```

### Example 2: Quick check with 2-minute timeout
```robot
${site_id}=    Create Site With VM Config
...    Ubuntu 20.04 Site
...    CIS_Ubuntu_Ubuntu-20-04
...    server
...    scan_template=cis-ubuntu-linux-20.04-lts-benchmark-v2-0-1-level-1-server
...    scope=S
...    engine_id=3
...    service=ssh
...    ping_timeout=120
```

## Console Output

### When Host is Reachable
```
========================================
CHECKING HOST REACHABILITY
IP Address: 10.4.31.8
Timeout: 600 seconds (10.0 minutes)
========================================
✓ Host 10.4.31.8 is REACHABLE (responded in 0 seconds, attempt 1)
Host 10.4.31.8 is reachable, proceeding with site creation
```

### When Host Takes Time to Respond
```
========================================
CHECKING HOST REACHABILITY
IP Address: 10.4.31.8
Timeout: 600 seconds (10.0 minutes)
========================================
Attempt 1: Host 10.4.31.8 not reachable (elapsed: 0s)
Attempt 2: Host 10.4.31.8 not reachable (elapsed: 5s)
Attempt 3: Host 10.4.31.8 not reachable (elapsed: 10s)
✓ Host 10.4.31.8 is REACHABLE (responded in 15 seconds, attempt 4)
Host 10.4.31.8 is reachable, proceeding with site creation
```

### When Host is NOT Reachable
```
========================================
CHECKING HOST REACHABILITY
IP Address: 10.4.31.8
Timeout: 600 seconds (10.0 minutes)
========================================
Attempt 1: Host 10.4.31.8 not reachable (elapsed: 0s)
Attempt 2: Host 10.4.31.8 not reachable (elapsed: 5s)
...
Attempt 120: Host 10.4.31.8 not reachable (elapsed: 595s)
❌ Host 10.4.31.8 not reachable after 600 seconds (10.0 minutes)

Test FAILED:
Host 10.4.31.8 is not reachable after 600 seconds. Cannot create site for unreachable host.
```

## Testing the Feature

Run the ping check tests:

```bash
# Test with a reachable host
robot -t "Test Ping Check For Reachable Host" tests/test_ping_check.robot

# Test with an unreachable host
robot -t "Test Ping Check For Unreachable Host" tests/test_ping_check.robot

# Run all ping tests
robot tests/test_ping_check.robot
```

## Technical Details

### Keyword: Check Host Reachability
```robot
Check Host Reachability
    [Arguments]    ${ip}    ${timeout}=600    ${interval}=5
```

**Parameters:**
- `ip`: IP address to ping
- `timeout`: Maximum time to wait in seconds (default: 600 = 10 minutes)
- `interval`: Time between ping attempts in seconds (default: 5)

**Returns:** Boolean - `True` if reachable, `False` if timeout reached

**Implementation:**
- Uses system `ping` command with single packet (`-c 1`)
- Wait timeout per ping is 5 seconds (`-W 5`)
- Retries every 5 seconds until host responds or timeout reached
- Provides detailed console logging for each attempt

## Migration Guide

### Existing Tests
All existing tests will automatically include the ping check with no code changes needed.

### If You Need to Disable It
Only disable the ping check if:
- You're running tests in a controlled environment where all hosts are guaranteed to be up
- You're testing error handling for unreachable hosts
- You need to speed up test development (not recommended for production)

```robot
# Add skip_ping_check=${True} to any Create Site With VM Config call
${site_id}=    Create Site With VM Config
...    [all your existing parameters]
...    skip_ping_check=${True}
```

## Troubleshooting

### Test fails immediately with "Host not reachable"
- **Cause**: The host is actually down or unreachable
- **Solution**: 
  1. Verify the VM is running
  2. Check network connectivity
  3. Verify the IP address in `testdata/vm_config.json` is correct
  4. Try pinging manually: `ping <ip_address>`

### Test takes too long
- **Cause**: Default 10-minute timeout is too long for your use case
- **Solution**: Use a shorter `ping_timeout` value (e.g., 120 for 2 minutes)

### Test succeeds but scan fails
- **Cause**: Ping check only verifies network reachability, not SSH/service availability
- **Solution**: This is expected - ping checks if the host is online, but credentials/services might still fail

## Related Files

- `resources/site.robot` - Contains `Check Host Reachability` and updated `Create Site With VM Config`
- `tests/test_ping_check.robot` - Ping check test cases
- `testdata/vm_config.json` - VM configuration with IP addresses

## See Also

- [E2E Testing Guide](E2E_TESTING_GUIDE.md)
- [Quick Reference](QUICK_REFERENCE.md)
- [Site Creation Documentation](E2E_ARCHITECTURE.md#site-management)
