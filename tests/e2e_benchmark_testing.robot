*** Settings ***
Documentation     E2E Benchmark Compliance Testing
...               
...               This test suite provides a parameterized approach to benchmark compliance testing.
...               Simply pass the required parameters and let the E2E resource handle the workflow.
...               
...               WHAT IT DOES:
...               1. Logs in to Nexpose/InsightVM
...               2. Reads available policies from data/policies/{benchmark}_policies.json
...               3. Selects scan engine
...               4. Processes and creates scan template with specified policies
...               5. Creates/updates site with VM configuration
...               6. Starts scan and monitors until completion
...               7. Validates scan results (vulnerability count)
...               8. Generates XCCDF report
...               9. Validates report against CSV rules
...               
...               PARAMETERS TO CUSTOMIZE:
...               - Benchmark: CIS, DISA, etc.
...               - OS Name: Red Hat Enterprise Linux 9, Ubuntu Linux 20.04 LTS, etc.
...               - Version: 2.0.0, 3.0.0, etc. (auto-reads from JSON)
...               - Profile (Optional): Level 1 - Server, Level 2 - Server (auto-detected from JSON)
...               - Policy List: "all" or specific policies like "Level 1 - Server,Level 2 - Server"
...               - Scan Template: cis, disa, etc.
...               - Service: ssh, cifs, oracle, mysql, etc.
...               - Scope: S (STIG), etc.
...               - Site Name: Custom site name
...               - Template Name: Custom template name
...               - CSV File: Path to validation rules CSV
...               
...               POLICY SELECTION:
...               The framework automatically reads available policies from data/policies/{benchmark}_policies.json
...               based on your OS name and version. You can then:
...               1. Use all policies: policy_list=all
...               2. Use specific policies: policy_list=Level 1 - Server,Level 2 - Server
...               3. Use one policy: policy_list=Level 1 - Server

Resource          ../resources/e2e_benchmark_testing.robot


*** Test Cases ***
E2E RHEL 9 Level 1 Server CIS Benchmark
    [Documentation]    Complete E2E test for RHEL 9 Level 1 Server CIS benchmark
    [Tags]    e2e    rhel9    cis    level1    server
    
    # Generate unique timestamp for site/template names
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${site_name}=    Set Variable    RHEL9_CIS_Level1_Server_${timestamp}
    ${template_name}=    Set Variable    RHEL9_CIS_Template_${timestamp}
    
    # Execute complete E2E test
    # VM Config Path: CIS → RHEL → 9 → compliance → server
    ${results}=    Run Complete E2E Benchmark Test  CIS  RHEL  9  compliance  server
    ...    os_name=Red Hat Enterprise Linux 9  version=2.0.0  scan_template=cis
    ...    service=ssh  scope=S   site_name=${site_name}
    ...    template_name=${template_name}    policy_list=all
    ...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv  
    
    # Log final results
    Log    ========================================    console=True
    Log    E2E TEST COMPLETE - FINAL RESULTS    console=True
    Log    ========================================    console=True
    Log    Session ID: ${results}[session_id]    console=True
    Log    Engine ID: ${results}[engine_id]    console=True
    Log    Template ID: ${results}[template_id]    console=True
    Log    Site ID: ${results}[site_id]    console=True
    Log    Scan ID: ${results}[scan_id]    console=True
    Log    Scan Status: ${results}[scan_status]    console=True
    Log    Scan Time: ${results}[scan_elapsed_time]s    console=True
    Log    Policy Count: ${results}[policy_count]    console=True
    Log    Validation Passed: ${results}[validation_passed] ✓    console=True
    Log    Validation Failed: ${results}[validation_failed] ✗    console=True
    Log    ========================================    console=True


