# Validation Rules Organization

This directory contains CSV files with validation rules organized by:
- **Benchmark Type** (CIS, DISA, etc.)
- **Operating System** (RHEL9, Ubuntu20, Windows2019, etc.)
- **Profile/Level** (level1_server, level2_workstation, stig_baseline, etc.)

## 📁 Directory Structure

```
validation_rules/
├── CIS/
│   ├── RHEL9/
│   │   ├── level1_server.csv
│   │   ├── level1_workstation.csv
│   │   ├── level2_server.csv
│   │   └── level2_workstation.csv
│   ├── Ubuntu20/
│   │   ├── level1_server.csv
│   │   ├── level1_workstation.csv
│   │   └── level2_server.csv
│   ├── Windows2019/
│   │   ├── level1_domain.csv
│   │   └── level1_member_server.csv
│   └── Oracle19c/
│       └── level1_rdbms.csv
├── DISA/
│   ├── RHEL9/
│   │   └── stig_baseline.csv
│   ├── Ubuntu20/
│   │   └── stig_baseline.csv
│   └── Windows2019/
│       └── stig_baseline.csv
└── README.md (this file)
```

## 📝 CSV File Format

Each CSV file must have these columns:

| Column | Required | Description |
|--------|----------|-------------|
| NUMBER | Yes | Sequential rule number (1, 2, 3...) |
| RULE_ID | Yes | Full XCCDF rule identifier |
| EXPECTED_RESULT | Yes | Expected result (COMPLIANT, NOT COMPLIANT, etc.) |
| DESCRIPTION | No | Human-readable description |

## 🎯 Naming Convention

**File names should be lowercase with underscores:**

- `level1_server.csv` - CIS Level 1 Server profile
- `level1_workstation.csv` - CIS Level 1 Workstation profile
- `level2_server.csv` - CIS Level 2 Server profile
- `stig_baseline.csv` - DISA STIG baseline
- `custom_profile.csv` - Custom validation profile

## 🚀 Usage Examples

### Example 1: Validate RHEL 9 CIS Level 1 Server
```robot
${rules_file}=    Set Variable    ${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv

${passed}    ${failed}    ${results}=    Validate Report From Excel
    ...    excel_path=${rules_file}
    ...    xml_content=${report_content}
    ...    file_type=csv
```

### Example 2: Validate Ubuntu 20 DISA STIG
```robot
${rules_file}=    Set Variable    ${EXECDIR}/testdata/validation_rules/DISA/Ubuntu20/stig_baseline.csv

${passed}    ${failed}    ${results}=    Validate Report From Excel
    ...    excel_path=${rules_file}
    ...    xml_content=${report_content}
    ...    file_type=csv
```

### Example 3: Data-Driven Testing (Test Multiple Profiles)
```robot
*** Test Cases ***
Validate Multiple Profiles
    [Template]    Validate Profile
    CIS    RHEL9    level1_server
    CIS    RHEL9    level1_workstation
    CIS    RHEL9    level2_server
    DISA   RHEL9    stig_baseline

*** Keywords ***
Validate Profile
    [Arguments]    ${benchmark}    ${os}    ${profile}
    ${rules_file}=    Set Variable    ${EXECDIR}/testdata/validation_rules/${benchmark}/${os}/${profile}.csv
    # ... generate report, download, validate ...
```

## 📊 Benefits of This Structure

1. **Organized by Context** - Easy to find rules for specific OS/profile combinations
2. **Scalable** - Add new OS or profiles by adding new directories/files
3. **Maintainable** - Each CSV file is focused on one specific profile
4. **Reusable** - Same structure works for CIS, DISA, PCI-DSS, HIPAA, etc.
5. **Version Controlled** - Track changes to validation rules over time
6. **Business-Friendly** - Non-technical users can edit CSV files in Excel

## 🔧 Maintenance Tips

1. **Keep files focused** - One CSV per profile, don't mix profiles
2. **Use consistent naming** - Follow the naming convention
3. **Document changes** - Add comments in git commits when updating rules
4. **Regular updates** - When benchmark versions change, update corresponding CSV
5. **Validate CSV format** - Ensure all required columns are present
