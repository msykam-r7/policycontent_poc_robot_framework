# Quick Reference: Get Benchmark ID and Policies

## 🚀 Quick Start (Copy & Paste)

### Basic Usage
```robotframework
# Import required resource
Resource    ../resources/scan_template_api.robot

# Get benchmark info
${benchmark}=    Get Benchmark ID And Policies For OS    
...    cis    
...    Red Hat Enterprise Linux 9 STIG    
...    1.0.0

# Use the data
Log    Benchmark ID: ${benchmark}[benchmark_id]
Log    Policies: ${benchmark}[policies]
Log    Policy Count: ${benchmark}[policy_count]
```

---

## 📋 What You Get Back

When you call `Get Benchmark ID And Policies For OS`, you receive a dictionary with:

| Key | Description | Example Value |
|-----|-------------|---------------|
| `benchmark_id` | Full benchmark identifier | `xccdf_org.cisecurity.benchmarks_benchmark_CIS_Red_Hat_Enterprise_Linux_9_STIG_Benchmark` |
| `os` | Operating system name | `Red Hat Enterprise Linux 9 STIG` |
| `version` | OS version | `1.0.0` |
| `policies` | List of policy IDs | `['Level-I', 'Level-II', ...]` |
| `policy_count` | Number of policies | `12` |
| `deprecated` | Deprecated versions (if any) | `['0.9.0', '0.8.0']` |

---

## 💡 Usage in Your Test

### Replace This (Complex):
```robotframework
# Your current approach
${template_result}=    Process Template For OS    cis    Red Hat Enterprise Linux 9 STIG    1.0.0    all    ${site_name}
# Now you have to dig through template_result to find benchmark info
```

### With This (Simple):
```robotframework
# Step 1: Get benchmark info separately
${benchmark}=    Get Benchmark ID And Policies For OS    cis    Red Hat Enterprise Linux 9 STIG    1.0.0

Log    Found ${benchmark}[policy_count] policies for ${benchmark}[os]

# Step 2: Then process template if needed
${template_result}=    Process Template For OS    cis    Red Hat Enterprise Linux 9 STIG    1.0.0    all    ${site_name}
```

---

## 🎯 Common Scenarios

### 1. Get Benchmark for Specific OS + Version
```robotframework
${benchmark}=    Get Benchmark ID And Policies For OS    cis    Ubuntu 20.04    3.0.0
```

### 2. Get Benchmark for OS (Latest Version)
```robotframework
${benchmark}=    Get Benchmark ID And Policies For OS    cis    Ubuntu 20.04
# Returns first matching benchmark (usually latest)
```

### 3. List All Available OS
```robotframework
${all}=    Get Policies For OS    cis    all
FOR    ${b}    IN    @{all}
    Log    ${b}[os] ${b}[version]
END
```

### 4. Check Available Policies
```robotframework
${benchmark}=    Get Benchmark ID And Policies For OS    cis    Red Hat Enterprise Linux 9 STIG    1.0.0
FOR    ${policy}    IN    @{benchmark}[policies]
    Log    Available policy: ${policy}
END
```

---

## 🔧 Integration Example

Here's how to integrate into your existing test (`ubuntubenchmark3.0.0.robot`):

```robotframework
*** Test Cases ***
COMPLIANT CIS Ubuntu 20.04 Benchmark
    # Login
    ${session_id}=    Login To Console
    
    # Get engines
    ${engine_ids}=    Get Available Engines
    ${engine_id}=    Set Variable If    ${engine_count} > 0    ${engine_ids}[0]    3
    
    # Generate site name
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${site_name}=    Set Variable    Red Hat Enterprise Linux 9 STIG ${timestamp}
    
    # 🆕 NEW: Get benchmark ID and policies FIRST
    ${benchmark}=    Get Benchmark ID And Policies For OS    
    ...    cis    
    ...    Red Hat Enterprise Linux 9 STIG    
    ...    1.0.0
    
    Log    ========================================    console=True
    Log    Benchmark: ${benchmark}[benchmark_id]    console=True
    Log    Policies: ${benchmark}[policies]    console=True
    Log    Policy Count: ${benchmark}[policy_count]    console=True
    Log    ========================================    console=True
    
    # Continue with existing code
    ${template_result}=    Process Template For OS    
    ...    cis    
    ...    Red Hat Enterprise Linux 9 STIG    
    ...    1.0.0    
    ...    all    
    ...    ${site_name}
    
    # ... rest of your test
```

---

## 📁 Files to Use

| File | Purpose |
|------|---------|
| `resources/scan_template_api.robot` | Contains the keyword (already modified) |
| `tests/simple_benchmark_example.robot` | Simple working examples |
| `tests/get_benchmark_example.robot` | Detailed examples |
| `library/benchmark_policy_helper.py` | Python library (optional) |

---

## 🏃 Run Examples

```bash
# Run simple example
robot tests/simple_benchmark_example.robot

# Run detailed examples
robot tests/get_benchmark_example.robot

# Run specific test case
robot -t "Simple Benchmark Lookup Example" tests/simple_benchmark_example.robot
```

---

## ⚠️ Prerequisites

1. Must call `Login To Console` first
2. Template data must exist (auto-fetched if missing)

---

## 📞 Help

See detailed documentation in `GET_BENCHMARK_GUIDE.md`
