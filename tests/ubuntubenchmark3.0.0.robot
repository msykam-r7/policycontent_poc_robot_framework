*** Settings ***
Documentation     Test suite for Nexpose Console Login
Resource          ../resources/login.robot
Resource          ../resources/engines.robot
Resource          ../resources/site.robot
Resource          ../resources/scan_template_api.robot
Resource          ../resources/scan_operations.robot



*** Keywords ***
Create Or Update Ubuntu Site
    [Documentation]    Helper keyword to create or update site with common parameters
    [Arguments]    ${site_name}    ${engine_id}    ${site_id}=${EMPTY}    ${scan_template}=cis
    
    # If site_id is provided, update; otherwise create
    IF    '${site_id}' != '${EMPTY}'
        ${result_site_id}=    Update Site With VM Config    
        ...    ${site_id}
        ...    ${site_name}
        ...    CIS
        ...    RHEL
        ...    9
        ...    server
        ...    scan_template=${scan_template}
        ...    service=ssh
        ...    scope=S
        ...    engine_id=${engine_id}
    ELSE
        ${result_site_id}=    Create Site With VM Config    
        ...    ${site_name}
        ...    CIS
        ...    RHEL
        ...    9
        ...    server
        ...    scan_template=${scan_template}
        ...    service=ssh
        ...    scope=S
        ...    engine_id=${engine_id}
    END
    
    RETURN    ${result_site_id}


