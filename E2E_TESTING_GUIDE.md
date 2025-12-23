# E2E Benchmark Testing Framework

## Overview

This framework provides a **parameterized, reusable approach** to benchmark compliance testing (CIS, DISA, etc.) for Nexpose/InsightVM. Instead of copying and modifying test code, you simply pass parameters to a single keyword that handles the entire workflow.

## What's Included

### 1. Resource File: `resources/e2e_benchmark_testing.robot`

Contains all reusable keywords for:
- Login and authentication
- Engine selection
- Template processing and creation
- Site creation/update
- Scan execution and monitoring
- Report generation
- CSV validation

### 2. Test File: `tests/e2e_benchmark_testing.robot`

Contains:
- **Pre-configured test cases** for common scenarios (RHEL 9, Ubuntu 20.04)
- **Customizable template** for any benchmark/OS combination

## Quick Start

### Run Pre-configured Tests

```bash
# Run RHEL 9 CIS Level 1 Server test
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E RHEL 9 Level 1 Server CIS Benchmark"

# Run Ubuntu 20.04 CIS Level 1 Server test
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E Ubuntu 20.04 Level 1 Server CIS Benchmark"

# Run all E2E tests
robot --outputdir results tests/e2e_benchmark_testing.robot
```

## Create Your Own Test

### Option 1: Modify the Custom Template

Edit `tests/e2e_benchmark_testing.robot` and customize the "E2E Custom Benchmark Test Template" test case:

```robotframework
# Customize these parameters
${benchmark}=    Set Variable    CIS
${os_name}=    Set Variable    Red Hat Enterprise Linux 9
${version}=    Set Variable    2.0.0
${profile}=    Set Variable    Level 1 - Server
${scan_template}=    Set Variable    cis
${service}=    Set Variable    ssh
${scope}=    Set Variable    S
${csv_file}=    Set Variable    ${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
```

### Option 2: Create New Test File

Create a new test file (e.g., `tests/my_custom_e2e.robot`):

```robotframework
*** Settings ***
Resource          ../resources/e2e_benchmark_testing.robot

*** Test Cases ***
My Custom E2E Test
    ${timestamp}=    Evaluate    int(__import__('time').time())
    
    ${results}=    Run Complete E2E Benchmark Test
    ...    benchmark=CIS
    ...    os_name=Ubuntu
    ...    version=22.04
    ...    profile=Level 1 - Server
    ...    scan_template=cis
    ...    service=ssh
    ...    scope=S
    ...    site_name=My_Custom_Site_${timestamp}
    ...    template_name=My_Custom_Template_${timestamp}
    ...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/Ubuntu22/level1_server.csv
    ...    policy_list=all
    ...    db_required=${FALSE}
    ...    validate_compliance=${TRUE}
    ...    expected_vuln_count=0
    
    # Results are returned in a dictionary
    Should Be Equal As Integers    ${results}[validation_failed]    0
```

## Parameters Reference

### Required Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `benchmark` | Benchmark framework name | `CIS`, `DISA` |
| `os_name` | Operating system name | `Red Hat Enterprise Linux 9`, `Ubuntu` |
| `version` | OS/Benchmark version | `2.0.0`, `20.04` |
| `profile` | Compliance profile | `Level 1 - Server`, `Level 2 - Server` |
| `scan_template` | Template type | `cis`, `disa` |
| `service` | Credential service type | `ssh`, `cifs`, `oracle`, `mysql` |
| `scope` | Scope identifier | `S` (STIG) |
| `site_name` | Name for the site | `RHEL9_CIS_Site_123456` |
| `template_name` | Name for scan template | `RHEL9_CIS_Template_123456` |
| `csv_file` | Path to validation CSV | `${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv` |

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `policy_list` | `all` | Policies to include |
| `db_required` | `${FALSE}` | Whether database credentials needed |
| `engine_id` | Auto-select | Specific engine ID to use |
| `site_id` | Create new | Existing site ID to update |
| `validate_compliance` | `${TRUE}` | Enable compliance validation |
| `expected_vuln_count` | `0` | Expected vulnerability count |

## Complete Workflow

When you call `Run Complete E2E Benchmark Test`, it executes:

1. **Login** → Authenticates to Nexpose/InsightVM
2. **Engine Selection** → Selects scan engine (auto or specified)
3. **Template Processing** → Creates scan template with policies
4. **Site Creation** → Creates/updates site with VM configuration
5. **Scan Start** → Initiates compliance scan
6. **Scan Monitoring** → Monitors until completion
7. **Scan Validation** → Validates vulnerability count
8. **Policy Natural ID** → Retrieves policy surrogate identifier
9. **Report Generation** → Generates XCCDF report
10. **Report Validation** → Validates report against CSV rules

## Return Values

The keyword returns a dictionary with:

```python
{
    'session_id': '...',
    'engine_id': 3,
    'template_id': '...',
    'site_id': 123,
    'scan_id': 456,
    'scan_status': 'finished',
    'scan_elapsed_time': 1234,
    'policy_count': 235,
    'validation_passed': 235,
    'validation_failed': 0,
    'formatted_policies': [...],
    'policy_natural_ids': {...},
    'report_ids': {...},
    'scan_details': {...}
}
```

## CSV Validation Rules

Create CSV files with validation rules in this format:

```csv
NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs...,COMPLIANT,Ensure cramfs kernel module is not available
2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs...,NOT COMPLIANT,Ensure freevxfs kernel module is not available
3,xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs...,INFORMATIONAL,Ensure hfs kernel module is not available
```

Valid expected results:
- `COMPLIANT` → XCCDF `pass`
- `NOT COMPLIANT` → XCCDF `fail`
- `INFORMATIONAL` → XCCDF `informational`
- `NOT APPLICABLE` → XCCDF `notapplicable`
- `NOT CHECKED` → XCCDF `notchecked`
- `UNKNOWN` → XCCDF `unknown`

## Directory Structure

```
poc_robot_framework/
├── resources/
│   ├── e2e_benchmark_testing.robot    # Main E2E resource file
│   ├── login.robot                     # Login keywords
│   ├── engines.robot                   # Engine keywords
│   ├── site.robot                      # Site management
│   ├── scan_template_api.robot         # Template keywords
│   ├── scan_operations.robot           # Scan keywords
│   └── report_operations.robot         # Report keywords
├── tests/
│   ├── e2e_benchmark_testing.robot    # E2E test file
│   └── ... (other test files)
└── testdata/
    └── validation_rules/
        ├── CIS/
        │   ├── RHEL9/
        │   │   ├── level1_server.csv
        │   │   └── level2_server.csv
        │   └── Ubuntu20/
        │       └── level1_server.csv
        └── DISA/
            └── RHEL9/
                └── stig_baseline.csv
```

## Benefits

✅ **No Code Duplication** → Reuse the same keywords for all tests  
✅ **Parameterized** → Customize via parameters, not code changes  
✅ **Maintainable** → Update logic in one place  
✅ **Consistent** → Same workflow for all benchmarks  
✅ **Flexible** → Support any OS/benchmark combination  
✅ **Validated** → Automatic CSV-based validation  
✅ **Complete** → Handles entire workflow end-to-end

## Examples

### Example 1: RHEL 9 with Database Credentials

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Red Hat Enterprise Linux 9
...    version=2.0.0
...    profile=Level 1 - Server
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=RHEL9_DB_Site_${timestamp}
...    template_name=RHEL9_DB_Template_${timestamp}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
...    db_required=${TRUE}    # Enable database credentials
```

### Example 2: Update Existing Site

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Ubuntu
...    version=20.04
...    profile=Level 1 - Server
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=Updated_Site_Name
...    template_name=Updated_Template
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/Ubuntu20/level1_server.csv
...    site_id=61    # Update existing site
```

### Example 3: Custom Vulnerability Threshold

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=DISA
...    os_name=Red Hat Enterprise Linux 9
...    version=1.0.0
...    profile=STIG Baseline
...    scan_template=disa
...    service=ssh
...    scope=S
...    site_name=DISA_Site_${timestamp}
...    template_name=DISA_Template_${timestamp}
...    csv_file=${EXECDIR}/testdata/validation_rules/DISA/RHEL9/stig_baseline.csv
...    expected_vuln_count=10    # Allow up to 10 vulnerabilities
```

## Troubleshooting

### Issue: Test fails at site creation
- **Check**: VM config exists for your OS/version combination
- **Check**: Credentials are correct in `testdata/vm_config.json`

### Issue: Test fails at validation
- **Check**: CSV file path is correct
- **Check**: CSV expected results match actual system compliance
- **Check**: CSV format is correct (NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION)

### Issue: Scan timeout
- **Solution**: Increase timeout parameter (default: 7200s = 2 hours)
- Add to keyword call: `timeout=10800` (3 hours)

### Issue: Report generation fails
- **Check**: Site scan completed successfully
- **Check**: Policy natural ID is valid
- **Wait**: Report may take time to generate (up to 2 minutes)

## Migration from Old Tests

If you have existing tests like `ubuntubenchmark3.0.0.robot`, migrate them:

**Before:**
```robotframework
# 200+ lines of code with hardcoded values
```

**After:**
```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Ubuntu
...    version=20.04
...    profile=Level 1 - Server
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=Ubuntu_Site_${timestamp}
...    template_name=Ubuntu_Template_${timestamp}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/Ubuntu20/level1_server.csv
# Done! ~10 lines instead of 200+
```

## Support

For questions or issues with the E2E framework, check:
1. This README
2. Inline documentation in `resources/e2e_benchmark_testing.robot`
3. Example tests in `tests/e2e_benchmark_testing.robot`
