# Multi-OS Multi-Profile Validation Strategy

This guide provides recommendations for validating CIS/DISA benchmarks across multiple operating systems and profiles efficiently.

## 🎯 Problem Statement

When validating compliance reports, you face:
- **Multiple OS Types**: RHEL, Ubuntu, Windows, Oracle, etc.
- **Multiple Benchmarks**: CIS, DISA STIG, PCI-DSS, HIPAA, etc.
- **Multiple Profiles**: Level 1/2, Server/Workstation, Domain Controller, etc.
- **Hundreds of Rules**: Each profile can have 50-500+ individual rules

**Challenge**: How to organize and maintain validation rules efficiently?

---

## ✅ Recommended Solution: Hierarchical CSV Structure

### 📁 Directory Organization

```
testdata/validation_rules/
├── CIS/
│   ├── RHEL9/
│   │   ├── level1_server.csv          # CIS RHEL 9 L1 Server (50-100 rules)
│   │   ├── level1_workstation.csv     # CIS RHEL 9 L1 Workstation
│   │   ├── level2_server.csv          # CIS RHEL 9 L2 Server (150-300 rules)
│   │   └── level2_workstation.csv     # CIS RHEL 9 L2 Workstation
│   ├── Ubuntu20/
│   │   ├── level1_server.csv
│   │   ├── level1_workstation.csv
│   │   └── level2_server.csv
│   ├── Windows2019/
│   │   ├── level1_domain_controller.csv
│   │   ├── level1_member_server.csv
│   │   └── level2_member_server.csv
│   └── Oracle19c/
│       ├── level1_rdbms.csv
│       └── level2_rdbms.csv
├── DISA/
│   ├── RHEL9/
│   │   └── stig_baseline.csv          # DISA STIG (200-400 rules)
│   ├── Ubuntu20/
│   │   └── stig_baseline.csv
│   └── Windows2019/
│       └── stig_baseline.csv
├── PCI-DSS/
│   └── ... (similar structure)
└── README.md
```

### 📊 CSV File Format (Standard Across All Files)

```csv
NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs...,COMPLIANT,Ensure cramfs kernel module
2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs...,COMPLIANT,Ensure freevxfs kernel module
3,xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs...,NOT COMPLIANT,Ensure hfs kernel module
```

---

## 🚀 Implementation Approaches

### **Approach 1: Individual Test Cases (Recommended for Clarity)**

```robot
*** Test Cases ***
Validate CIS RHEL9 Level 1 Server
    [Tags]    cis    rhel9    level1    server
    Validate Benchmark Policy
    ...    site_id=61
    ...    policy_id=xccdf_org.cisecurity...Level_1_-_Server
    ...    rules_file=CIS/RHEL9/level1_server.csv
    ...    benchmark_name=CIS RHEL 9 Level 1 Server

Validate CIS RHEL9 Level 2 Server
    [Tags]    cis    rhel9    level2    server
    Validate Benchmark Policy
    ...    site_id=62
    ...    policy_id=xccdf_org.cisecurity...Level_2_-_Server
    ...    rules_file=CIS/RHEL9/level2_server.csv
    ...    benchmark_name=CIS RHEL 9 Level 2 Server

Validate DISA RHEL9 STIG
    [Tags]    disa    rhel9    stig
    Validate Benchmark Policy
    ...    site_id=63
    ...    policy_id=xccdf_mil.disa.stig...
    ...    rules_file=DISA/RHEL9/stig_baseline.csv
    ...    benchmark_name=DISA RHEL 9 STIG
```

**Benefits**:
- ✅ Clear test names in reports
- ✅ Easy to run specific tests using tags: `robot --include rhel9 tests/`
- ✅ Each test is independent
- ✅ Good for CI/CD pipelines

**Run specific tests**:
```bash
# Run all RHEL9 tests
robot --include rhel9 tests/validate_multiple_benchmarks.robot

# Run only CIS Level 1 tests
robot --include level1 tests/validate_multiple_benchmarks.robot

# Run CIS RHEL9 Server tests
robot --include "cis AND rhel9 AND server" tests/validate_multiple_benchmarks.robot
```