*** Test Cases ***
COMPLIANT CIS Ubuntu 20.04 Benchmark
    [Documentation]    Complete flow: Login, get engines, extract policies, get all policies, check deprecation, create site, and verify
    [Tags]    login    engines    site    policies    deprecation
    
    # Step 1: Login to Console
    ${session_id}=    Login To Console
    Log    Successfully obtained Session ID: ${session_id}
    
    # Step 2: Get Available Scan Engines
    ${engine_ids}=    Get Available Engines
    Log    Available Engines: ${engine_ids}
    
    # Get first engine ID or use default engine 3
    ${engine_count}=    Get Length    ${engine_ids}
    ${engine_id}=    Set Variable If    ${engine_count} > 0    ${engine_ids}[0]    3
    Log    Selected Engine ID: ${engine_id}
    
    # Step 3: Generate site name first (will be used as template title)
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${site_name}=    Set Variable    Ubuntu 20.04 Standard ${timestamp}
    
    # Step 4-7: Process template using OS identifier (simplified approach)
    # Arguments: scan_template, os_identifier, policies (optional)
    ${template_result}=    Process Template By OS Identifier    scan_template=cis    os_identifier=ubuntu-20.04-standard    policies=all
    Log    Template processing complete. Deprecated count: ${template_result}[deprecated_count]    console=True
    
    # Log all formatted policies (benchmark_id:version:policy_id)
    ${formatted_policies}=    Set Variable    ${template_result}[formatted_policies]
    ${policy_count}=    Get Length    ${formatted_policies}
    Log    ========================================    console=True
    Log    ALL POLICIES (${policy_count} total):    console=True
    FOR    ${policy}    IN    @{formatted_policies}
        Log    ${policy}    console=True
    END
    Log    ========================================    console=True
    
    # Get the generated template XML (now has custom title from site_name)
    ${template_xml}=    Set Variable    ${template_result}[template_xml]
    ${template_title}=    Set Variable    ${template_result}[template_title]
    Log    Template XML generated successfully with title: ${template_title}    console=True
    
    # Create new scan template via POST API
    ${create_result}=    Create Scan Template    ${template_xml}    ${site_name}
    ${scan_template_id}=    Set Variable    ${create_result}[template_id]
    Log    ✓ Template created successfully - ID: ${scan_template_id}, Title: ${create_result}[template_title]    console=True
    
    # Step 8: Create Site with Ubuntu 20.04 VM config from CIS framework using the new template
    ${site_id}=    Create Or Update Ubuntu Site    ${site_name}    ${engine_id}    ${EMPTY}    ${scan_template_id}
    Log    Created Site with ID: ${site_id}
    
    # Step 9: Verify site was created by fetching site details
    ${site_details}=    Get Site Details    ${site_id}
    Log    Site Details: ${site_details}    console=True
    
    # Step 10: Update the site with same name
    ${updated_site_id}=    Create Or Update Ubuntu Site    ${site_name}    ${engine_id}    ${site_id}    ${scan_template_id}
    Log    Updated Site with ID: ${updated_site_id}
    
    # Step 11: Verify site was updated
    ${updated_site_details}=    Get Site Details    ${site_id}
    Should Be Equal    ${updated_site_details}[name]    ${site_name}    Site name should match
    Log    Site successfully updated. Name: ${updated_site_details}[name]    console=True
    
    # Step 12: Start scan on the site
    ${scan_result}=    scan_operations.Start Scan    ${site_id}    ${engine_id}    ${site_name}
    ${scan_id}=    Set Variable    ${scan_result}[scan_id]
    Log    ✓ Scan started successfully - Scan ID: ${scan_id}    console=True
    
    # Step 13: Monitor scan until completion (polls every 5 seconds, logs every 1 minute, no timeout)
    ${monitor_result}=    scan_operations.Monitor Scan Until Complete    ${scan_id}    ${site_id}    poll_interval=5    log_interval=60
    ${final_status}=    Set Variable    ${monitor_result}[status]
    ${elapsed_time}=    Set Variable    ${monitor_result}[elapsed_time]
    ${previous_status}=    Set Variable    ${monitor_result}[previous_status]
    
    Log    ========================================    console=True
    Log    SCAN MONITORING COMPLETE    console=True
    Log    Previous Status: ${previous_status}    console=True
    Log    Final Status: ${final_status}    console=True
    Log    Total Time: ${elapsed_time} seconds    console=True
    Log    ========================================    console=True
    
    # Verify scan completed successfully
    Should Be Equal As Strings    ${final_status}    finished    Scan should complete with 'finished' status
    
    # Check if status changed from running to finished
    ${status_changed}=    Evaluate    '${previous_status}' == 'running' and '${final_status}' == 'finished'
    IF    ${status_changed}
        Log    <span style="color: green; font-weight: bold;">✓ Detected status change from 'running' to 'finished' - proceeding with policy natural ID retrieval</span>    html=True
    END
    
    # Step 14: Get final scan details
    ${final_scan_details}=    scan_operations.Get Scan Details    ${scan_id}    ${site_id}
    Log    Final Scan Details:    console=True
    Log    Full Details: ${final_scan_details}    console=True
    
    # Check if vulnerabilities field exists and validate count is 0
    ${has_vulnerabilities}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${final_scan_details}    vulnerabilities
    IF    ${has_vulnerabilities}
        ${vuln_count}=    Set Variable    ${final_scan_details}[vulnerabilities]
        Log    Vulnerability Count: ${vuln_count}    console=True
        
        # Convert to integer and validate it's 0
        ${vuln_count_int}=    Convert To Integer    ${vuln_count}
        Should Be Equal As Integers    ${vuln_count_int}    0    
        ...    msg=COMPLIANCE FAILED: Expected 0 vulnerabilities but found ${vuln_count_int}
        
        Log    ✓ COMPLIANCE PASSED: Vulnerability count is 0    console=True
    ELSE
        Log    Warning: Vulnerabilities field not found in scan statistics    console=True
    END
    
    # Step 15: Get surrogate identifier for FIRST policy only
    Log    ========================================    console=True
    Log    GETTING POLICY SURROGATE IDENTIFIER (NATURAL ID) - FIRST POLICY ONLY:    console=True
    Log    ========================================    console=True
    &{policy_natural_ids}=    Create Dictionary
    
    # Get only the first policy
    ${first_policy}=    Set Variable    ${formatted_policies}[0]
    Log    Processing FIRST policy only: ${first_policy}    console=True
    ${surrogate_response}=    scan_template_api.Get Policy Surrogate Identifier    ${first_policy}
    
    # Extract policy ID from formatted string (benchmark_id:version:policy_id)
    @{policy_parts}=    Split String    ${first_policy}    :
    ${policy_id}=    Set Variable    ${policy_parts}[2]
    
    # Extract policy name from policy ID (e.g., xccdf_org.cisecurity.benchmarks_profile_SEVERITY_CAT_II -> profile_SEVERITY_CAT_II)
    ${policy_name}=    Evaluate    $policy_id.split('_profile_')[-1] if '_profile_' in $policy_id else $policy_id
    
    # Convert to lowercase and replace spaces/special chars
    ${policy_var_name}=    Evaluate    'profile_' + $policy_name.lower().replace('-', '_').replace(' ', '_')
    
    # Store natural ID in dictionary
    Set To Dictionary    ${policy_natural_ids}    ${policy_var_name}    ${surrogate_response}[natural_id]
    
    Log    ✓ Policy: ${first_policy}    console=True
    Log    ✓ Policy Name: ${policy_name}    console=True
    Log    ✓ Variable Name: ${policy_var_name}    console=True
    Log    ✓ Natural ID: ${surrogate_response}[natural_id]    console=True
    Log    ========================================    console=True
    Log    COMPLETED 1 SURROGATE ID LOOKUP (FIRST POLICY ONLY)    console=True
    Log    ========================================    console=True
    
    # Log summary of all policy natural IDs with variable names
    Log    ========================================    console=True
    Log    POLICY NATURAL ID SUMMARY (Variable Format):    console=True
    FOR    ${var_name}    IN    @{policy_natural_ids}
        ${natural_id}=    Get From Dictionary    ${policy_natural_ids}    ${var_name}
        Log    ${var_name}: ${natural_id}    console=True
    END
    Log    ========================================    console=True
    
    # Step 16: Generate XCCDF Report for FIRST Policy Only
    Log    ========================================    console=True
    Log    STEP 16: GENERATING XCCDF REPORT - FIRST POLICY ONLY    console=True
    Log    ========================================    console=True
    
    # Dictionary to store report IDs
    ${report_ids}=    Create Dictionary
    
    # Get first (and only) policy from dictionary
    ${var_name}=    Evaluate    list($policy_natural_ids.keys())[0]
    ${natural_id}=    Get From Dictionary    ${policy_natural_ids}    ${var_name}
    
    # Create descriptive report name from policy variable name
    ${report_name}=    Set Variable    XCCDF_Report_${var_name}
    
    Log    ========================================    console=True
    Log    Generating Report for FIRST POLICY:    console=True
    Log    Policy Variable: ${var_name}    console=True
    Log    Natural ID: ${natural_id}    console=True
    Log    Report Name: ${report_name}    console=True
    Log    ========================================    console=True
    
    # Generate report
    ${report_result}=    Generate XCCDF Report For Policy
    ...    site_id=${site_id}
    ...    policy_natural_id=${natural_id}
    ...    report_name=${report_name}
    
    # Store report ID
    Set To Dictionary    ${report_ids}    ${var_name}    ${report_result}[report_id]
    
    Log    ✓ Report ID: ${report_result}[report_id]    console=True
    Log    ========================================    console=True
    Log    COMPLETED 1 REPORT GENERATION (FIRST POLICY ONLY)    console=True
    Log    ========================================    console=True
    
    # Log summary of generated report
    Log    ========================================    console=True
    Log    GENERATED REPORT SUMMARY:    console=True
    FOR    ${var_name}    IN    @{report_ids}
        ${report_id}=    Get From Dictionary    ${report_ids}    ${var_name}
        Log    ${var_name}: Report ID ${report_id}    console=True
    END
    Log    ========================================    console=True


