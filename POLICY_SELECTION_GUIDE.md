# Policy Selection in E2E Testing Framework

## Overview

The E2E framework now supports **flexible policy selection** when creating scan templates. You can choose to include:
- ✅ **All available policies** for an OS/version
- ✅ **Multiple specific policies** 
- ✅ **Single policy**

Policies are automatically discovered from `data/policies/{benchmark}_policies.json` files based on your OS name and version.

## How It Works

### Step 1: Automatic Policy Discovery

When you specify:
```robotframework
benchmark=CIS
os_name=Red Hat Enterprise Linux 9
version=2.0.0
```

The framework automatically:
1. Opens `data/policies/cis_policies.json`
2. Finds the entry matching your OS and version
3. Reads all available policies for that combination

Example JSON entry:
```json
{
  "os": "Xccdf Org.ecurity.s 2.0.0 Cis Red Hat Enterprise Linux 9 Benchmark",
  "benchmark_id": "xccdf_org.cisecurity.benchmarks_benchmark_2.0.0_CIS_Red_Hat_Enterprise_Linux_9_Benchmark",
  "version": "2.0.0",
  "policies": [
    "xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server",
    "xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Workstation",
    "xccdf_org.cisecurity.benchmarks_profile_Level_2_-_Server",
    "xccdf_org.cisecurity.benchmarks_profile_Level_2_-_Workstation"
  ],
  "policy_count": 4
}
```

### Step 2: Policy Selection

You specify which policies to include using the `policy_list` parameter:

#### Option 1: All Policies
```robotframework
policy_list=all
```
- Includes **all 4 policies** (Level 1 Server, Level 1 Workstation, Level 2 Server, Level 2 Workstation)
- Best for comprehensive testing

#### Option 2: Multiple Specific Policies
```robotframework
policy_list=Level 1 - Server,Level 2 - Server
```
- Includes **only the specified policies**
- Use comma-separated list
- Policy names are simplified (without the `xccdf_org.cisecurity.benchmarks_profile_` prefix)

#### Option 3: Single Policy
```robotframework
policy_list=Level 1 - Server
```
- Includes **only one policy**
- Fastest for targeted testing

### Step 3: Profile Selection

You can also specify which profile to use for site creation:

```robotframework
profile_name=Level 1 - Server
```

If not specified, the framework uses the **first available policy** from the JSON.

## Complete Examples

### Example 1: All Policies

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Red Hat Enterprise Linux 9
...    version=2.0.0
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=${site_name}
...    template_name=${template_name}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
...    profile_name=Level 1 - Server
...    policy_list=all                    # ← Include all 4 policies
```

**Result**: Template created with all 4 policies

### Example 2: Specific Policies

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Red Hat Enterprise Linux 9
...    version=2.0.0
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=${site_name}
...    template_name=${template_name}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
...    profile_name=Level 1 - Server
...    policy_list=Level 1 - Server,Level 2 - Server    # ← Only these 2
```

**Result**: Template created with only Level 1 Server and Level 2 Server policies

### Example 3: Single Policy

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Red Hat Enterprise Linux 9
...    version=2.0.0
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=${site_name}
...    template_name=${template_name}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
...    profile_name=Level 1 - Server
...    policy_list=Level 1 - Server       # ← Only one policy
```

**Result**: Template created with only Level 1 Server policy

### Example 4: Auto-Detected Profile (No profile_name)

```robotframework
${results}=    Run Complete E2E Benchmark Test
...    benchmark=CIS
...    os_name=Red Hat Enterprise Linux 9
...    version=2.0.0
...    scan_template=cis
...    service=ssh
...    scope=S
...    site_name=${site_name}
...    template_name=${template_name}
...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv
...    policy_list=all
```

**Result**: Framework automatically uses first available policy (Level 1 - Server) for site creation

## Policy Name Format

When specifying policies in `policy_list`, use the **simplified format**:

| JSON Format | Simplified Format (for policy_list) |
|-------------|-------------------------------------|
| `xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server` | `Level 1 - Server` |
| `xccdf_org.cisecurity.benchmarks_profile_Level_2_-_Workstation` | `Level 2 - Workstation` |
| `xccdf_org.cisecurity.benchmarks_profile_STIG` | `STIG` |

The framework handles the conversion automatically.

## Available Policies by OS

### Red Hat Enterprise Linux 9 (v2.0.0)
```
Level 1 - Server
Level 1 - Workstation
Level 2 - Server
Level 2 - Workstation
```

### Ubuntu Linux 20.04 LTS (v3.0.0)
```
Level 1 - Server
Level 1 - Workstation
Level 2 - Server
Level 2 - Workstation
```

### Ubuntu Linux 22.04 LTS (v2.0.0)
```
Level 1 - Server
Level 1 - Workstation
Level 2 - Server
Level 2 - Workstation
```

## Running the Examples

```bash
# Test with all policies
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E RHEL 9 All Policies Example"

# Test with multiple specific policies
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E RHEL 9 Multiple Policies Example"

# Test with single policy
robot --outputdir results tests/e2e_benchmark_testing.robot --test "E2E RHEL 9 Single Policy Example"
```

## Benefits

✅ **Flexible** - Choose exactly which policies you need
✅ **Fast** - Single policy tests run faster than all policies
✅ **Targeted** - Test specific compliance levels
✅ **Comprehensive** - Or test everything with `all`
✅ **Automatic** - Policies discovered from JSON automatically
✅ **Simple** - Use easy-to-remember policy names

## Troubleshooting

### Issue: "No matching policy found"
**Solution**: Check that your `os_name` and `version` match an entry in `data/policies/{benchmark}_policies.json`

### Issue: "Profile not found in available policies"
**Solution**: Verify the profile name matches one of the available policies. Use simplified format (e.g., `Level 1 - Server` not the full `xccdf_org...` format)

### Issue: Invalid policy in policy_list
**Solution**: Check policy names match available policies exactly. They're case-sensitive and must include spaces/hyphens correctly.

## Summary

The E2E framework gives you complete control over policy selection:

1. **Specify OS and version** → Framework reads available policies from JSON
2. **Choose policy_list** → Select `all`, multiple, or single policy
3. **Optionally specify profile_name** → Or let framework auto-select
4. **Run test** → Template created with exactly the policies you want

This flexibility allows you to:
- Run quick single-policy tests during development
- Run comprehensive all-policy tests for full validation
- Run targeted multi-policy tests for specific compliance levels
