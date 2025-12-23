# Robot Framework E2E Benchmark Testing - Complete Execution Flow

## Table of Contents
1. [Overview](#overview)
2. [Test Execution Entry Point](#test-execution-entry-point)
3. [Execution Flow Diagram](#execution-flow-diagram)
4. [Detailed Step-by-Step Execution](#detailed-step-by-step-execution)
5. [Session Management & Authentication](#session-management--authentication)
6. [VM Credentials Configuration](#vm-credentials-configuration)
7. [Library Architecture](#library-architecture)
8. [Timing and Waits](#timing-and-waits)
9. [File Structure and Dependencies](#file-structure-and-dependencies)

---

## Overview

When you run a Robot Framework test file (e.g., `robot tests/CIS/Linux/RHEL/RHEL9benchmarks.robot`), it executes an end-to-end compliance benchmark test that:
- Authenticates to Nexpose/InsightVM
- Creates scan templates and sites
- Executes compliance scans
- Generates and validates XCCDF reports
- Cleans up resources automatically

---

## Test Execution Entry Point

### Command:
```bash
robot tests/CIS/Linux/RHEL/RHEL9benchmarks.robot
```

### Test File Structure:
```robotframework
*** Settings ***
Resource    ../../../../resources/e2e_benchmark_testing.robot

*** Test Cases ***
RHEL 9 - CIS Benchmark Level 1 Server Compliance Test
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_RHEL_9
    ...    vm_cred_types=compliance,server
    ...    os_benchmark_identifier=Red_Hat_Enterprise_Linux_9_BENCHMARK
    ...    version=2.0.0
    ...    scan_template=cis
    ...    server_service=ssh
    ...    scope=S
    ...    site_name=${site_name}
    ...    template_name=${template_name}
    ...    policy_list=all
    ...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
    
    [Teardown]    Cleanup Test Resources    ${results}[site_id]    ${results}[template_id]
```

**Entry Keyword:** `Run Complete E2E Benchmark Test` in `resources/e2e_benchmark_testing.robot`

---

## Execution Flow Diagram

```
Test Start
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  1. Run Complete E2E Benchmark Test (Router)                   │
│     Location: resources/e2e_benchmark_testing.robot:213         │
│     - Detects signature type (old vs new)                       │
│     - Routes to adapter or internal implementation              │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. Run Complete E2E Benchmark Test With OS Identifier (Adapter)│
│     Location: resources/e2e_benchmark_testing.robot:234         │
│     - Parses: CIS_RHEL_9 → benchmark=CIS, vm_os=RHEL, version=9│
│     - Converts old signature to new signature                   │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. Run Complete E2E Benchmark Test Internal                    │
│     Location: resources/e2e_benchmark_testing.robot:302         │
│     - Orchestrates all 11 steps                                 │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 0: Get Policies From JSON                                 │
│  File: resources/policy_operations.robot                        │
│  - Loads: data/policies/cis_policies.json                       │
│  - Extracts policies for OS + version                           │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Execute Login Step                                     │
│  File: resources/login.robot                                    │
│  Function: Login To Console                                     │
│  - POST /api/1.1/xml with credentials                           │
│  - Extracts session-id from XML response                        │
│  - Stores in global variable: ${SESSION_ID}                     │
│  Duration: ~1-2 seconds                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: Execute Engine Selection Step                          │
│  File: resources/engine_operations.robot                        │
│  Function: Get Available Engines                                │
│  - GET /api/3/scan_engines                                      │
│  - Selects first available engine or uses provided engine_id    │
│  Duration: ~1 second                                             │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: Execute Template Processing Step                       │
│  File: resources/scan_template_api.robot                        │
│  Function: Process Template For OS                              │
│  - Loads scan template JSON                                     │
│  - Filters policies based on policy_list                        │
│  - Creates scan template via POST /api/3/scan_templates         │
│  - Returns: template_id, formatted_policies, policy_count       │
│  Duration: ~2-3 seconds                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: Execute Site Creation Step                             │
│  File: resources/site.robot                                     │
│  Function: Create Or Update Site With Credentials               │
│  - Fetches VM credentials from testdata/vm_config.json          │
│  - Credential path: CIS → RHEL → 9 → compliance → server        │
│  - Creates site with credentials via POST /api/1.1/xml          │
│  - Returns: site_id                                             │
│  Duration: ~2-3 seconds                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 5: Execute Scan Start Step                                │
│  File: resources/scan_operations.robot                          │
│  Function: Start Scan                                           │
│  - POST /api/3/sites/{site_id}/scans                            │
│  - Returns: scan_id                                             │
│  Duration: ~1 second                                             │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 6: Execute Scan Monitoring Step                           │
│  File: resources/scan_operations.robot                          │
│  Function: Monitor Scan Until Complete                          │
│  - Polls: GET /api/3/scans/{scan_id} every 5 seconds            │
│  - Logs: Console output every 60 seconds                        │
│  - Asset Discovery Timeout: 600 seconds (10 minutes)            │
│  - Scan Completion: No timeout (waits indefinitely)             │
│  - Monitors statuses: running → finished/stopped/error          │
│  Duration: Variable (typically 5-15 minutes)                    │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 7: Execute Scan Validation Step                           │
│  File: resources/scan_operations.robot                          │
│  Function: Get Scan Details                                     │
│  - GET /api/3/scans/{scan_id}                                   │
│  - Validates scan completed successfully                        │
│  - Checks vulnerability count                                   │
│  Duration: ~1 second                                             │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 8: Execute Policy Natural ID Retrieval Step               │
│  File: resources/policy_operations.robot                        │
│  Function: Get Policy Natural ID                                │
│  - GET /api/3/policies                                          │
│  - Extracts natural ID for policy                               │
│  Duration: ~1 second                                             │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 9: Execute Report Generation Step                         │
│  File: resources/report_operations.robot                        │
│  Function: Generate And Download XCCDF Report                   │
│  - Creates report config via library/generate_xccdf_report.py   │
│  - POST /api/3/reports to create report                         │
│  - Polls report status every 10 seconds                         │
│  - Max wait: 600 seconds (10 minutes)                           │
│  - Downloads report via GET /api/3/reports/{id}/history/{inst}  │
│  Duration: ~1-2 minutes                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 10: Execute Report Validation Step                        │
│  File: resources/report_operations.robot                        │
│  Function: Validate Report From Excel                           │
│  Library: library/excel_validator.py                            │
│  - Loads CSV rules: testdata/validation_rules/CIS/RHEL9/*.csv   │
│  - Parses XCCDF XML report                                      │
│  - Validates each rule: NUMBER, RULE_ID, EXPECTED_RESULT        │
│  - Returns: passed_count, failed_count                          │
│  Duration: ~2-5 seconds                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 11: Validate Compliance Results                           │
│  File: resources/e2e_benchmark_testing.robot                    │
│  Function: Validate Compliance Results                          │
│  - Asserts: validation_failed == 0                              │
│  - Fails test if any controls did not pass                      │
│  Duration: <1 second                                             │
└─────────────────────────────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────────────────────────────┐
│  [TEARDOWN]: Cleanup Test Resources                             │
│  File: resources/e2e_benchmark_testing.robot                    │
│  Function: Cleanup Test Resources                               │
│  - Deletes site: DELETE /api/1.1/xml (XML API)                  │
│  - Deletes template: DELETE /api/3/scan_templates/{id}          │
│  - Executes regardless of test pass/fail                        │
│  Duration: ~2-3 seconds                                          │
└─────────────────────────────────────────────────────────────────┘
    ↓
Test Complete
```

---

## Detailed Step-by-Step Execution

### STEP 0: Get Policies From JSON
**File:** `resources/policy_operations.robot`  
**Function:** `Get Policies From JSON`

```robotframework
${policy_info}=    Get Policies From JSON    ${benchmark}    ${os_name}    ${version}
```

**What it does:**
1. Loads `data/policies/cis_policies.json`
2. Navigates JSON structure: `CIS → Red Hat Enterprise Linux 9 → 2.0.0`
3. Extracts:
   - `policies`: List of policy IDs (e.g., `xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server`)
   - `benchmark_id`: Benchmark identifier
4. Returns dictionary with policy information

**JSON Structure Example:**
```json
{
  "CIS": {
    "Red Hat Enterprise Linux 9": {
      "2.0.0": {
        "benchmark_id": "xccdf_org.cisecurity.benchmarks_benchmark_CIS_Red_Hat_Enterprise_Linux_9_Benchmark",
        "policies": [
          "xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server",
          "xccdf_org.cisecurity.benchmarks_profile_Level_2_-_Server"
        ]
      }
    }
  }
}
```

---

### STEP 1: Execute Login Step
**File:** `resources/login.robot`  
**Function:** `Login To Console`  
**Duration:** ~1-2 seconds

```robotframework
${session_id}=    Login To Console
```

**What it does:**
1. Reads credentials from environment variables or config:
   - `${BASE_URL}`: Nexpose console URL
   - `${USERNAME}`: Console username
   - `${PASSWORD}`: Console password

2. Sends XML POST request to `/api/1.1/xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LoginRequest user-id="${USERNAME}" password="${PASSWORD}"/>
```

3. Parses XML response:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<LoginResponse success="1" session-id="ABC123XYZ..."/>
```

4. Extracts and stores `session-id` in global variable `${SESSION_ID}`

**Session Management:**
- Session ID is stored globally and reused across all API calls
- Session expires after inactivity (typically 30-60 minutes)
- If session expires during execution, automatic re-login is triggered
- Re-login detection: API returns 401 Unauthorized or specific error XML

**Session Expiry Handling:**
Located in `resources/scan_operations.robot` and `resources/report_operations.robot`:
```robotframework
TRY
    ${status_result}=    Get Scan Status    ${scan_id}
EXCEPT    AS    ${error}
    Log    ⚠️ Connection error: ${error}
    ${new_session}=    Login To Console
    Log    ✓ Re-authenticated with new session
END
```

---

### STEP 2: Execute Engine Selection Step
**File:** `resources/engine_operations.robot`  
**Function:** `Get Available Engines`  
**Duration:** ~1 second

```robotframework
${selected_engine_id}=    Execute Engine Selection Step    ${engine_id}
```

**What it does:**
1. If `engine_id` provided → uses that engine
2. If not provided:
   - Sends GET request: `/api/3/scan_engines`
   - Headers: `Cookie=nexposeCCSessionID=${SESSION_ID}`
   - Response: JSON list of engines with IDs
   - Selects first available engine

**Response Example:**
```json
{
  "resources": [
    {
      "id": 3,
      "name": "Local Scan Engine",
      "status": "active"
    }
  ]
}
```

---

### STEP 3: Execute Template Processing Step
**File:** `resources/scan_template_api.robot`  
**Function:** `Process Template For OS`  
**Duration:** ~2-3 seconds

```robotframework
${template_result}=    Execute Template Processing Step
    ...    ${scan_template}     # "cis"
    ...    ${os_name}            # "Red Hat Enterprise Linux 9"
    ...    ${version}            # "2.0.0"
    ...    ${policy_list}        # "all" or specific policies
    ...    ${template_name}      # Unique template name
```

**What it does:**
1. Loads template JSON from `data/templates/cis_template.json`
2. Injects OS-specific parameters
3. Filters policies:
   - If `policy_list=all` → includes all policies
   - If specific policies → filters to match
4. Formats policy IDs for API
5. Creates scan template via POST `/api/3/scan_templates`
6. Returns: `template_id`, `formatted_policies`, `policy_count`

**API Request Structure:**
```json
{
  "name": "RHEL9_CIS_Template_1735890123",
  "description": "CIS Benchmark template for RHEL 9",
  "policies": ["policy-id-1", "policy-id-2"],
  "scanType": "policy"
}
```

---

### STEP 4: Execute Site Creation Step
**File:** `resources/site.robot`  
**Function:** `Create Or Update Site With Credentials`  
**Duration:** ~2-3 seconds

```robotframework
${created_site_id}=    Execute Site Creation Step
    ...    ${site_name}
    ...    ${selected_engine_id}
    ...    ${template_id}
    ...    ${benchmark}         # CIS
    ...    ${vm_os}             # RHEL
    ...    ${vm_version}        # 9
    ...    ${service}           # ssh
    ...    ${scope}             # S
    ...    ${site_id}           # Empty for new, or existing ID
    ...    @{vm_cred_types}     # compliance, server
```

**What it does:**

#### A. Fetch VM Credentials
**File:** `testdata/vm_config.json`

**Navigation Path:**
```
vm_config.json
  └─ CIS
      └─ RHEL
          └─ 9
              └─ compliance
                  └─ server
                      ├─ service: "ssh"
                      ├─ ip: "192.168.1.100"
                      ├─ username: "root"
                      ├─ password: "encrypted_password"
                      ├─ port: 22
                      └─ privilege_elevation: {...}
```

**Credential Structure in JSON:**
```json
{
  "CIS": {
    "RHEL": {
      "9": {
        "compliance": {
          "server": {
            "service": "ssh",
            "ip": "192.168.1.100",
            "username": "root",
            "password": "P@ssw0rd123",
            "port": 22,
            "privilege_elevation": {
              "type": "sudo",
              "username": "root",
              "password": "P@ssw0rd123"
            }
          }
        }
      }
    }
  }
}
```

**How VM Credentials Are Loaded:**
1. Function: `Get Credentials From VM Config` in `resources/site.robot`
2. Parameters: `benchmark`, `vm_os`, `vm_version`, `cred_type` (e.g., "server")
3. Navigates JSON: `${benchmark} → ${vm_os} → ${vm_version} → compliance → ${cred_type}`
4. Extracts: IP, port, username, password, service, privilege elevation
5. Multiple credential types supported: `server`, `database`, `windows`

#### B. Create Site XML
```xml
<?xml version="1.0" encoding="UTF-8"?>
<SiteSaveRequest session-id="${SESSION_ID}">
  <Site name="RHEL9_CIS_Level1_Server_1735890123" description="CIS Benchmark Test">
    <Hosts>
      <host>192.168.1.100</host>
    </Hosts>
    <Credentials>
      <adminCredentials service="ssh">
        <account username="root" password="P@ssw0rd123" port="22"/>
        <elevationCredentials type="sudo" username="root" password="P@ssw0rd123"/>
      </adminCredentials>
    </Credentials>
    <ScanConfig configID="${template_id}" engineID="${selected_engine_id}"/>
  </Site>
</SiteSaveRequest>
```

#### C. Send Site Creation Request
- POST to `/api/1.1/xml` with XML payload
- Response contains `site-id`
- Stored in `${created_site_id}`

---

### STEP 5: Execute Scan Start Step
**File:** `resources/scan_operations.robot`  
**Function:** `Start Scan`  
**Duration:** ~1 second

```robotframework
${scan_result}=    Execute Scan Start Step
    ...    ${created_site_id}
    ...    ${selected_engine_id}
    ...    ${site_name}
```

**What it does:**
1. POST to `/api/3/sites/${site_id}/scans`
2. Request body:
```json
{
  "engineId": 3,
  "name": "RHEL9 CIS Scan"
}
```
3. Response:
```json
{
  "id": 12345,
  "status": "running"
}
```
4. Returns scan_id: `12345`

---

### STEP 6: Execute Scan Monitoring Step
**File:** `resources/scan_operations.robot`  
**Function:** `Monitor Scan Until Complete`  
**Duration:** Variable (5-15 minutes typical)

```robotframework
${monitor_result}=    Execute Scan Monitoring Step
    ...    ${scan_id}
    ...    ${site_id}
```

**Timing Configuration:**
- **Poll Interval:** 5 seconds (API call frequency)
- **Log Interval:** 60 seconds (console output frequency)
- **Asset Discovery Timeout:** 600 seconds (10 minutes)
- **Scan Completion Timeout:** None (waits indefinitely)

**What it does:**

1. **Initialization:**
```robotframework
${start_time}=    Evaluate    int(__import__('time').time())
${asset_discovery_timeout}=    Set Variable    ${600}    # 10 minutes
${asset_discovered}=    Set Variable    ${False}
```

2. **Polling Loop:**
```robotframework
WHILE    True
    # Every 5 seconds: Check scan status
    ${status_result}=    Get Scan Status    ${scan_id}
    ${status}=    Set Variable    ${status_result}[status]
    
    # Every 60 seconds: Log to console
    ${current_time}=    Evaluate    int(__import__('time').time())
    ${elapsed}=    Evaluate    ${current_time} - ${last_log_time}
    IF    ${elapsed} >= 60
        Log    ⏳ Scan Status: ${status} | Assets: ${asset_count} | Time: ${total_elapsed}s
        ${last_log_time}=    Set Variable    ${current_time}
    END
    
    # Check if assets discovered
    IF    ${asset_count} > 0
        ${asset_discovered}=    Set Variable    ${True}
    END
    
    # Asset discovery timeout check (10 minutes)
    ${total_elapsed}=    Evaluate    ${current_time} - ${start_time}
    IF    ${total_elapsed} >= ${asset_discovery_timeout} and not ${asset_discovered}
        Log    ⚠️ Asset discovery timeout after 10 minutes
        RETURN    status=asset_discovery_timeout
    END
    
    # Scan completion check
    IF    '${status}' == 'finished' or '${status}' == 'stopped' or '${status}' == 'error'
        BREAK
    END
    
    Sleep    5s    # Wait before next poll
END
```

3. **Status Tracking:**
   - `integrating` → Assets being added
   - `running` → Scan in progress
   - `finished` → Scan completed successfully
   - `stopped` → Scan stopped by user
   - `error` → Scan failed

4. **Console Output Example:**
```
========================================
MONITORING SCAN: 12345
API Poll Interval: 5 seconds
Log Display Interval: 60 seconds
Asset Discovery Timeout: 600 seconds
========================================
⏳ Scan Status: running | Assets: 1 | Time: 62s | Progress: 25%
⏳ Scan Status: running | Assets: 1 | Time: 122s | Progress: 50%
⏳ Scan Status: running | Assets: 1 | Time: 182s | Progress: 75%
✓ Scan Status: finished | Assets: 1 | Time: 235s | Progress: 100%
========================================
```

---

### STEP 7: Execute Scan Validation Step
**File:** `resources/scan_operations.robot`  
**Function:** `Get Scan Details`  
**Duration:** ~1 second

```robotframework
${scan_details}=    Execute Scan Validation Step
    ...    ${scan_id}
    ...    ${site_id}
    ...    ${validate_compliance}    # TRUE
    ...    ${expected_vuln_count}    # 0
```

**What it does:**
1. GET `/api/3/scans/${scan_id}`
2. Validates:
   - Scan status is "finished"
   - Vulnerability count matches expected (for compliance, expects 0)
3. Returns scan details dictionary

---

### STEP 8: Execute Policy Natural ID Retrieval Step
**File:** `resources/policy_operations.robot`  
**Function:** `Get Policy Natural ID`  
**Duration:** ~1 second

```robotframework
${policy_natural_ids}=    Execute Policy Natural ID Retrieval Step
    ...    ${formatted_policies}
```

**What it does:**
1. GET `/api/3/policies`
2. Finds policy by formatted ID
3. Extracts `natural_id` (used for XCCDF report generation)
4. Returns list of natural IDs

**Example:**
- Input: `xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server`
- Output: Natural ID for XCCDF report request

---

### STEP 9: Execute Report Generation Step
**File:** `resources/report_operations.robot`  
**Function:** `Generate And Download XCCDF Report`  
**Duration:** ~1-2 minutes

```robotframework
${report_result}=    Execute Report Generation Step
    ...    ${site_id}
    ...    ${policy_natural_ids}
```

**Timing Configuration:**
- **Status Check Interval:** 10 seconds
- **Maximum Wait:** 600 seconds (10 minutes)
- **Max Attempts:** 60 attempts × 10 seconds = 600 seconds

**What it does:**

1. **Build XCCDF Report Request:**
```python
# library/generate_xccdf_report.py
report_xml = build_xccdf_report_xml(
    site_id=site_id,
    policy_ids=policy_natural_ids,
    format="xccdf-xml"
)
```

2. **Create Report Configuration:**
   - POST `/api/3/reports`
   - Request body: XCCDF report XML template
   - Response: `report_id`

3. **Monitor Report Generation:**
```robotframework
${attempt}=    Set Variable    0
${max_attempts}=    Set Variable    60    # 10 minutes

WHILE    '${status}' == 'Started' and ${attempt} < ${max_attempts}
    ${attempt}=    Evaluate    ${attempt} + 1
    Log    ⏳ Report generating (Attempt ${attempt}/${max_attempts})
    Sleep    10s
    
    ${status_result}=    Get Report Status    ${report_id}
    ${status}=    Set Variable    ${status_result}[latest_status]
END
```

4. **Download Report:**
   - GET `/api/3/reports/${report_id}/history/${instance_id}`
   - Returns XCCDF XML content
   - Typical size: 500KB - 5MB

**Console Output:**
```
========================================
GENERATING XCCDF REPORT
Site ID: 123
Policy IDs: ["policy-1", "policy-2"]
========================================
⏳ Report generating (Attempt 1/60), waiting 10s...
⏳ Report generating (Attempt 2/60), waiting 10s...
✓ Report Status: Complete
Downloaded Report Size: 1,234,567 bytes
========================================
```

---

### STEP 10: Execute Report Validation Step
**File:** `resources/report_operations.robot`  
**Function:** `Validate Report From Excel`  
**Library:** `library/excel_validator.py`  
**Duration:** ~2-5 seconds

```robotframework
${validation_result}=    Execute Report Validation Step
    ...    ${report_ids}
    ...    ${csv_file}    # testdata/validation_rules/CIS/RHEL9/level1_server.csv
```

**CSV Rules File Format:**
```csv
NUMBER,RULE_ID,EXPECTED_RESULT
1.1.1,xccdf_org.cisecurity.benchmarks_rule_1.1.1_Ensure_mounting_of_cramfs_filesystems_is_disabled,pass
1.1.2,xccdf_org.cisecurity.benchmarks_rule_1.1.2_Ensure_mounting_of_freevxfs_filesystems_is_disabled,pass
1.1.3,xccdf_org.cisecurity.benchmarks_rule_1.1.3_Ensure_mounting_of_jffs2_filesystems_is_disabled,pass
```

**What it does:**

1. **Load CSV Rules:**
```python
# library/excel_validator.py
def load_rules_from_csv(csv_path):
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        rules = [
            {
                'number': row['NUMBER'],
                'rule_id': row['RULE_ID'],
                'expected': row['EXPECTED_RESULT']
            }
            for row in reader
        ]
    return rules
```

2. **Parse XCCDF XML Report:**
```python
import xml.etree.ElementTree as ET

tree = ET.fromstring(xml_content)
namespaces = {'xccdf': 'http://checklists.nist.gov/xccdf/1.2'}

# Find all rule results
rule_results = tree.findall('.//xccdf:rule-result', namespaces)
```

3. **Validate Each Rule:**
```python
passed = 0
failed = 0
failures = []

for rule in csv_rules:
    # Find matching rule-result in XCCDF
    xpath = f".//xccdf:rule-result[@idref='{rule['rule_id']}']/xccdf:result"
    result_elem = tree.find(xpath, namespaces)
    
    actual_result = result_elem.text  # "pass", "fail", "notapplicable"
    expected_result = rule['expected']
    
    if actual_result == expected_result:
        passed += 1
    else:
        failed += 1
        failures.append({
            'number': rule['number'],
            'rule_id': rule['rule_id'],
            'expected': expected_result,
            'actual': actual_result
        })

return {
    'passed': passed,
    'failed': failed,
    'failures': failures
}
```

4. **Console Output:**
```
========================================
✅ VALIDATION COMPLETE
Passed: 235 ✓
Failed: 0 ✗
========================================
```

---

### STEP 11: Validate Compliance Results
**File:** `resources/e2e_benchmark_testing.robot`  
**Function:** `Validate Compliance Results`  
**Duration:** <1 second

```robotframework
Validate Compliance Results
    ...    os_name=${os_name}
    ...    benchmark=${benchmark}
    ...    version=${version}
    ...    validation_passed=${validation_result}[passed]
    ...    validation_failed=${validation_result}[failed]
```

**What it does:**
```robotframework
Should Be Equal As Integers    ${validation_failed}    0
    ...    msg=${os_name} ${benchmark} v${version} compliance test FAILED: 
    ...        ${validation_failed} security control(s) did not meet compliance requirements.
```

- If any controls failed → Test FAILS with detailed message
- If all controls passed → Test continues to teardown

---

### TEARDOWN: Cleanup Test Resources
**File:** `resources/e2e_benchmark_testing.robot`  
**Function:** `Cleanup Test Resources`  
**Duration:** ~2-3 seconds

```robotframework
[Teardown]    Cleanup Test Resources    ${results}[site_id]    ${results}[template_id]
```

**What it does:**

1. **Delete Site:**
```robotframework
IF    '${site_id}' != '${EMPTY}'
    TRY
        site.Delete Site    ${site_id}
        Log    ✓ Site deleted successfully
    EXCEPT    AS    ${error}
        Log    ⚠️ Failed to delete site: ${error}
    END
END
```

**API Call:**
- POST `/api/1.1/xml` with XML:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<SiteDeleteRequest session-id="${SESSION_ID}" site-id="${site_id}"/>
```

2. **Delete Scan Template:**
```robotframework
IF    '${template_id}' != '${EMPTY}'
    TRY
        Delete Scan Template    ${template_id}
        Log    ✓ Scan template deleted successfully
    EXCEPT    AS    ${error}
        Log    ⚠️ Failed to delete template: ${error}
    END
END
```

**API Call:**
- DELETE `/api/3/scan_templates/${template_id}`
- Headers: `Cookie=nexposeCCSessionID=${SESSION_ID}`

**Important:** Cleanup executes **regardless** of test pass/fail status. Errors during cleanup are logged but do not fail the test.

---

## Session Management & Authentication

### Session Lifecycle

```
Test Start
    ↓
Login To Console
    ↓ (stores ${SESSION_ID})
    ├─ Step 1: Create Template (uses ${SESSION_ID})
    ├─ Step 2: Create Site (uses ${SESSION_ID})
    ├─ Step 3: Start Scan (uses ${SESSION_ID})
    ├─ Step 4: Monitor Scan (uses ${SESSION_ID})
    │   └─ If 401/timeout → Re-login → New ${SESSION_ID}
    ├─ Step 5: Generate Report (uses ${SESSION_ID})
    └─ Teardown: Cleanup (uses ${SESSION_ID})
```

### Session Storage
**Location:** Global variable `${SESSION_ID}` in `resources/login.robot`

```robotframework
*** Variables ***
${SESSION_ID}    ${EMPTY}    # Initialized as empty
```

### Session Usage in API Calls

**XML API (1.1):**
```xml
<SiteSaveRequest session-id="${SESSION_ID}">
  ...
</SiteSaveRequest>
```

**REST API (3.0):**
```python
headers = {
    'Cookie': f'nexposeCCSessionID={SESSION_ID}',
    'Content-Type': 'application/json'
}
```

### Session Expiry Detection

**Indicators:**
1. HTTP 401 Unauthorized
2. XML response with `success="0"`
3. Connection timeout errors
4. API returns authentication error

**Re-authentication Logic:**
```robotframework
TRY
    ${response}=    GET    ${url}    headers=${headers}
EXCEPT    AS    ${error}
    Run Keyword If    'Unauthorized' in '${error}' or '401' in '${error}'
    ...    Login To Console
    ${response}=    GET    ${url}    headers=${headers}    # Retry with new session
END
```

### Session Timeout Settings
- **Default Timeout:** 30-60 minutes (Nexpose server setting)
- **Test Duration:** Typically 10-20 minutes
- **Risk:** Low (tests usually complete before expiry)

---

## VM Credentials Configuration

### Credential Storage Location
**File:** `testdata/vm_config.json`

### JSON Structure

```json
{
  "CIS": {
    "RHEL": {
      "9": {
        "compliance": {
          "server": {
            "service": "ssh",
            "ip": "192.168.1.100",
            "username": "root",
            "password": "SecureP@ssw0rd123",
            "port": 22,
            "privilege_elevation": {
              "type": "sudo",
              "username": "root",
              "password": "SecureP@ssw0rd123"
            }
          }
        }
      }
    },
    "Ubuntu": {
      "Ubuntu-20-04": {
        "compliance": {
          "server": {
            "service": "ssh",
            "ip": "192.168.1.101",
            "username": "ubuntu",
            "password": "UbuntuP@ss",
            "port": 22,
            "privilege_elevation": {
              "type": "sudo",
              "username": "root",
              "password": "RootP@ss"
            }
          }
        }
      }
    },
    "Microsoft": {
      "Windows-Server-2019": {
        "compliance": {
          "server": {
            "service": "cifs",
            "ip": "192.168.1.102",
            "username": "Administrator",
            "password": "WinP@ss123",
            "port": 445
          }
        }
      }
    },
    "ORACLE": {
      "19C": {
        "compliance": {
          "server": {
            "service": "ssh",
            "ip": "192.168.1.103",
            "username": "oracle",
            "password": "OracleP@ss",
            "port": 22
          },
          "database": {
            "service": "oracle",
            "ip": "192.168.1.103",
            "username": "system",
            "password": "DBP@ss123",
            "port": 1521,
            "sid": "ORCL"
          }
        }
      }
    }
  }
}
```

### Credential Retrieval Process

**Function:** `Get Credentials From VM Config` in `resources/site.robot`

```robotframework
Get Credentials From VM Config
    [Arguments]    ${benchmark}    ${vm_os}    ${vm_version}    ${cred_type}
    
    # Load JSON file
    ${json_content}=    OperatingSystem.Get File    ${EXECDIR}/testdata/vm_config.json
    ${config}=    Evaluate    json.loads('''${json_content}''')    json
    
    # Navigate: CIS → RHEL → 9 → compliance → server
    ${creds}=    Set Variable    ${config}[${benchmark}][${vm_os}][${vm_version}][compliance][${cred_type}]
    
    RETURN    ${creds}
```

### Credential Types

1. **server** - OS-level credentials (SSH/CIFS/WinRM)
2. **database** - Database credentials (Oracle, MySQL, PostgreSQL)
3. **windows** - Windows-specific credentials

### Multiple Credential Handling

**Example:** Oracle 19c requires both server AND database credentials

```robotframework
vm_cred_types=compliance,server,database
```

**Parsing:**
```robotframework
@{cred_list}=    Split String    ${vm_cred_types}    ,
# Results in: ['compliance', 'server', 'database']

FOR    ${cred_type}    IN    @{cred_list}
    ${creds}=    Get Credentials From VM Config    CIS    ORACLE    19C    ${cred_type}
    # Add credentials to site XML
END
```

### Credential Security

**Current Implementation:** Plain text in JSON (for POC)

**Production Recommendations:**
1. Use environment variables
2. Integrate with secret management (HashiCorp Vault, AWS Secrets Manager)
3. Encrypt credential file
4. Use Nexpose credential management APIs

---

## Library Architecture

### Python Libraries

#### 1. **excel_validator.py**
**Location:** `library/excel_validator.py`  
**Purpose:** Validate XCCDF reports against CSV rules

**Dependencies:**
- `csv` - Read CSV rule files
- `openpyxl` - Excel file handling (if needed)
- `xml.etree.ElementTree` - Parse XCCDF XML
- `pathlib` - File path handling
- `typing` - Type hints

**Key Functions:**
```python
def load_rules_from_csv(csv_path: str) -> List[Dict]
def validate_xccdf_report(xml_content: str, rules: List[Dict]) -> Dict
def get_validation_summary(results: Dict) -> str
```

**Usage in Robot:**
```robotframework
Library    ../library/excel_validator.py

${passed}    ${failed}    ${results}=    Validate Report From Excel
    ...    excel_path=${csv_file}
    ...    xml_content=${xccdf_report}
    ...    file_type=csv
```

#### 2. **generate_xccdf_report.py**
**Location:** `library/generate_xccdf_report.py`  
**Purpose:** Build XCCDF report request XML/JSON

**Dependencies:**
- `json` - Load report templates
- `typing` - Type hints

**Key Functions:**
```python
def build_xccdf_report_xml(site_id: str, policy_ids: List[str], format: str) -> str
def load_and_build_xccdf_report(template_path: str, **kwargs) -> str
```

**Usage in Robot:**
```robotframework
Library    ../library/generate_xccdf_report.py

${report_xml}=    Build XCCDF Report Request
    ...    site_id=${site_id}
    ...    policy_ids=${policy_natural_ids}
    ...    format=xccdf-xml
```

#### 3. **format_xml.py**
**Location:** `library/format_xml.py`  
**Purpose:** Pretty-print XML for debugging

**Dependencies:**
- `xml.dom.minidom` - XML formatting
- `sys` - Command-line interface

**Usage:**
```bash
python library/format_xml.py input.xml output.xml
```

**Note:** Not directly used in Robot tests (utility script)

### Robot Framework Resources

```
resources/
├── login.robot                    # Authentication & session management
├── engine_operations.robot        # Scan engine selection
├── scan_template_api.robot        # Template creation & management
├── site.robot                     # Site creation, credential handling, deletion
├── scan_operations.robot          # Scan execution & monitoring
├── policy_operations.robot        # Policy retrieval & JSON parsing
├── report_operations.robot        # Report generation & validation
└── e2e_benchmark_testing.robot    # Main orchestration & workflow
```

### Import Hierarchy

```
Test File (e.g., RHEL9benchmarks.robot)
    ↓
resources/e2e_benchmark_testing.robot
    ├─ imports: login.robot
    ├─ imports: engine_operations.robot
    ├─ imports: scan_template_api.robot
    ├─ imports: site.robot
    ├─ imports: scan_operations.robot
    ├─ imports: policy_operations.robot
    └─ imports: report_operations.robot
            ├─ imports: library/excel_validator.py
            └─ imports: library/generate_xccdf_report.py
```

### Shared Libraries

**Robot Framework Built-in:**
- `RequestsLibrary` - HTTP API calls
- `Collections` - Dictionary/list operations
- `OperatingSystem` - File operations
- `String` - String manipulation
- `XML` - XML parsing
- `Process` - External process execution

**Python Standard Library:**
- `json` - JSON parsing
- `csv` - CSV file handling
- `time` - Timestamps and delays
- `xml.etree.ElementTree` - XML parsing
- `xml.dom.minidom` - XML formatting

---

## Timing and Waits

### Complete Test Duration Breakdown

**Example: RHEL 9 CIS Benchmark Test**

| Step | Description | Duration | Waits/Polls |
|------|-------------|----------|-------------|
| 0 | Get Policies From JSON | ~1s | - |
| 1 | Login to Console | ~1-2s | - |
| 2 | Get Scan Engine | ~1s | - |
| 3 | Process Template | ~2-3s | - |
| 4 | Create Site with Credentials | ~2-3s | - |
| 5 | Start Scan | ~1s | - |
| 6 | **Monitor Scan** | **5-15 min** | Poll every 5s, log every 60s |
| 7 | Validate Scan Completion | ~1s | - |
| 8 | Get Policy Natural ID | ~1s | - |
| 9 | **Generate Report** | **1-2 min** | Poll every 10s, max 10 min |
| 10 | Validate Report | ~2-5s | - |
| 11 | Validate Compliance | <1s | - |
| Teardown | Cleanup Resources | ~2-3s | - |
| **TOTAL** | **~7-18 minutes** | - |

### Detailed Timing Configuration

#### Scan Monitoring (Step 6)
```robotframework
# File: resources/scan_operations.robot
# Function: Monitor Scan Until Complete

${poll_interval}=    Set Variable    ${5}        # Check status every 5 seconds
${log_interval}=    Set Variable    ${60}       # Console log every 60 seconds
${asset_discovery_timeout}=    Set Variable    ${600}  # 10 minutes for asset discovery

# No overall timeout - waits until scan finishes
```

**Why No Overall Timeout?**
- Scan duration varies greatly (5-20+ minutes)
- Depends on: target complexity, policy count, network speed
- Better to wait indefinitely than fail prematurely
- Asset discovery timeout catches stuck scans

#### Report Generation (Step 9)
```robotframework
# File: resources/report_operations.robot
# Function: Generate And Download XCCDF Report

${check_interval}=    Set Variable    ${10}      # Check status every 10 seconds
${max_attempts}=    Set Variable    ${60}       # 60 attempts = 600 seconds = 10 minutes
${max_wait}=    Evaluate    ${max_attempts} * ${check_interval}  # 600 seconds
```

**Timeout Behavior:**
- If report not generated in 10 minutes → Test FAILS
- Typical report generation: 30-90 seconds
- 10-minute timeout is safety net

#### Retry Logic

**Scan Start Retry:**
```robotframework
# If scan fails to start (rare), retry up to 3 times
${max_retries}=    Set Variable    ${3}

FOR    ${attempt}    IN RANGE    1    ${max_retries + 1}
    TRY
        ${scan_id}=    Start Scan    ${site_id}
        BREAK
    EXCEPT
        IF    ${attempt} == ${max_retries}
            Fail    Failed to start scan after ${max_retries} attempts
        END
        Sleep    10s
    END
END
```

**Session Re-authentication:**
- No retry limit
- Automatic re-login on 401/timeout
- Continues from where it left off

### Sleep Statements Summary

| Location | Duration | Purpose |
|----------|----------|---------|
| Scan monitoring loop | 5s | Wait between status checks |
| Report status loop | 10s | Wait between report status checks |
| Connection error retry | 10s | Wait before re-authentication |
| Asset discovery check | 5s | Part of scan monitoring loop |

**Total Sleep Time in Typical Test:**
- Scan monitoring: ~180 sleep calls × 5s = 900s (15 min)
- Report generation: ~6 sleep calls × 10s = 60s (1 min)
- **Total: ~16 minutes of actual scan/report work**

---

## File Structure and Dependencies

### Project Structure
```
poc_robot_framework/
├── tests/
│   ├── CIS/
│   │   ├── Linux/
│   │   │   ├── RHEL/
│   │   │   │   └── RHEL9benchmarks.robot
│   │   │   └── Ubuntu/
│   │   │       ├── ubuntu_20.04_benchmarks.robot
│   │   │       └── ubuntu_24.04_benchmarks.robot
│   │   ├── Windows/
│   │   │   └── windows_sever_2019_standalone.robot
│   │   └── Oracle/
│   │       └── oracle19cbenchmark.robot
│   └── DISA/
│       └── windows10benchmark.robot
│
├── resources/
│   ├── e2e_benchmark_testing.robot        # Main orchestration
│   ├── login.robot                        # Authentication
│   ├── engine_operations.robot            # Engine management
│   ├── scan_template_api.robot            # Template operations
│   ├── site.robot                         # Site & credential management
│   ├── scan_operations.robot              # Scan execution
│   ├── policy_operations.robot            # Policy handling
│   └── report_operations.robot            # Report generation
│
├── library/
│   ├── excel_validator.py                 # CSV/XCCDF validation
│   ├── generate_xccdf_report.py           # Report request builder
│   └── format_xml.py                      # XML utility
│
├── testdata/
│   ├── vm_config.json                     # VM credentials
│   └── validation_rules/
│       ├── CIS/
│       │   ├── RHEL9/
│       │   │   └── level1_server.csv
│       │   ├── Ubuntu2004/
│       │   │   └── level1_server.csv
│       │   └── WindowsServer2019/
│       │       └── level1_member_server.csv
│       └── DISA/
│           └── Windows10/
│               └── stig_baseline.csv
│
└── data/
    ├── policies/
    │   └── cis_policies.json              # Policy definitions
    └── templates/
        ├── cis_template.json              # CIS template
        └── disa_template.json             # DISA template
```

### Dependency Map

```
RHEL9benchmarks.robot
    ↓ imports
e2e_benchmark_testing.robot
    ↓ calls
    ├─ Login To Console (login.robot)
    │   └─ Uses: ${BASE_URL}, ${USERNAME}, ${PASSWORD}
    │
    ├─ Get Available Engines (engine_operations.robot)
    │   └─ Uses: ${SESSION_ID}
    │
    ├─ Process Template For OS (scan_template_api.robot)
    │   └─ Reads: data/templates/cis_template.json
    │   └─ Uses: ${SESSION_ID}
    │
    ├─ Create Or Update Site (site.robot)
    │   └─ Reads: testdata/vm_config.json
    │   └─ Uses: ${SESSION_ID}
    │
    ├─ Start Scan (scan_operations.robot)
    │   └─ Uses: ${SESSION_ID}
    │
    ├─ Monitor Scan Until Complete (scan_operations.robot)
    │   └─ Uses: ${SESSION_ID}
    │   └─ Polls every 5s, logs every 60s
    │
    ├─ Get Policy Natural ID (policy_operations.robot)
    │   └─ Uses: ${SESSION_ID}
    │
    ├─ Generate And Download XCCDF Report (report_operations.robot)
    │   └─ Uses: library/generate_xccdf_report.py
    │   └─ Uses: ${SESSION_ID}
    │   └─ Polls every 10s, max 60 attempts
    │
    ├─ Validate Report From Excel (report_operations.robot)
    │   └─ Uses: library/excel_validator.py
    │   └─ Reads: testdata/validation_rules/CIS/RHEL9/level1_server.csv
    │
    └─ Cleanup Test Resources (e2e_benchmark_testing.robot)
        ├─ Delete Site (site.robot)
        └─ Delete Scan Template (e2e_benchmark_testing.robot)
```

### Configuration Files

#### 1. vm_config.json
**Purpose:** Store target system credentials  
**Location:** `testdata/vm_config.json`  
**Used by:** `site.robot → Get Credentials From VM Config`

#### 2. cis_policies.json
**Purpose:** Define CIS benchmark policies  
**Location:** `data/policies/cis_policies.json`  
**Used by:** `policy_operations.robot → Get Policies From JSON`

#### 3. cis_template.json
**Purpose:** Scan template configuration  
**Location:** `data/templates/cis_template.json`  
**Used by:** `scan_template_api.robot → Process Template For OS`

#### 4. level1_server.csv
**Purpose:** Validation rules for compliance checks  
**Location:** `testdata/validation_rules/CIS/RHEL9/level1_server.csv`  
**Used by:** `library/excel_validator.py`

### Environment Variables

**Required:**
```bash
export BASE_URL="https://nexpose-console.example.com"
export USERNAME="admin"
export PASSWORD="SecureP@ssw0rd"
```

**Optional:**
```bash
export ENGINE_ID="3"                    # Default scan engine
export SCAN_TIMEOUT="7200"              # Scan timeout in seconds
export REPORT_TIMEOUT="600"             # Report generation timeout
export LOG_LEVEL="INFO"                 # DEBUG, INFO, WARN, ERROR
```

---

## Quick Reference

### Run a Test
```bash
robot tests/CIS/Linux/RHEL/RHEL9benchmarks.robot
```

### Run with Custom Output
```bash
robot --outputdir results --loglevel DEBUG tests/CIS/Linux/RHEL/RHEL9benchmarks.robot
```

### Run Multiple Tests
```bash
robot --outputdir results tests/CIS/Linux/RHEL/*.robot
```

### View Results
```bash
open results/report.html
```

### Key Files to Check
- **Credentials:** `testdata/vm_config.json`
- **Policies:** `data/policies/cis_policies.json`
- **Validation Rules:** `testdata/validation_rules/CIS/RHEL9/level1_server.csv`
- **Templates:** `data/templates/cis_template.json`

### Troubleshooting Commands
```bash
# Check session ID
grep "Session ID" results/log.html

# Check scan status
grep "Scan Status" results/log.html

# Check validation results
grep "VALIDATION COMPLETE" results/log.html

# Check cleanup
grep "CLEANUP" results/log.html
```

---

## Summary

This document provides a complete view of the Robot Framework E2E benchmark testing execution flow. Key takeaways:

1. **Test Entry:** Simple test file calls one main keyword
2. **Orchestration:** E2E keyword coordinates 11 steps
3. **Authentication:** Session-based with automatic re-login
4. **Credentials:** Loaded from JSON, navigated by benchmark/OS/version
5. **Timing:** Scans take 5-15 minutes, reports 1-2 minutes
6. **Monitoring:** Polls every 5-10 seconds, logs periodically
7. **Validation:** CSV rules checked against XCCDF report
8. **Cleanup:** Always runs, even on test failure
9. **Libraries:** Python for complex logic, Robot for workflow

**Total Test Duration:** ~7-18 minutes for typical compliance scan

**Files Involved:** 
- 6 Robot resource files
- 3 Python libraries
- 4 configuration/data files
- 1 CSV validation file per OS/benchmark

**API Calls:** 15-20 calls per test (login, create, start, monitor, report, cleanup)
