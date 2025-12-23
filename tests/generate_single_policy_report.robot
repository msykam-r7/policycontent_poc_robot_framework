*** Settings ***
Documentation     Generate XCCDF Report for Single Policy - Red Hat Enterprise Linux 9 Level 1 Server
...               
...               HOW RULE VALIDATION WORKS:
...               ==========================
...               
...               1. DEFINE RULES: In the test case, create a list of rules with expected results
...                  Each rule needs:
...                  - rule_id: The XCCDF rule identifier (e.g., xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_...)
...                  - expected_result: Expected compliance status (COMPLIANT, NOT COMPLIANT, etc.)
...               
...               2. DOWNLOAD REPORT: After report generation, download the XCCDF XML report
...               
...               3. VALIDATE: The validation keyword will:
...                  a) Parse the downloaded XCCDF XML report
...                  b) Search for each rule using XPath: .//rule-result[@idref='rule_id']
...                  c) Extract the actual result from: <result>pass</result>
...                  d) Map XCCDF result to your format:
...                     pass → COMPLIANT
...                     fail → NOT COMPLIANT
...                     notapplicable → NOT APPLICABLE
...                     notchecked → NOT CHECKED
...                     unknown → UNKNOWN
...                     informational → INFORMATIONAL
...                  e) Compare actual vs expected result
...                  f) Log PASS ✅ or FAIL ❌ for each rule
...                  g) Fail the test if any rule validation fails
...               
...               EXAMPLE XCCDF XML STRUCTURE:
...               <rule-result idref="xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_...">
...                 <result>pass</result>
...                 <ident system="http://cce.mitre.org">CCE-XXXXX</ident>
...                 <check system="http://oval.mitre.org/XMLSchema/oval-definitions-5">
...                   <check-content-ref href="..." name="oval:..."/>
...                 </check>
...               </rule-result>

Resource          ../resources/login.robot
Resource          ../resources/scan_template_api.robot
Resource          ../resources/report_operations.robot


*** Variables ***
${SITE_ID}    61
${POLICY_ID}    xccdf_org.cisecurity.benchmarks_benchmark_2.0.0_CIS_Red_Hat_Enterprise_Linux_9_Benchmark:2.0.0:xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server
${RULES_CSV_FILE}    ${EXECDIR}/testdata/validation_rules/CIS/RHEL9/level1_server.csv