---

### **Approach 2: Template-Based (For Many Similar Tests)**

```robot
*** Settings ***
Test Template    Validate Benchmark Policy

*** Test Cases ***    SITE_ID    POLICY_ID    RULES_FILE    BENCHMARK_NAME
CIS RHEL9 L1 Server    61    xccdf_org...Level_1_-_Server    CIS/RHEL9/level1_server.csv    CIS RHEL 9 L1 Server
CIS RHEL9 L2 Server    62    xccdf_org...Level_2_-_Server    CIS/RHEL9/level2_server.csv    CIS RHEL 9 L2 Server
CIS Ubuntu20 L1 Server    63    xccdf_org...Level_1_-_Server    CIS/Ubuntu20/level1_server.csv    CIS Ubuntu 20 L1 Server
DISA RHEL9 STIG    64    xccdf_mil...MAC-1_Classified    DISA/RHEL9/stig_baseline.csv    DISA RHEL 9 STIG
```

**Benefits**:
- ✅ Very compact - all tests in one table
- ✅ Easy to add new tests (just add a row)
- ✅ Data-driven approach

---

### **Approach 3: Loop-Based (For Dynamic Test Generation)**

```robot
*** Test Cases ***
Validate All RHEL9 Benchmarks
    [Documentation]    Dynamically validate all RHEL9 profiles
    
    @{rhel9_profiles}=    Create List
    ...    CIS/RHEL9/level1_server.csv
    ...    CIS/RHEL9/level1_workstation.csv
    ...    CIS/RHEL9/level2_server.csv
    ...    DISA/RHEL9/stig_baseline.csv
    
    FOR    ${profile}    IN    @{rhel9_profiles}
        ${benchmark_name}=    Get Benchmark Name From Path    ${profile}
        Validate Benchmark Policy
        ...    site_id=61
        ...    policy_id=${POLICY_MAP}[${profile}]
        ...    rules_file=${profile}
        ...    benchmark_name=${benchmark_name}
    END
```

**Benefits**:
- ✅ One test runs multiple validations
- ✅ Good for nightly regression testing
- ⚠️ Harder to identify which specific profile failed

---

## 📋 Maintenance Workflow

### 1. **Adding a New OS**

```bash
# Create directory structure
mkdir -p testdata/validation_rules/CIS/RHEL10

# Create CSV files for each profile
# Copy from similar OS and modify rule IDs
cp testdata/validation_rules/CIS/RHEL9/level1_server.csv \
   testdata/validation_rules/CIS/RHEL10/level1_server.csv

# Update rule IDs in the CSV
# Update test file to add new test case
```

### 2. **Adding a New Profile**

```bash
# Create new CSV file
touch testdata/validation_rules/CIS/RHEL9/level3_server.csv

# Populate with rules (see "Getting Rule IDs" below)

# Add new test case in Robot file
```

### 3. **Updating Rule Expectations**

Just edit the CSV file - no code changes needed!

```csv
# Before: Expected COMPLIANT
3,xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs...,COMPLIANT,Ensure hfs

# After: Expected NOT COMPLIANT (e.g., known issue in environment)
3,xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs...,NOT COMPLIANT,Ensure hfs
```

---

## 🔍 Getting Rule IDs for CSV Files

### Method 1: Extract from XCCDF Report (Automated)

```robot
*** Keywords ***
Extract All Rule IDs From Report
    [Arguments]    ${xml_content}    ${output_csv}
    
    # Parse XML
    ${root}=    Parse XML    ${xml_content}
    
    # Find all rule-result elements
    @{rule_results}=    Get Elements    ${root}    .//rule-result
    
    # Create CSV
    ${csv_content}=    Set Variable    NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION\n
    
    ${index}=    Set Variable    ${1}
    FOR    ${rule_result}    IN    @{rule_results}
        ${rule_id}=    Get Element Attribute    ${rule_result}    idref
        ${result_elem}=    Get Element    ${rule_result}    .//result
        ${actual_result}=    Get Element Text    ${result_elem}
        
        ${csv_content}=    Catenate    SEPARATOR=\n    ${csv_content}
        ...    ${index},${rule_id},COMPLIANT,Auto-generated description
        
        ${index}=    Evaluate    ${index} + 1
    END
    
    Create File    ${output_csv}    ${csv_content}
```

