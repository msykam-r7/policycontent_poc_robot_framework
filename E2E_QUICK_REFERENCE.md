# E2E Framework Quick Reference Card

## 🚀 Quick Start (3 Steps)

1. **Choose a test** from `tests/e2e_benchmark_testing.robot`
2. **Run it**: `robot --outputdir results tests/e2e_benchmark_testing.robot`
3. **Check results** in console output and HTML report

## 📝 Create Custom Test (5 Lines)

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS    os_name=Ubuntu    version=20.04
...    profile=Level 1 - Server    scan_template=cis
...    service=ssh    scope=S    site_name=My_Site_${timestamp}
...    template_name=My_Template_${timestamp}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/Ubuntu20/level1_server.csv
```

## 🎯 Core Keyword

```robotframework
Run Complete E2E Benchmark Test
```
→ Executes all 10 workflow steps
→ Returns comprehensive results dictionary
→ Includes CSV validation

## 📋 Required Parameters (10)

| Parameter | Example | Description |
|-----------|---------|-------------|
| `benchmark` | `CIS` | Benchmark framework |
| `os_name` | `Red Hat Enterprise Linux 9` | OS name |
| `version` | `2.0.0` | Version |
| `profile` | `Level 1 - Server` | Compliance profile |
| `scan_template` | `cis` | Template type |
| `service` | `ssh` | Service type |
| `scope` | `S` | Scope identifier |
| `site_name` | `RHEL9_Site_123456` | Site name |
| `template_name` | `RHEL9_Template_123456` | Template name |
| `csv_file` | `${EXECDIR}/testdata/.../file.csv` | Validation CSV path |

## 🔧 Optional Parameters (6)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `policy_list` | `all` | Policies to include |
| `db_required` | `${FALSE}` | Database credentials needed |
| `engine_id` | Auto-select | Specific engine ID |
| `site_id` | Create new | Existing site ID to update |
| `validate_compliance` | `${TRUE}` | Enable compliance validation |
| `expected_vuln_count` | `0` | Expected vuln count |

## 📊 Return Dictionary

```python
{
    'session_id': '...',              # Login session
    'engine_id': 3,                   # Scan engine
    'template_id': '...',             # Created template
    'site_id': 123,                   # Site ID
    'scan_id': 456,                   # Scan ID
    'scan_status': 'finished',        # Scan status
    'scan_elapsed_time': 1234,        # Scan duration (seconds)
    'policy_count': 235,              # Number of policies
    'validation_passed': 235,         # Rules passed
    'validation_failed': 0,           # Rules failed
    'formatted_policies': [...],      # Policy list
    'policy_natural_ids': {...},      # Policy IDs
    'report_ids': {...},              # Report IDs
    'scan_details': {...}             # Complete scan details
}
```

## 🔟 Workflow Steps

1. **Login** → Authenticate
2. **Engine Selection** → Select engine
3. **Template Processing** → Create template
4. **Site Creation** → Create/update site
5. **Scan Start** → Initiate scan
6. **Scan Monitoring** → Wait for completion
7. **Scan Validation** → Check vuln count
8. **Policy Natural ID** → Get policy ID
9. **Report Generation** → Generate XCCDF
10. **Report Validation** → Validate with CSV

## 📁 File Structure

```
resources/
  └── e2e_benchmark_testing.robot  ← Main resource
tests/
  └── e2e_benchmark_testing.robot  ← Test cases
testdata/validation_rules/
  ├── CIS/
  │   ├── RHEL9/level1_server.csv
  │   └── Ubuntu20/level1_server.csv
  └── DISA/RHEL9/stig_baseline.csv
```

## 📝 CSV Format

```csv
NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_...,COMPLIANT,Description
2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_...,NOT COMPLIANT,Description
3,xccdf_org.cisecurity.benchmarks_rule_1.1.1.3_...,INFORMATIONAL,Description
```

**Valid Results**: `COMPLIANT`, `NOT COMPLIANT`, `INFORMATIONAL`, `NOT APPLICABLE`, `NOT CHECKED`, `UNKNOWN`

## 🏃 Run Commands

```bash
# Run all E2E tests
robot --outputdir results tests/e2e_benchmark_testing.robot

# Run specific test
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E RHEL 9 Level 1 Server CIS Benchmark"

# Run with tags
robot --outputdir results tests/e2e_benchmark_testing.robot --include e2e

# Run custom template only
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E Custom Benchmark Test Template"
```

## 🎯 Common Use Cases

### Update Existing Site
```robotframework
...    site_id=61    # Update site 61
```

### Use Specific Engine
```robotframework
...    engine_id=3   # Use engine 3
```

### Allow Some Vulnerabilities
```robotframework
...    expected_vuln_count=10    # Allow 10 vulns
```

### Database Credentials Required
```robotframework
...    db_required=${TRUE}    # Include DB creds
```

## 🔍 Validation Mapping

| CSV Value | XCCDF Value |
|-----------|-------------|
| `COMPLIANT` | `pass` |
| `NOT COMPLIANT` | `fail` |
| `INFORMATIONAL` | `informational` |
| `NOT APPLICABLE` | `notapplicable` |
| `NOT CHECKED` | `notchecked` |
| `UNKNOWN` | `unknown` |

## ⚠️ Common Issues

### Site Creation Fails
✓ Check VM config exists for OS/version
✓ Verify credentials in testdata/vm_config.json

### Validation Fails
✓ Check CSV path is correct
✓ Verify CSV expected results match actual
✓ Ensure CSV format is correct

### Scan Timeout
✓ Increase timeout (default: 7200s)
✓ Check target system is accessible

### Report Generation Fails
✓ Verify scan completed successfully
✓ Wait up to 2 minutes for report

## 📚 Documentation

- `E2E_TESTING_GUIDE.md` → Complete guide
- `E2E_ARCHITECTURE.md` → Architecture details
- `E2E_FRAMEWORK_SUMMARY.md` → Quick overview
- Inline docs in resource file → Keyword help

## 💡 Tips

✓ Use `${timestamp}` for unique site/template names
✓ Store CSV files in `testdata/validation_rules/{Benchmark}/{OS}/`
✓ Access results via dictionary keys
✓ Copy custom template for new tests
✓ Update CSV files when compliance changes

## 🆚 Code Reduction

**Before**: 250+ lines per test
**After**: ~15 lines per test
**Savings**: ~94% reduction

## 🎓 Learning Path

1. Read `E2E_FRAMEWORK_SUMMARY.md`
2. Run pre-configured test
3. Modify custom template
4. Create your own test
5. Read `E2E_TESTING_GUIDE.md` for advanced usage

## ✅ Success Indicators

Your test succeeds when:
- ✓ All 10 steps complete
- ✓ Scan status = 'finished'
- ✓ Vulnerability count matches expected
- ✓ Validation failed = 0
- ✓ Return dictionary populated

---

**Need Help?**
1. Check `E2E_TESTING_GUIDE.md`
2. Review inline documentation
3. Examine example tests
4. Verify parameters match your environment
