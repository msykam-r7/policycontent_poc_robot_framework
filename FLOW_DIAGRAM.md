# Code Flow Diagram

## 🔄 How the Code Works

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR TEST CASE                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │   Login To Console                  │
        │   (Get Session ID)                  │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  🆕 Get Benchmark ID And Policies   │
        │      For OS                         │
        │                                     │
        │  Input:                             │
        │  - template_id: cis                 │
        │  - os_name: Red Hat Enterprise      │
        │    Linux 9 STIG                     │
        │  - version: 1.0.0                   │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  Returns Dictionary:                │
        │  {                                  │
        │    benchmark_id: "xccdf_org..."     │
        │    os: "Red Hat Enterprise..."      │
        │    version: "1.0.0"                 │
        │    policies: [                      │
        │      "Level-I",                     │
        │      "Level-II",                    │
        │      ...                            │
        │    ]                                │
        │    policy_count: 12                 │
        │    deprecated: []                   │
        │  }                                  │
        └─────────────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────┐
        │  You can now use:                   │
        │  ${benchmark}[benchmark_id]         │
        │  ${benchmark}[policies]             │
        │  ${benchmark}[policy_count]         │
        └─────────────────────────────────────┘
```

---

## 📊 Data Flow

```
┌──────────────────┐
│ Nexpose API      │
│ (Template Data)  │
└────────┬─────────┘
         │
         │ First time: API call
         │ Later: Uses cached file
         ▼
┌──────────────────────────────┐
│ data/policies/               │
│   cis_policies.json          │
│                              │
│ Contains all benchmarks:     │
│ - OS names                   │
│ - Versions                   │
│ - Benchmark IDs              │
│ - Policy lists               │
└────────┬─────────────────────┘
         │
         │ Read and filter
         ▼
┌──────────────────────────────┐
│ Get Benchmark ID And         │
│ Policies For OS              │
│                              │
│ 1. Loads JSON file           │
│ 2. Filters by OS name        │
│ 3. Filters by version (opt)  │
│ 4. Returns first match       │
└────────┬─────────────────────┘
         │
         │ Returns filtered result
         ▼
┌──────────────────────────────┐
│ Your Test Case               │
│ Gets dictionary with:        │
│ - benchmark_id               │
│ - policies                   │
│ - policy_count               │
│ - etc.                       │
└──────────────────────────────┘
```

---

## 🎯 Comparison: Before vs After

### BEFORE (Your Current Approach)
```
Login
  ↓
Process Template For OS (complex, does everything)
  ↓
template_result = {
  template_xml: "...",
  os_policies: [...],
  all_policies: [...],
  deprecated_count: 1,
  total_policies: 500,
  benchmark_id: "...",
  os_name: "...",
  version: "...",
  policies: "all",
  template_title: "..."
}
  ↓
Have to dig through template_result to find what you need
```

### AFTER (New Simple Approach)
```
Login
  ↓
Get Benchmark ID And Policies For OS (simple, focused)
  ↓
benchmark = {
  benchmark_id: "...",
  os: "...",
  version: "...",
  policies: [...],
  policy_count: 12
}
  ↓
Direct access: ${benchmark}[benchmark_id]
               ${benchmark}[policies]
```

---

## 🔍 What Happens Under the Hood

```
When you call:
${benchmark}=    Get Benchmark ID And Policies For OS    cis    Red Hat Enterprise Linux 9 STIG    1.0.0