### Method 2: From CIS/DISA PDF Documentation

1. Download the benchmark PDF
2. Extract rule IDs from the document
3. Build CSV manually or semi-automatically

### Method 3: From Nexpose UI

1. View policy in Nexpose console
2. Export policy details
3. Parse and convert to CSV format

---

## 🎯 Best Practices

### ✅ DO:

1. **One CSV per profile** - Don't mix Level 1 and Level 2 rules in same file
2. **Use descriptive file names** - `level1_server.csv`, not `rules1.csv`
3. **Keep CSV in version control** - Track changes to validation expectations
4. **Add meaningful descriptions** - Helps when reviewing failures
5. **Use tags extensively** - Makes selective test runs easy
6. **Start small** - Begin with critical rules, expand coverage over time

### ❌ DON'T:

1. **Don't hardcode rules in Robot files** - Always use CSV files
2. **Don't duplicate rules** - If same rule appears in multiple profiles, consider a shared CSV
3. **Don't ignore CSV validation** - Ensure CSV format is correct before running tests
4. **Don't commit sensitive data** - CSVs should contain rule IDs, not actual system data

---

## 📊 Reporting Strategy

### Individual Test Reports

```bash
# Run single benchmark
robot --outputdir results/rhel9_l1 tests/validate_multiple_benchmarks.robot::Validate CIS RHEL9 Level 1 Server
```

### Combined Report Dashboard

```bash
# Run all benchmarks, combine reports
robot --outputdir results/all tests/validate_multiple_benchmarks.robot

# Generate merged report (if using multiple test files)
rebot --outputdir results/combined results/*/output.xml
```

### CI/CD Integration

```yaml
# Example Jenkins/GitLab CI
stages:
  - validate_cis_rhel9
  - validate_cis_ubuntu
  - validate_disa

validate_cis_rhel9:
  script:
    - robot --include "cis AND rhel9" tests/validate_multiple_benchmarks.robot
  artifacts:
    paths:
      - results/
```

---

## 🔧 Advanced: Shared Rules

Some rules appear across multiple profiles (e.g., Level 1 rules are subset of Level 2).

### Option A: Separate Files (Recommended)
Keep separate CSVs for each profile, even if there's duplication. Easier to maintain.

### Option B: Shared Base File + Profile-Specific
```
CIS/RHEL9/
  ├── base_level1.csv           # 50 rules
  ├── level1_server.csv          # References base + adds 10 server-specific
  ├── level2_server.csv          # References base + level1 + adds 150 more
```

Requires custom keyword to merge CSVs - more complex but reduces duplication.

---

## 📈 Scalability

This structure scales well:

- **10 OS types** × **5 profiles each** = **50 CSV files**
- **Average 100 rules per CSV** = **5,000 total rules**
- **All organized**, **easy to find**, **easy to maintain**

---

## 🎓 Summary

**Recommended Approach**:
1. ✅ Use hierarchical folder structure: `Benchmark/OS/profile.csv`
2. ✅ One CSV file per OS+Profile combination
3. ✅ Use Approach 1 (individual test cases) for clarity
4. ✅ Use tags for flexible test selection
5. ✅ Keep CSVs in version control
6. ✅ Start with critical rules, expand coverage iteratively

**Result**: Maintainable, scalable, business-friendly validation framework!

---

## 📚 Files Created for You

I've created:
- ✅ Directory structure in `testdata/validation_rules/`
- ✅ Sample CSV files for RHEL9 and Ubuntu20 (CIS and DISA)
- ✅ Example test file: `tests/validate_multiple_benchmarks.robot`
- ✅ Documentation: `testdata/validation_rules/README.md`

**Next Steps**:
1. Review the sample CSV files
2. Add your actual rule IDs to the CSVs
3. Run the example test to verify it works
4. Expand to additional OS/profiles as needed
