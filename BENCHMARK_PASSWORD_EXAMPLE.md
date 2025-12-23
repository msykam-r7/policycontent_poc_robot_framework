# Benchmark Testing: Password Policy Example

## Overview
This document explains how CIS benchmark testing works using **password policies** as a real-world example. Understanding these concepts will help the team interpret test results and determine compliance status.

---

## 🎯 What is a Benchmark Rule?

A **benchmark rule** is a specific security configuration requirement that must be met for your system to be considered "compliant" with industry standards (CIS, DISA STIG, etc.).

### Example Rule: Password Length Configuration

**Rule ID:** `xccdf_org.cisecurity.benchmarks_rule_5.3.3.2.2_Ensure_password_length_is_configured`

**What it checks:** Ensures that passwords must meet a minimum length requirement (typically 14+ characters)

---

## 📊 Three Possible Outcomes

### 1. ✅ **PASS (COMPLIANT)**
The system **meets** the security requirement.

#### Example Scenario:
**Requirement:** Password must be at least 14 characters long

**System Configuration:**
```bash
# /etc/security/pwquality.conf
minlen = 14
```

**Test Result:** `COMPLIANT` ✅

**What happens in the test:**
- Framework scans your RHEL 9 server
- Checks `/etc/security/pwquality.conf`
- Finds `minlen = 14`
- Compares: Required (≥14) vs Actual (14)
- **Result:** PASS - System is configured correctly

---

### 2. ❌ **FAIL (NOT COMPLIANT)**
The system **does not meet** the security requirement.

#### Example Scenario:
**Requirement:** Password must be at least 14 characters long

**System Configuration:**
```bash
# /etc/security/pwquality.conf
minlen = 8
```
**OR** the setting is missing entirely.

**Test Result:** `NOT COMPLIANT` ❌

**What happens in the test:**
- Framework scans your RHEL 9 server
- Checks `/etc/security/pwquality.conf`
- Finds `minlen = 8` (or setting is absent)
- Compares: Required (≥14) vs Actual (8)
- **Result:** FAIL - Configuration is too weak
- **Reported as:** Vulnerability in scan results

---

### 3. ℹ️ **INFORMATIONAL**
The rule **requires manual review** - automated testing cannot determine compliance.

#### Example Scenario:
**Rule:** `xccdf_org.cisecurity.benchmarks_rule_5.3.3.2.3_Ensure_password_complexity_is_configured`

**System Configuration:**
```bash
# /etc/security/pwquality.conf
dcredit = -1    # Requires at least 1 digit
ucredit = -1    # Requires at least 1 uppercase
lcredit = -1    # Requires at least 1 lowercase
ocredit = -1    # Requires at least 1 special character
```

**Test Result:** `INFORMATIONAL` ℹ️

**Why?** 
Because the scanner **cannot determine** if your organization's specific password complexity policy is appropriate. Some organizations may require 2 special characters, others may only need 1. This needs **human judgment**.

---

## 🔬 Real Test Case Walkthrough

### Test Case: CIS RHEL 9 Password Policy Validation

Let's walk through what happens when you run the test from `ubuntubenchmark3.0.0.robot`:

#### **Step 1: Test Preparation**
```robotframework
# Test logs in and creates a site to scan
${session_id}=    Login To Console
${site_id}=    Create Site With VM Config
```

#### **Step 2: Scan Execution**
```robotframework
# Framework scans the target server
${scan_result}=    Start Scan    ${site_id}
${monitor_result}=    Monitor Scan Until Complete    ${scan_id}
```

#### **Step 3: Rule Evaluation**
The scanner checks **multiple password rules**:

| Rule | Description | Expected | What Scanner Checks |
|------|-------------|----------|---------------------|
| `5.3.3.2.2` | Password length configured | `NOT COMPLIANT` | Checks `minlen` in `/etc/security/pwquality.conf` |
| `5.3.3.1.1` | Failed login attempts lockout | `NOT COMPLIANT` | Checks `deny` setting in PAM configuration |
| `5.3.3.2.6` | Password dictionary check enabled | `COMPLIANT` | Checks `dictcheck = 1` in pwquality.conf |
| `5.4.1.1` | Password expiration configured | `NOT COMPLIANT` | Checks `PASS_MAX_DAYS` in `/etc/login.defs` |
| `5.4.1.3` | Password expiration warning | `COMPLIANT` | Checks `PASS_WARN_AGE` in `/etc/login.defs` |

#### **Step 4: Results Analysis**

**If a rule shows `NOT COMPLIANT`:**
```robotframework
# Framework expects this system to be non-compliant
Should Be Equal    ${rule_result}    NOT COMPLIANT

# Scan reports this as a vulnerability
${vuln_count}=    Set Variable    ${final_scan_details}[vulnerabilities]
# vuln_count > 0 because configuration doesn't meet CIS standards
```

**If a rule shows `COMPLIANT`:**
```robotframework
# System meets the requirement
# No vulnerability reported for this rule
```

---

## 🎓 Team Understanding Guide

### When Will a Test Return an Error? ❌

