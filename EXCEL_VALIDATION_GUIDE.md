# Excel-Based XCCDF Report Validation

This guide explains how to validate XCCDF compliance reports using Excel or CSV files containing your expected rules.

## 📋 Overview

Instead of hardcoding validation rules in Robot Framework test files, you can now:
1. Define expected rules in an **Excel (.xlsx)** or **CSV** file
2. Load rules automatically during test execution
3. Validate downloaded XCCDF reports against your rules
4. Get detailed pass/fail reports with summaries

## 📁 File Structure

```
poc_robot_framework/
├── testdata/
│   ├── rhel9_rules.csv          # Sample CSV with validation rules
│   └── rhel9_rules.xlsx         # Sample Excel (you can create this)
├── library/
│   └── excel_validator.py       # Python library for validation
├── resources/
│   └── report_operations.robot  # Contains "Validate Report From Excel" keyword
└── tests/
    └── validate_report_from_excel.robot  # Example test using Excel validation
```

## 📝 Excel/CSV File Format

Your Excel or CSV file should have these columns:

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| **NUMBER** | Yes | Sequential rule number | 1, 2, 3... |
| **RULE_ID** | Yes | Full XCCDF rule identifier | `xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs...` |
| **EXPECTED_RESULT** | Yes | Expected compliance result | `COMPLIANT`, `NOT COMPLIANT`, `NOT APPLICABLE` |
| **DESCRIPTION** | No | Human-readable description | `Ensure cramfs kernel module is not available` |

### Sample CSV Format
```csv
NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs_kernel_module_is_not_available,COMPLIANT,Ensure cramfs kernel module is not available
2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs_kernel_module_is_not_available,COMPLIANT,Ensure freevxfs kernel module is not available
3,xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs_kernel_module_is_not_available,COMPLIANT,Ensure hfs kernel module is not available
```

### Sample Excel Format
Same columns as CSV, but in Excel:

| NUMBER | RULE_ID | EXPECTED_RESULT | DESCRIPTION |
|--------|---------|-----------------|-------------|
| 1 | xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs... | COMPLIANT | Ensure cramfs kernel module is not available |
| 2 | xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs... | COMPLIANT | Ensure freevxfs kernel module is not available |
| 3 | xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs... | COMPLIANT | Ensure hfs kernel module is not available |

## 🎯 Valid Expected Results

These are the valid values for the **EXPECTED_RESULT** column:

- `COMPLIANT` - Rule passed compliance check
- `NOT COMPLIANT` - Rule failed compliance check
- `NOT APPLICABLE` - Rule not applicable to this system
- `NOT CHECKED` - Rule was not checked
- `NOT SELECTED` - Rule was not selected for scanning
- `INFORMATIONAL` - Informational result only
- `ERROR` - Error occurred during check
- `UNKNOWN` - Unknown result
- `FIXED` - Issue was fixed

## 🚀 How to Use

### Option 1: CSV File (Recommended for simplicity)

1. **Create your CSV file** at `testdata/your_rules.csv`:
```csv
NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs_kernel_module_is_not_available,COMPLIANT,Cramfs module check
2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs_kernel_module_is_not_available,COMPLIANT,Freevxfs module check
```

2. **Run the test**:
```bash
robot tests/validate_report_from_excel.robot
```

3. **Modify test to use your CSV** (in `tests/validate_report_from_excel.robot`):
```robot
*** Variables ***
${RULES_FILE}    ${EXECDIR}/testdata/your_rules.csv
```

### Option 2: Excel File

1. **Install required Python library**:
```bash
pip install openpyxl
```

2. **Create Excel file** with same column structure as CSV

3. **Update test to use Excel**:
```robot
*** Variables ***
${RULES_FILE}    ${EXECDIR}/testdata/your_rules.xlsx

*** Test Cases ***
Your Test
    # ... other steps ...
    
    ${passed}    ${failed}    ${results}=    report_operations.Validate Report From Excel
    ...    excel_path=${RULES_FILE}
    ...    xml_content=${report_content}
    ...    file_type=excel    # Changed from 'csv' to 'excel'
```

## 📊 Validation Output

When you run the test, you'll see output like this:

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

❌ FAILED RULES DETAIL:
Rule #3: ✗ Mismatch: Expected COMPLIANT, Got NOT COMPLIANT
- Rule ID: xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_Ensure_hfs_kernel_module_is_not_available
- Expected: COMPLIANT
- Actual: NOT COMPLIANT
---
```

## 🔧 Advanced Usage

### Use in Your Own Test

```robot
*** Settings ***
Resource    ../resources/report_operations.robot

*** Variables ***
${RULES_CSV}    ${EXECDIR}/testdata/my_validation_rules.csv

*** Test Cases ***
My Custom Validation Test
    # ... login, generate report, download report ...
    
    # ${report_content} should contain the XCCDF XML
    
    ${passed}    ${failed}    ${results}=    report_operations.Validate Report From Excel
    ...    excel_path=${RULES_CSV}
    ...    xml_content=${report_content}
    ...    file_type=csv
    
    # Assert all rules passed
    Should Be Equal As Integers    ${failed}    0
    ...    msg=Validation failed: ${failed} rule(s) did not match expected results
```

### Python API Usage

You can also use the Python library directly:

```python
from library.excel_validator import ExcelValidator

# Create validator
validator = ExcelValidator()

# Load rules from CSV
rules = validator.load_rules_from_csv('testdata/rhel9_rules.csv')

# Or load from Excel
# rules = validator.load_rules_from_excel('testdata/rhel9_rules.xlsx')

# Validate report
with open('downloaded_report.xml', 'r') as f:
    xml_content = f.read()

passed, failed, results = validator.validate_xccdf_report(xml_content)

# Get summary
print(validator.get_validation_summary())

# Get only failed rules
failed_rules = validator.get_failed_rules()
for rule in failed_rules:
    print(f"Failed: {rule['description']} - {rule['message']}")
```

## 📝 Tips

1. **Keep CSV Simple**: CSV files are easier to edit and version control than Excel
2. **One File Per Policy**: Create separate CSV files for different policies/benchmarks
3. **Use Descriptions**: Add meaningful descriptions to help identify rules quickly
4. **Version Control**: Commit your CSV files to track changes in expected compliance
5. **Update Rules**: When compliance requirements change, just update the CSV - no code changes needed!

## 🆘 Troubleshooting

### "Module 'openpyxl' not found"
Install it: `pip install openpyxl`

### "CSV file not found"
Check the path in `${RULES_FILE}` variable - use `${EXECDIR}` for workspace-relative paths

### "Missing required header: RULE_ID"
Make sure your CSV/Excel has all required columns: NUMBER, RULE_ID, EXPECTED_RESULT

### "Rule not found in XCCDF report"
- Verify the RULE_ID exactly matches what's in the XCCDF XML
- Check if the rule was actually scanned (some rules may be excluded)

## 📚 Example Test File

See `tests/validate_report_from_excel.robot` for a complete working example!

## 🎓 Summary

**Benefits of Excel/CSV validation:**
- ✅ No code changes needed to update validation rules
- ✅ Business users can maintain the rules list
- ✅ Easy to add/remove/modify rules
- ✅ Clear tabular format
- ✅ Can be exported from other systems
- ✅ Version controlled alongside test code
- ✅ Detailed pass/fail reporting with summaries