*** Test Cases ***
Generate Report For RHEL 9 Level 1 Server Policy
    [Documentation]    Login, get policy natural ID, generate XCCDF report, download and validate using CSV
    [Tags]    report    policy    rhel9    validation    csv
    
    # ============================================================================
    # CSV FILE CONTAINS ALL VALIDATION RULES
    # ============================================================================
    # CSV File Location: ${RULES_CSV_FILE}
    # 
    # The CSV file format:
    # NUMBER,RULE_ID,EXPECTED_RESULT,DESCRIPTION
    # 1,xccdf_org.cisecurity.benchmarks_rule_1.1.1.1_Ensure_cramfs...,COMPLIANT,Description
    # 2,xccdf_org.cisecurity.benchmarks_rule_1.1.1.2_Ensure_freevxfs...,COMPLIANT,Description
    # 
    # You can edit the CSV file directly to add/remove/modify validation rules
    # ============================================================================

    # Step 1: Login to Console
    Log    ========================================    console=True
    Log    STEP 1: LOGGING IN TO CONSOLE    console=True
    Log    ========================================    console=True
    ${session_id}=    Login To Console
    Log    ✓ Successfully obtained Session ID: ${session_id}    console=True
    Log    ========================================    console=True
    
    # Step 2: Get Policy Natural ID (Surrogate Identifier)
    Log    ========================================    console=True
    Log    STEP 2: GETTING POLICY NATURAL ID    console=True
    Log    ========================================    console=True
    Log    Policy ID: ${POLICY_ID}    console=True
    ${surrogate_response}=    scan_template_api.Get Policy Surrogate Identifier    ${POLICY_ID}
    ${policy_natural_id}=    Set Variable    ${surrogate_response}[natural_id]
    Log    ✓ Policy Natural ID Retrieved: ${policy_natural_id}    console=True
    Log    ========================================    console=True
    
    # Step 3: Generate XCCDF Report
    Log    ========================================    console=True
    Log    STEP 3: GENERATING XCCDF REPORT    console=True
    Log    ========================================    console=True
    Log    Site ID: ${SITE_ID}    console=True
    Log    Policy Natural ID: ${policy_natural_id}    console=True
    
    # Create unique report name with random ID
    ${random_id}=    Evaluate    __import__('random').randint(100000, 999999)
    ${report_name}=    Set Variable    XCCDF_Report_RHEL9_Level1_Server_${random_id}
    Log    Report Name: ${report_name}    console=True
    Log    ========================================    console=True
    
    ${report_result}=    report_operations.Generate XCCDF Report For Policy
    ...    site_id=${SITE_ID}
    ...    policy_natural_id=${policy_natural_id}
    ...    report_name=${report_name}
    
    ${report_id}=    Set Variable    ${report_result}[report_id]
    
    Log    ========================================    console=True
    Log    ✅ REPORT GENERATION SUCCESSFUL    console=True
    Log    ========================================    console=True
    Log    Report ID: ${report_id}    console=True
    Log    Report Name: ${report_result}[report_name]    console=True
    Log    Site ID: ${report_result}[site_id]    console=True
    Log    Policy Natural ID: ${report_result}[policy_natural_id]    console=True
    Log    ========================================    console=True
    
    # Step 4: Get Report Status
    Log    ========================================    console=True
    Log    STEP 4: CHECKING REPORT STATUS    console=True
    Log    ========================================    console=True
    ${status_result}=    report_operations.Get Report Status    ${report_id}
    
    Log    ========================================    console=True
    Log    ✅ REPORT STATUS CHECK COMPLETE    console=True
    Log    ========================================    console=True
    Log    Report Config ID: ${status_result}[report_config_id]    console=True
    Log    Success: ${status_result}[success]    console=True
    
    # Check if report has been generated
    ${has_latest}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${status_result}    latest_status
    IF    ${has_latest}
        Log    Latest Report ID: ${status_result}[latest_report_id]    console=True
        Log    Latest Status: ${status_result}[latest_status]    console=True
        Log    Generated On: ${status_result}[generated_on]    console=True
        
        # Wait for report to complete - poll every 10 seconds for up to 2 minutes
        ${max_attempts}=    Set Variable    12
        ${attempt}=    Set Variable    0
        
        WHILE    '${status_result}[latest_status]' == 'Started' and ${attempt} < ${max_attempts}
            ${attempt}=    Evaluate    ${attempt} + 1
            Log    ⏳ Report is being generated (Attempt ${attempt}/${max_attempts}), waiting 10 seconds...    console=True
            Sleep    10s
            Log    Checking report status again...    console=True
            ${status_result}=    report_operations.Get Report Status    ${report_id}
            Log    Latest Status: ${status_result}[latest_status]    console=True
        END
        
        # Check if report generation completed
        Should Not Be Equal    ${status_result}[latest_status]    Started
        ...    msg=Report generation did not complete within 2 minutes
        
        # Step 5: Download the Report
        Log    ========================================    console=True
        Log    STEP 5: DOWNLOADING REPORT    console=True
        Log    ========================================    console=True
        ${download_result}=    report_operations.Download Report    
        ...    report_config_id=${report_id}
        ...    report_instance_id=${status_result}[latest_report_id]
        
        Log    ========================================    console=True
        Log    ✅ REPORT DOWNLOAD COMPLETE    console=True
        Log    ========================================    console=True
        Log    Downloaded Report Size: ${download_result}[content_length] bytes    console=True
        Log    Content Type: ${download_result}[content_type]    console=True
        Log    Download URL: ${download_result}[download_url]    console=True
        Log    ========================================    console=True
        
        # Step 6: Validate Report Using CSV File
        Log    ========================================    console=True
        Log    STEP 6: VALIDATING REPORT FROM CSV FILE    console=True
        Log    ========================================    console=True
        Log    CSV File: ${RULES_CSV_FILE}    console=True
        Log    ========================================    console=True
        
        # Validate using CSV file
        ${passed}    ${failed}    ${results}=    report_operations.Validate Report From Excel
        ...    excel_path=${RULES_CSV_FILE}
        ...    xml_content=${download_result}[report_content]
        ...    file_type=csv
        
        Log    ========================================    console=True
        Log    ✅ VALIDATION COMPLETE    console=True
        Log    ========================================    console=True
        Log    Passed: ${passed} ✓    console=True
        Log    Failed: ${failed} ✗    console=True
        Log    ========================================    console=True
        
        # Assert all rules passed
        Should Be Equal As Integers    ${failed}    0
        ...    msg=❌ Validation failed: ${failed} rule(s) did not match expected results. Check the validation summary above for details.
    ELSE
        Log    Report generation in progress or not started yet - cannot download    console=True
    END
    Log    ========================================    console=True