An **error** occurs when:
1. **System configuration doesn't meet the benchmark requirement**
   - Example: Password length is 8, but CIS requires 14
   
2. **Configuration file is missing or malformed**
   - Example: `/etc/security/pwquality.conf` doesn't exist
   
3. **Service is not installed**
   - Example: PAM modules are not installed

4. **Permissions prevent access to configuration**
   - Example: Scanner cannot read `/etc/shadow`

### When Will a Test Pass? ✅

A test **passes** when:
1. **System configuration matches or exceeds the requirement**
   - Example: Password length is 14 or more
   
2. **All required services are properly configured**
   - Example: PAM modules are installed and configured correctly
   
3. **File permissions meet security standards**
   - Example: `/etc/shadow` has mode 0000

### When Will a Test Fail? ❌

A test **fails** when:
1. **Expected result is `COMPLIANT` but system is `NOT COMPLIANT`**
   - Your system should meet the standard but doesn't
   
2. **Expected result is `NOT COMPLIANT` but system is `COMPLIANT`**
   - Your test baseline expects a vulnerability, but system is actually secure
   
3. **Validation mismatch**
   - The CSV validation file doesn't match actual scan results

---

## 📋 Complete Password Policy Example Matrix

Here's a real example from CIS RHEL 9 benchmarks:

| # | Rule Name | Expected Result | Configuration File | What Gets Checked | Pass Condition | Fail Condition |
|---|-----------|----------------|-------------------|-------------------|----------------|----------------|
| 163 | Password length | `NOT COMPLIANT` | `/etc/security/pwquality.conf` | `minlen` parameter | minlen ≥ 14 | minlen < 14 or missing |
| 160 | Failed attempts lockout | `NOT COMPLIANT` | `/etc/pam.d/password-auth` | `pam_faillock.so deny` | deny ≤ 5 | deny > 5 or not set |
| 167 | Dictionary check enabled | `COMPLIANT` | `/etc/security/pwquality.conf` | `dictcheck` parameter | dictcheck = 1 | dictcheck = 0 or missing |
| 176 | Password expiration | `NOT COMPLIANT` | `/etc/login.defs` | `PASS_MAX_DAYS` | PASS_MAX_DAYS ≤ 365 | PASS_MAX_DAYS > 365 |
| 177 | Expiration warning | `COMPLIANT` | `/etc/login.defs` | `PASS_WARN_AGE` | PASS_WARN_AGE ≥ 7 | PASS_WARN_AGE < 7 |

---

## 🔍 How to Read Test Results

### Example Console Output:
```
========================================
SCAN MONITORING COMPLETE
Previous Status: running
Final Status: finished
Total Time: 245 seconds
========================================

Vulnerability Count: 85
```

**What this means:**
- The scan completed successfully
- Found **85 configuration issues** (vulnerabilities)
- These are rules where the system is `NOT COMPLIANT`
- Each vulnerability corresponds to a specific benchmark rule

### Example Validation:
```robotframework
# Check if password dictionary check is compliant
${rule_163}=    Get Rule Result    5.3.3.2.6
Should Be Equal    ${rule_163}    COMPLIANT

# ✅ PASS: System has dictionary check enabled
```

```robotframework
# Check if password length is configured
${rule_163}=    Get Rule Result    5.3.3.2.2
Should Be Equal    ${rule_163}    NOT COMPLIANT

# ❌ FAIL: System does NOT have proper password length configured
# This is expected for this baseline - it's intentionally non-compliant
```

---

## 💡 Key Takeaways for the Team

1. **COMPLIANT = PASS** ✅
   - System meets security requirements
   - No vulnerability reported

2. **NOT COMPLIANT = FAIL** ❌
   - System does NOT meet security requirements
   - Reported as a vulnerability in scan

3. **INFORMATIONAL = MANUAL REVIEW** ℹ️
   - Cannot be automatically determined
   - Requires human assessment

4. **Test Expectation Matters** 🎯
   - If CSV says `NOT COMPLIANT` and scan finds `NOT COMPLIANT` → Test PASSES
   - If CSV says `COMPLIANT` and scan finds `NOT COMPLIANT` → Test FAILS
   - The CSV file defines your **baseline expectation**

5. **Vulnerability Count = Total NOT COMPLIANT Rules** 📊
   - Zero vulnerabilities = All rules are COMPLIANT
   - Non-zero = Number of rules that are NOT COMPLIANT

---

## 🚀 Running the Example

To see this in action:
```bash
cd /Users/msykam/poc_robot_framework
robot -d results tests/ubuntubenchmark3.0.0.robot
```

**Watch for:**
- Lines showing "Ensure_password_length_is_configured"
- Final vulnerability count
- Validation against the CSV baseline

---

## 📞 Questions?

This example uses password policies because they're easy to understand:
- **Clear requirement:** "Password must be 14+ characters"
- **Easy to verify:** Check a configuration file
- **Clear pass/fail:** Either it's set correctly or it isn't

The same logic applies to **all 200+ benchmark rules** - firewall settings, file permissions, service configurations, etc.
