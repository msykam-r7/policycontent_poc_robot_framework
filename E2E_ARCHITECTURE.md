# E2E Benchmark Testing Framework - Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    E2E Test File (User Layer)                    │
│                  tests/e2e_benchmark_testing.robot               │
├─────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Test Case: E2E RHEL 9 Level 1 Server CIS Benchmark      │  │
│  ├───────────────────────────────────────────────────────────┤  │
│  │  ${results} = Run Complete E2E Benchmark Test             │  │
│  │      ...benchmark=CIS                                     │  │
│  │      ...os_name=Red Hat Enterprise Linux 9                │  │
│  │      ...version=2.0.0                                     │  │
│  │      ...profile=Level 1 - Server                          │  │
│  │      ...scan_template=cis                                 │  │
│  │      ...service=ssh                                       │  │
│  │      ...scope=S                                           │  │
│  │      ...site_name=${site_name}                            │  │
│  │      ...template_name=${template_name}                    │  │
│  │      ...csv_file=${csv_file}                              │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              E2E Resource File (Orchestration Layer)             │
│              resources/e2e_benchmark_testing.robot               │
├─────────────────────────────────────────────────────────────────┤
│  Main Keyword: Run Complete E2E Benchmark Test                  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 1: Execute Login Step                               │  │
│  │         → Login To Console                               │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 2: Execute Engine Selection Step                    │  │
│  │         → Get Available Engines                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 3: Execute Template Processing Step                 │  │
│  │         → Process Template For OS                        │  │
│  │         → Create Scan Template                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 4: Execute Site Creation Step                       │  │
│  │         → Create Site With VM Config                     │  │
│  │         OR Update Site With VM Config                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 5: Execute Scan Start Step                          │  │
│  │         → Start Scan                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 6: Execute Scan Monitoring Step                     │  │
│  │         → Monitor Scan Until Complete                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 7: Execute Scan Validation Step                     │  │
│  │         → Get Scan Details                               │  │
│  │         → Validate Vulnerability Count                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 8: Execute Policy Natural ID Retrieval Step         │  │
│  │         → Get Policy Surrogate Identifier                │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 9: Execute Report Generation Step                   │  │
│  │         → Generate XCCDF Report For Policy               │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Step 10: Execute Report Validation Step                  │  │
│  │          → Get Report Status                             │  │
│  │          → Download Report                               │  │
│  │          → Validate Report From Excel (CSV)              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Returns: Dictionary with all results                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│               Existing Resource Files (Service Layer)            │
├─────────────────────────────────────────────────────────────────┤
│  • login.robot           → Authentication                        │
│  • engines.robot         → Engine management                     │
│  • site.robot            → Site CRUD operations                  │
│  • scan_template_api.robot → Template operations                 │
│  • scan_operations.robot → Scan execution                        │
│  • report_operations.robot → Report generation & validation      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  Nexpose/InsightVM API                           │
│              (REST API + XML-RPC Interface)                      │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
Parameters (User Input)
    ↓
Run Complete E2E Benchmark Test
    ↓
Execute 10 Steps Sequentially
    ↓
Collect Results in Dictionary
    ↓
Return to Test Case
    ↓