Step-by-step execution:
┌──────────────────────────────────────────────────────┐
│ 1. Check if data/policies/cis_policies.json exists  │
│    ├─ YES: Load from file (fast)                    │
│    └─ NO:  Call API to fetch (creates file)         │
└──────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│ 2. Parse JSON to get all benchmarks                 │
│    Example data structure:                          │
│    {                                                 │
│      "template_id": "cis",                          │
│      "policy_benchmarks": [                         │
│        {                                             │
│          "os": "Red Hat Enterprise Linux 9 STIG",   │
│          "version": "1.0.0",                        │
│          "benchmark_id": "xccdf_org...",            │
│          "policies": ["Level-I", "Level-II"],       │
│          "policy_count": 12                         │
│        },                                            │
│        ... more benchmarks ...                       │
│      ]                                               │
│    }                                                 │
└──────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│ 3. Filter benchmarks by OS name                     │
│    - Convert to lowercase                           │
│    - Split into words                               │
│    - Match all words in OS name                     │
│    Result: [matching benchmarks]                    │
└──────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│ 4. Filter by version (if provided)                  │
│    - Keep only benchmarks with matching version     │
│    Result: [version-filtered benchmarks]            │
└──────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│ 5. Return first matching benchmark                  │
│    - Should be only one for specific OS+version     │
│    - Returns as dictionary                          │
└──────────────────────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────┐
│ 6. Log details to console                           │
│    ========================================          │
│    BENCHMARK DETAILS FOR Red Hat Enterprise...      │
│    Benchmark ID: xccdf_org...                       │
│    OS: Red Hat Enterprise Linux 9 STIG              │
│    Version: 1.0.0                                    │
│    Policy Count: 12                                  │
│    Policies: ['Level-I', 'Level-II', ...]           │
│    ========================================          │
└──────────────────────────────────────────────────────┘
```

---

## 💾 File Structure

```
poc_robot_framework/
│
├── resources/
│   └── scan_template_api.robot ← Modified (new keyword added)
│
├── library/
│   └── benchmark_policy_helper.py ← New (Python helper)
│
├── tests/
│   ├── ubuntubenchmark3.0.0.robot ← Your original test
│   ├── ubuntubenchmark_enhanced.robot ← New (enhanced version)
│   ├── simple_benchmark_example.robot ← New (simple examples)
│   └── get_benchmark_example.robot ← New (detailed examples)
│
├── data/
│   └── policies/
│       └── cis_policies.json ← Auto-generated by API
│
└── Documentation/
    ├── SUMMARY.md ← Overview (this summary)
    ├── QUICK_REFERENCE.md ← Quick reference card
    ├── GET_BENCHMARK_GUIDE.md ← Full guide
    └── FLOW_DIAGRAM.md ← This file
```

---

## 🚀 Usage Pattern

```
┌─────────────────────────────────────────────────┐
│  PATTERN 1: Simple Lookup                       │
│  Use when: You just need benchmark info         │
│                                                  │
│  Login                                           │
│    ↓                                             │
│  Get Benchmark ID And Policies For OS            │
│    ↓                                             │
│  Use ${benchmark}[benchmark_id]                  │
│      ${benchmark}[policies]                      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  PATTERN 2: Benchmark + Template Processing     │
│  Use when: Need benchmark info AND template     │
│                                                  │
│  Login                                           │
│    ↓                                             │
│  Get Benchmark ID And Policies For OS            │
│    ↓                                             │
│  Log benchmark info                              │
│    ↓                                             │
│  Process Template For OS                         │
│    ↓                                             │
│  Continue with site creation/scanning            │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  PATTERN 3: List All Available OS               │
│  Use when: Want to see all options              │
│                                                  │
│  Login                                           │
│    ↓                                             │
│  Get Policies For OS    cis    all               │
│    ↓                                             │
│  FOR each benchmark                              │
│    Log ${benchmark}[os] ${benchmark}[version]    │
│  END                                             │
└─────────────────────────────────────────────────┘
```

---

## ✨ Key Advantages

```
┌──────────────────────────┐     ┌──────────────────────────┐
│  Old Way                 │     │  New Way                 │
├──────────────────────────┤     ├──────────────────────────┤
│ ❌ Complex return value  │     │ ✅ Simple dictionary     │
│ ❌ Dig through results   │     │ ✅ Direct access         │
│ ❌ Hard to read          │     │ ✅ Clear and readable    │
│ ❌ Multi-purpose keyword │     │ ✅ Single purpose        │
└──────────────────────────┘     └──────────────────────────┘
```

---

## 📞 Quick Help

**Q: How do I get benchmark info?**
```robotframework
${b}=    Get Benchmark ID And Policies For OS    cis    Red Hat Enterprise Linux 9 STIG    1.0.0
```

**Q: How do I access the data?**
```robotframework
${id}=    Set Variable    ${b}[benchmark_id]
${policies}=    Set Variable    ${b}[policies]
${count}=    Set Variable    ${b}[policy_count]
```

**Q: What if I don't know the version?**
```robotframework
${b}=    Get Benchmark ID And Policies For OS    cis    Ubuntu 20.04
# Returns first match (usually latest version)
```

**Q: How do I see all available OS?**
```robotframework
${all}=    Get Policies For OS    cis    all
FOR    ${b}    IN    @{all}
    Log    ${b}[os] ${b}[version]
END
```
