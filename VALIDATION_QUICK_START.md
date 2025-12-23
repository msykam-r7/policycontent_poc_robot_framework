# Quick Start: Multi-Benchmark Validation

## 🎯 Solution Overview

**Structure**: Organize validation rules by Benchmark → OS → Profile
```
testdata/validation_rules/
├── CIS/RHEL9/level1_server.csv
├── CIS/Ubuntu20/level1_server.csv
├── DISA/RHEL9/stig_baseline.csv
└── ...
```

## 🚀 3-Step Quick Start

### Step 1: Create Your CSV File

**Option A - From Downloaded Report (Automated)**
```bash
# Run your test once to get an XCCDF report, then:
python library/extract_rules_from_report.py \
    path/to/downloaded_report.xml \
    testdata/validation_rules/CIS/RHEL9/level1_server.csv
```

**Option B - Manual Creation**
```csv
NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs...,COMPLIANT,Cramfs module check
2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs...,COMPLIANT,Freevxfs check
```

### Step 2: Create/Update Test File

```robot
*** Settings ***
Resource    ../resources/report_operations.robot

*** Variables ***
${RULES_FILE}    ${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv

*** Test Cases ***
Validate My Benchmark
    # ... login, generate report, download report ...
    
    ${passed}    ${failed}    ${results}=    Validate Report From Excel
    ...    excel_path=${RULES_FILE}
    ...    xml_content=${report_content}
    ...    file_type=csv
    
    Should Be Equal As Integers    ${failed}    0
```

### Step 3: Run Test

```bash
robot tests/validate_multiple_benchmarks.robot
```

## 📁 File Organization Examples

### Example 1: CIS Benchmarks
```
validation_rules/CIS/
├── RHEL9/
│   ├── level1_server.csv
│   ├── level1_workstation.csv
│   ├── level2_server.csv
│   └── level2_workstation.csv
├── Ubuntu20/
│   ├── level1_server.csv
│   └── level2_server.csv
└── Windows2019/
    ├── level1_domain_controller.csv
    └── level1_member_server.csv
```

### Example 2: DISA STIGs
```
validation_rules/DISA/
├── RHEL9/
│   └── stig_baseline.csv
├── Ubuntu20/
│   └── stig_baseline.csv
└── Windows2019/
    └── stig_baseline.csv
```

## 🎯 Running Tests Selectively

```bash
# Run all RHEL9 tests
robot --include rhel9 tests/validate_multiple_benchmarks.robot

# Run only Level 1 tests
robot --include level1 tests/validate_multiple_benchmarks.robot

# Run CIS RHEL9 Server tests
robot --include "cis AND rhel9 AND server" tests/validate_multiple_benchmarks.robot

# Run specific test
robot tests/validate_multiple_benchmarks.robot::Validate\ CIS\ RHEL9\ Level\ 1\ Server
```

## 📝 Maintenance Workflows

### Update Expected Results
```bash
# Just edit the CSV file - no code changes!
vim testdata/validation_rules/CIS/RHEL9/level1_server.csv

# Change:
# 3,xccdf_...rule_1.1.1.3...,COMPLIANT,Description
# To:
# 3,xccdf_...rule_1.1.1.3...,NOT COMPLIANT,Description
```

### Add New Profile
```bash
# 1. Create new CSV
cp testdata/validation_rules/CIS/RHEL9/level1_server.csv \
   testdata/validation_rules/CIS/RHEL9/level3_server.csv

# 2. Update CSV with new rules
vim testdata/validation_rules/CIS/RHEL9/level3_server.csv

# 3. Add test case in Robot file (see test file examples)
```

### Add New OS
```bash
# 1. Create directory
mkdir -p testdata/validation_rules/CIS/RHEL10

# 2. Copy and modify CSV
cp testdata/validation_rules/CIS/RHEL9/level1_server.csv \
   testdata/validation_rules/CIS/RHEL10/level1_server.csv

# 3. Update rule IDs in CSV
```

## 🔧 Helper Tools

### Extract Rules from Existing Report
```bash
# Download a report first, then extract all rules
python library/extract_rules_from_report.py \
    downloaded_report.xml \
    testdata/validation_rules/CIS/MyOS/my_profile.csv
```

### Validate CSV Format
```bash
# Check if CSV has required columns
head -1 testdata/validation_rules/CIS/RHEL9/level1_server.csv

# Should show:
# NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
```

## 📊 Understanding Output

```
================================================================================
VALIDATION SUMMARY
================================================================================
Total Rules: 5
Passed: 4 ✓
Failed: 1 ✗
Success Rate: 80.0%
================================================================================

#    | STATUS | EXPECTED        | ACTUAL          | DESCRIPTION
-----+--------+-----------------+-----------------+------------------------------
1    | PASS   | COMPLIANT       | COMPLIANT       | Ensure cramfs kernel module
2    | PASS   | COMPLIANT       | COMPLIANT       | Ensure freevxfs kernel module
3    | FAIL   | COMPLIANT       | NOT COMPLIANT   | Ensure hfs kernel module
4    | PASS   | COMPLIANT       | COMPLIANT       | Ensure jffs2 kernel module
5    | PASS   | COMPLIANT       | COMPLIANT       | Ensure udf kernel module
================================================================================
```

## ⚠️ Common Issues

### "CSV file not found"
```bash
# Check path - should be relative to workspace root
ls -la testdata/validation_rules/CIS/RHEL9/level1_server.csv

# Or use absolute path
${RULES_FILE}    /full/path/to/file.csv
```

### "Missing required header: RULE_ID"
```bash
# Ensure CSV has correct headers (case-sensitive):
# NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
```

### "Rule not found in XCCDF report"
```bash
# Verify rule ID matches exactly what's in XCCDF XML
# Check if rule was actually scanned (some may be excluded)
```

## 📚 Full Documentation

- **Comprehensive Guide**: `MULTI_BENCHMARK_VALIDATION_GUIDE.md`
- **Excel Validation**: `EXCEL_VALIDATION_GUIDE.md`
- **Rules Directory README**: `testdata/validation_rules/README.md`

## 🎓 Best Practices

1. ✅ **One CSV per profile** - Keep files focused
2. ✅ **Use descriptive names** - `level1_server.csv`, not `rules.csv`
3. ✅ **Version control CSVs** - Track changes over time
4. ✅ **Start small** - Begin with critical rules, expand later
5. ✅ **Use tags** - Makes selective testing easy
6. ✅ **Document changes** - Add git commit messages when updating rules

## 💡 Pro Tips

- Use `extract_rules_from_report.py` to bootstrap CSV files
- Keep backup copies of CSV files before major changes
- Use Excel/LibreOffice for easier CSV editing (but save as CSV!)
- Test CSVs individually before running full suite
- Export CSVs from compliance tracking systems if available

---

**Ready to start?** See `tests/validate_multiple_benchmarks.robot` for working examples!