Validate & Assert
```

## Component Responsibilities

### Test File (`tests/e2e_benchmark_testing.robot`)
- **Responsibility**: Define test cases with parameters
- **Does**: 
  - Sets test-specific parameters
  - Calls main E2E keyword
  - Validates final results
- **Does NOT**: 
  - Contain any business logic
  - Make API calls directly
  - Duplicate code

### E2E Resource (`resources/e2e_benchmark_testing.robot`)
- **Responsibility**: Orchestrate the complete workflow
- **Does**: 
  - Execute 10 workflow steps
  - Coordinate between different resources
  - Collect and return results
  - Handle step-by-step logging
- **Does NOT**: 
  - Implement low-level API calls
  - Contain test-specific logic
  - Hardcode any values

### Service Resources (`resources/*.robot`)
- **Responsibility**: Implement specific operations
- **Does**: 
  - Make API calls
  - Handle request/response
  - Provide reusable keywords
- **Does NOT**: 
  - Know about workflow
  - Depend on other services
  - Handle orchestration

## Modularity Benefits

```
┌─────────────────────────────────────────────────────────────────┐
│                         Modularity                               │
├─────────────────────────────────────────────────────────────────┤
│  Test Layer      → Add new tests without touching resources     │
│  Orchestration   → Change workflow without touching services    │
│  Service Layer   → Enhance services without touching tests      │
└─────────────────────────────────────────────────────────────────┘
```

## Comparison: Old vs New

### Old Approach (ubuntubenchmark3.0.0.robot)
```
┌─────────────────────────────────────────────┐
│  Test File (250+ lines)                     │
│  ┌───────────────────────────────────────┐  │
│  │ Step 1: Login                         │  │
│  │ Step 2: Get Engines                   │  │
│  │ Step 3: Process Template              │  │
│  │ Step 4: Create Site                   │  │
│  │ Step 5: Start Scan                    │  │
│  │ Step 6: Monitor Scan                  │  │
│  │ Step 7: Validate Scan                 │  │
│  │ Step 8: Get Policy Natural ID         │  │
│  │ Step 9: Generate Report               │  │
│  │ Step 10: Validate Report              │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘

Problem: Everything in one file, hard to maintain, lots of duplication
```

### New Approach (E2E Framework)
```
┌────────────────┐
│  Test (15 lines)│
└────────┬───────┘
         │ Calls
         ↓
┌────────────────────────────────┐
│  E2E Resource (550 lines)      │
│  All logic in one place        │
└────────┬───────────────────────┘
         │ Uses
         ↓
┌────────────────────────────────┐
│  Service Resources             │
│  Specialized operations        │
└────────────────────────────────┘

Benefit: Clean separation, reusable, maintainable
```

## CSV Validation Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                      CSV Validation Flow                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CSV File (testdata/validation_rules/...)                       │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION             │    │
│  │ 1,xccdf_org...rule_1.1.1.1...,COMPLIANT,Description    │    │
│  │ 2,xccdf_org...rule_1.1.1.2...,NOT COMPLIANT,Desc       │    │
│  │ 3,xccdf_org...rule_1.1.1.3...,INFORMATIONAL,Desc       │    │
│  └────────────────────────────────────────────────────────┘    │
│                          ↓                                       │
│  E2E Framework: Execute Report Validation Step                  │
│                          ↓                                       │
│  report_operations.Validate Report From Excel                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ • Load CSV file                                        │    │
│  │ • Parse XCCDF XML report                               │    │
│  │ • Compare each rule: Expected vs Actual                │    │
│  │ • Map XCCDF results (pass→COMPLIANT, etc.)             │    │
│  │ • Generate validation report                           │    │
│  │ • Return passed/failed counts                          │    │
│  └────────────────────────────────────────────────────────┘    │
│                          ↓                                       │
│  Validation Results                                             │
│  ┌────────────────────────────────────────────────────────┐    │
│  │ Passed: 235 ✓                                          │    │
│  │ Failed: 0 ✗                                            │    │
│  │ Success Rate: 100.0%                                   │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Usage Pattern

```
1. Choose your test scenario
   ├─ Pre-configured (RHEL 9, Ubuntu 20.04)
   └─ Custom (any benchmark/OS)

2. Set parameters
   ├─ Required: benchmark, os_name, version, profile, etc.
   └─ Optional: engine_id, site_id, expected_vuln_count, etc.

3. Provide CSV validation file
   └─ testdata/validation_rules/{Benchmark}/{OS}/{profile}.csv

4. Run test
   └─ robot --outputdir results tests/e2e_benchmark_testing.robot

5. Get results
   ├─ Console output (step-by-step progress)
   ├─ Return dictionary (programmatic access)
   └─ Test report (HTML/XML)
```

## Extensibility Points

### Add New Benchmark
1. Create CSV validation file
2. Update vm_config.json with credentials
3. Run test with new parameters

### Add New Step
1. Add keyword to e2e_benchmark_testing.robot
2. Call from `Run Complete E2E Benchmark Test`
3. All tests automatically get the new step

### Customize Workflow
1. Override specific step keywords
2. Add pre/post processing
3. Extend return dictionary

### Add Validation Logic
1. Enhance `Execute Report Validation Step`
2. Create custom validation keywords
3. Integrate with existing workflow

## Summary

The E2E framework provides:
- **3-layer architecture**: Test → Orchestration → Service
- **Clean separation**: Each layer has single responsibility
- **Reusability**: Write once, use everywhere
- **Maintainability**: Change once, affect all
- **Extensibility**: Add features without breaking existing tests
- **CSV validation**: Automatic report validation included
