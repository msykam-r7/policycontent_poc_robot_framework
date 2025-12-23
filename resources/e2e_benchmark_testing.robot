*** Settings ***
Documentation     End-to-End Benchmark Testing Resource
...               
...               This resource file contains all common keywords for E2E benchmark compliance testing.
...               It handles the complete workflow:
...               1. Login and engine selection
...               2. Template processing and creation
...               3. Site creation/update
...               4. Scan execution and monitoring
...               5. Report generation
...               6. CSV validation
...               
...               USAGE:
...               Import this resource and call: Run Complete E2E Benchmark Test
...               with all required parameters.

Library           RequestsLibrary
Library           Collections
Library           String
Library           OperatingSystem
Library           json
Resource          login.robot
Resource          engines.robot
Resource          site.robot
Resource          scan_template_api.robot
Resource          scan_operations.robot
Resource          report_operations.robot


*** Keywords ***
Map OS Name To VM Config Key
    [Documentation]    Map full OS name to VM config key
    ...    Maps OS names used in JSON/templates to the keys used in vm_config.json
    ...    
    ...    EXAMPLES:
    ...    - "Red Hat Enterprise Linux 9" → "RHEL"
    ...    - "Ubuntu Linux 20.04 LTS" → "Ubuntu"
    ...    - "CentOS Linux 8" → "CentOS"
    [Arguments]    ${os_name}
    
    # Define mapping for common OS names
    ${os_lower}=    Convert To Lowercase    ${os_name}
    
    # RHEL variants
    ${is_rhel}=    Evaluate    "red hat" in '''${os_lower}''' or "rhel" in '''${os_lower}'''
    IF    ${is_rhel}
        RETURN    RHEL
    END
    
    # Ubuntu
    ${is_ubuntu}=    Evaluate    "ubuntu" in '''${os_lower}'''
    IF    ${is_ubuntu}
        RETURN    Ubuntu
    END
    
    # CentOS
    ${is_centos}=    Evaluate    "centos" in '''${os_lower}'''
    IF    ${is_centos}
        RETURN    CentOS
    END
    
    # Amazon Linux
    ${is_amazon}=    Evaluate    "amazon" in '''${os_lower}'''
    IF    ${is_amazon}
        RETURN    Amazon-Linux-2
    END
    
    # Oracle Linux
    ${is_oracle}=    Evaluate    "oracle linux" in '''${os_lower}'''
    IF    ${is_oracle}
        RETURN    Oracle
    END
    
    # SUSE
    ${is_suse}=    Evaluate    "suse" in '''${os_lower}'''
    IF    ${is_suse}
        RETURN    SUSE
    END
    
    # If no match, return as-is
    Log    Warning: No VM config mapping found for OS: ${os_name}. Using as-is.    WARN
    RETURN    ${os_name}


Extract Version Number
    [Documentation]    Extract major version number from version string
    ...    EXAMPLES:
    ...    - "2.0.0" → "9" (for RHEL 9 v2.0.0)
    ...    - "3.0.0" → "20-04" (for Ubuntu 20.04 v3.0.0)
    [Arguments]    ${os_name}    ${version}
    
    # For RHEL: extract from OS name (e.g., "Red Hat Enterprise Linux 9" → "9")
    ${is_rhel}=    Evaluate    "red hat" in '''${os_name.lower()}''' or "rhel" in '''${os_name.lower()}'''
    IF    ${is_rhel}
        ${rhel_version}=    Evaluate    '''${os_name}'''.split()[-1]
        RETURN    ${rhel_version}
    END
    
    # For Ubuntu: extract from OS name (e.g., "Ubuntu Linux 20.04 LTS" → "Ubuntu-20-04")
    ${is_ubuntu}=    Evaluate    "ubuntu" in '''${os_name.lower()}'''
    IF    ${is_ubuntu}
        # Extract version like "20.04" and convert to "Ubuntu-20-04"
        ${ubuntu_match}=    Evaluate    __import__('re').search(r'(\d+\.\d+)', '''${os_name}''')    re
        IF    ${ubuntu_match} != ${None}
            ${ubuntu_version}=    Evaluate    ${ubuntu_match}.group(1).replace('.', '-')
            ${vm_version}=    Set Variable    Ubuntu-${ubuntu_version}
            RETURN    ${vm_version}
        END
    END
    
    # Default: return version as-is
    RETURN    ${version}


Get Policies From JSON
    [Documentation]    Read policies from JSON file based on benchmark, OS name, and version
    ...    
    ...    This keyword automatically determines which policies are available for
    ...    a specific OS and version combination by reading from JSON files in
    ...    data/policies/ directory.
    ...    
    ...    PARAMETERS:
    ...    - benchmark: Benchmark name (e.g., CIS, DISA) - determines which JSON file to read
    ...    - os_name: OS name as it appears in the JSON (e.g., "Red Hat Enterprise Linux 9", "Ubuntu Linux 20.04 LTS")
    ...    - version: Version to match (e.g., "2.0.0", "3.0.0")
    ...    
    ...    RETURNS:
    ...    Dictionary with keys:
    ...    - os: Full OS name from JSON
    ...    - benchmark_id: Benchmark identifier
    ...    - version: Version number
    ...    - policies: List of available policies
    ...    - policy_count: Number of policies
    ...    
    ...    EXAMPLE:
    ...    ${policy_info}=    Get Policies From JSON    CIS    Red Hat Enterprise Linux 9    2.0.0
    ...    # Returns policies: ["Level_1_-_Server", "Level_1_-_Workstation", ...]
    
    [Arguments]    ${benchmark}    ${os_name}    ${version}
    
    # Convert benchmark name to lowercase for filename
    ${benchmark_lower}=    Convert To Lowercase    ${benchmark}
    ${json_file}=    Set Variable    ${EXECDIR}/data/policies/${benchmark_lower}_policies.json
    
    Log    ========================================    console=True
    Log    READING POLICIES FROM JSON FILE    console=True
    Log    ========================================    console=True
    Log    Benchmark: ${benchmark}    console=True
    Log    OS Name: ${os_name}    console=True
    Log    Version: ${version}    console=True
    Log    JSON File: ${json_file}    console=True
    Log    ========================================    console=True
    
    # Check if JSON file exists
    ${file_exists}=    Run Keyword And Return Status    File Should Exist    ${json_file}
    IF    not ${file_exists}
        Fail    Policy JSON file not found: ${json_file}. Available files should be named like: cis_policies.json, disa_policies.json
    END
    
    # Read and parse JSON file
    ${json_content}=    Get File    ${json_file}
    ${json_data}=    Evaluate    json.loads('''${json_content}''')    json
    
    # Get policy_benchmarks array
    ${benchmarks}=    Set Variable    ${json_data}[policy_benchmarks]
    
    # Search for matching OS and version
    ${found}=    Set Variable    ${FALSE}
    ${matched_entry}=    Create Dictionary
    
    FOR    ${entry}    IN    @{benchmarks}
        ${entry_os}=    Set Variable    ${entry}[os]
        ${entry_version}=    Set Variable    ${entry}[version]
        
        # Check if OS name is contained in the JSON OS field (case-insensitive partial match)
        ${os_lower}=    Convert To Lowercase    ${os_name}
        ${entry_os_lower}=    Convert To Lowercase    ${entry_os}
        ${os_matches}=    Evaluate    '''${os_lower}''' in '''${entry_os_lower}'''
        
        # Check if version matches exactly
        ${version_matches}=    Evaluate    '''${entry_version}''' == '''${version}'''
        
        # If both match, we found it
        IF    ${os_matches} and ${version_matches}
            ${matched_entry}=    Set Variable    ${entry}
            ${found}=    Set Variable    ${TRUE}
            Log    ✓ Found matching entry in JSON    console=True
            Log    Full OS Name: ${entry_os}    console=True
            Log    Benchmark ID: ${entry}[benchmark_id]    console=True
            Log    Policies: ${entry}[policies]    console=True
            BREAK
        END
    END
    
    # Verify we found a match
    IF    not ${found}
        Log    ========================================    console=True
        Log    ERROR: NO MATCHING POLICY FOUND    console=True
        Log    ========================================    console=True
        Log    Searched for:    console=True
        Log    OS Name: ${os_name}    console=True
        Log    Version: ${version}    console=True
        Log    In file: ${json_file}    console=True
        Log    ========================================    console=True
        Fail    No matching policy found for OS "${os_name}" with version "${version}" in ${json_file}
    END
    
    Log    ========================================    console=True
    
    RETURN    ${matched_entry}


Get OS Details From Identifier
    [Documentation]    Extract OS name from benchmark identifier
    ...    Examples:
    ...    - Red_Hat_Enterprise_Linux_9_BENCHMARK → Red Hat Enterprise Linux 9
    ...    - Ubuntu_Linux_20.04_LTS_STIG_Benchmark → Ubuntu Linux 20.04 LTS
    ...    - Microsoft_Windows_Server_2019_Stand-alone → Microsoft Windows Server 2019
    [Arguments]    ${os_benchmark_identifier}    ${benchmark}
    
    # Remove common suffixes
    ${cleaned}=    Replace String    ${os_benchmark_identifier}    _BENCHMARK    ${EMPTY}
    ${cleaned}=    Replace String    ${cleaned}    _STIG_Benchmark    ${EMPTY}
    ${cleaned}=    Replace String    ${cleaned}    _Stand-alone    ${EMPTY}
    
    # Replace underscores with spaces
    ${os_name}=    Replace String    ${cleaned}    _    ${SPACE}
    
    RETURN    ${os_name}


Run Complete E2E Benchmark Test
    [Documentation]    Execute complete E2E benchmark compliance testing workflow
    ...    
    ...    Accepts EITHER the new signature (benchmark, vm_os, vm_version, os_name, service)
    ...    OR the old signature (os_identifier, os_benchmark_identifier, server_service/service)
    ...    
    ...    This keyword automatically detects which signature is being used and routes accordingly.
    [Arguments]    &{kwargs}
    
    # Check if using old signature (os_identifier + os_benchmark_identifier)
    ${has_os_identifier}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${kwargs}    os_identifier
    ${has_os_benchmark}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${kwargs}    os_benchmark_identifier
    
    IF    ${has_os_identifier} and ${has_os_benchmark}
        # Old signature - convert to new
        ${result}=    Run Complete E2E Benchmark Test With OS Identifier    &{kwargs}
        RETURN    ${result}
    ELSE
        # New signature - use internal implementation
        ${result}=    Run Complete E2E Benchmark Test Internal    &{kwargs}
        RETURN    ${result}
    END


Run Complete E2E Benchmark Test With OS Identifier
    [Documentation]    Adapter for old test signature using os_identifier and os_benchmark_identifier
    [Arguments]    
    ...    ${os_identifier}
    ...    ${vm_cred_types}
    ...    ${os_benchmark_identifier}
    ...    ${version}
    ...    ${scan_template}
    ...    ${scope}
    ...    ${site_name}
    ...    ${template_name}
    ...    ${csv_file}
    ...    ${server_service}=${EMPTY}
    ...    ${service}=${EMPTY}
    ...    ${policy_list}=all
    ...    ${engine_id}=${EMPTY}
    ...    ${site_id}=${EMPTY}
    
    # Parse os_identifier: CIS_RHEL_9 → benchmark=CIS, vm_os=RHEL, vm_version=9
    @{parts}=    Split String    ${os_identifier}    _
    ${benchmark}=    Set Variable    ${parts}[0]
    ${vm_os}=    Set Variable    ${parts}[1]
    ${vm_version}=    Set Variable    ${parts}[2]
    
    # Determine service to use
    ${final_service}=    Set Variable If    '${server_service}' != '${EMPTY}'    ${server_service}    ${service}
    
    # Get OS name from os_benchmark_identifier
    ${os_name}=    Get OS Details From Identifier    ${os_benchmark_identifier}    ${benchmark}
    
    # Convert vm_cred_types from string to list if needed
    ${is_string}=    Evaluate    isinstance($vm_cred_types, str)
    IF    ${is_string}
        @{cred_list}=    Split String    ${vm_cred_types}    ,
        # Strip whitespace from each element
        @{cred_list}=    Evaluate    [x.strip() for x in $cred_list]
    ELSE
        @{cred_list}=    Set Variable    ${vm_cred_types}
    END
    
    # Call the internal implementation with new signature
    ${result}=    Run Complete E2E Benchmark Test Internal
    ...    ${benchmark}
    ...    ${vm_os}
    ...    ${vm_version}
    ...    @{cred_list}
    ...    os_name=${os_name}
    ...    version=${version}
    ...    scan_template=${scan_template}
    ...    service=${final_service}
    ...    scope=${scope}
    ...    site_name=${site_name}
    ...    template_name=${template_name}
    ...    csv_file=${csv_file}
    ...    policy_list=${policy_list}
    ...    engine_id=${engine_id}
    ...    site_id=${site_id}
    
    RETURN    ${result}


Run Complete E2E Benchmark Test Internal
    [Documentation]    Internal implementation with new signature
    ...    
    ...    PARAMETERS:
    ...    - benchmark: Benchmark name for JSON lookup (e.g., CIS, DISA)
    ...    - vm_os: VM config OS key (e.g., RHEL, Ubuntu, CentOS)
    ...    - vm_version: VM config version key (e.g., 9, Ubuntu-20-04)
    ...    - vm_cred_types: Credential types needed (e.g., server, or server, database)
    ...    - os_name: Full OS name for JSON/template lookup (e.g., Red Hat Enterprise Linux 9)
    ...    - version: Version for JSON/template lookup (e.g., 2.0.0)
    ...    - profile_name: Specific profile name (optional, auto-detected from JSON if not provided)
    ...    - scan_template: Scan template type (e.g., cis, disa)
    ...    - service: Service type (e.g., ssh, cifs)
    ...    - scope: Scope (e.g., S for STIG)
    ...    - site_name: Name for the site
    ...    - template_name: Name for the scan template
    ...    - csv_file: Path to CSV validation rules file
    ...    - policy_list: Policies to include (default: all)
    ...    - engine_id: Specific engine ID to use (optional)
    ...    - site_id: Existing site ID to update (optional, creates new if not provided)
    ...    - validate_compliance: Whether to validate compliance (default: ${TRUE})
    ...    - expected_vuln_count: Expected vulnerability count for compliance (default: 0)
    ...    
    ...    EXAMPLE:
    ...    Run Complete E2E Benchmark Test
    ...        benchmark=CIS
    ...        vm_os=RHEL
    ...        vm_version=9
    ...        vm_cred_types=server
    ...        os_name=Red Hat Enterprise Linux 9
    ...        version=2.0.0
    ...        scan_template=cis
    ...        service=ssh
    ...        ...
    ...    
    ...    RETURNS:
    ...    Dictionary with test results including scan_id, report_id, validation results
    
    [Arguments]    
    ...    ${benchmark}
    ...    ${vm_os}
    ...    ${vm_version}
    ...    @{vm_cred_types}
    ...    ${os_name}
    ...    ${version}
    ...    ${scan_template}
    ...    ${service}
    ...    ${scope}
    ...    ${site_name}
    ...    ${template_name}
    ...    ${csv_file}
    ...    ${profile_name}=${EMPTY}
    ...    ${policy_list}=all
    ...    ${engine_id}=${EMPTY}
    ...    ${site_id}=${EMPTY}
    ...    ${validate_compliance}=${TRUE}
    ...    ${expected_vuln_count}=0
    
    # Initialize results dictionary
    ${results}=    Create Dictionary
    ${created_site_id}=    Set Variable    ${EMPTY}
    ${template_id}=    Set Variable    ${EMPTY}
    
    # Step 0: Get policies from JSON file based on benchmark, OS, and version
    ${policy_info}=    Get Policies From JSON    ${benchmark}    ${os_name}    ${version}
    
    # Determine which profile to use
    ${available_policies}=    Set Variable    ${policy_info}[policies]
    
    IF    '${profile_name}' == '${EMPTY}'
        # Use first available policy if profile_name not specified
        ${profile}=    Set Variable    ${available_policies}[0]
        Log    Auto-selected profile: ${profile}    console=True
    ELSE
        # Use specified profile_name - need to find matching policy ID
        ${profile_found}=    Set Variable    ${FALSE}
        FOR    ${policy}    IN    @{available_policies}
            # Extract profile name from policy ID (e.g., xccdf_org.cisecurity.benchmarks_profile_Level_1_-_Server -> Level 1 - Server)
            ${extracted_name}=    Evaluate    $policy.split('_profile_')[-1].replace('_', ' ') if '_profile_' in $policy else $policy
            ${name_matches}=    Evaluate    '''${extracted_name}''' == '''${profile_name}'''
            IF    ${name_matches}
                ${profile}=    Set Variable    ${policy}
                ${profile_found}=    Set Variable    ${TRUE}
                Log    Matched profile: ${profile}    console=True
                BREAK
            END
        END
        IF    not ${profile_found}
            Fail    Profile "${profile_name}" not found in available policies: ${available_policies}
        END
    END
    
    Set To Dictionary    ${results}    profile=${profile}
    Set To Dictionary    ${results}    available_policies=${available_policies}
    Set To Dictionary    ${results}    policy_info=${policy_info}
    
    # Step 1: Login
    ${session_id}=    Execute Login Step
    Set To Dictionary    ${results}    session_id    ${session_id}
    
    # Step 2: Get Engine (if not provided)
    ${selected_engine_id}=    Execute Engine Selection Step    ${engine_id}
    Set To Dictionary    ${results}    engine_id    ${selected_engine_id}
    
    # Step 3: Process Template
    ${template_result}=    Execute Template Processing Step
    ...    ${scan_template}
    ...    ${os_name}
    ...    ${version}
    ...    ${policy_list}
    ...    ${template_name}
    
    ${template_id}=    Set Variable    ${template_result}[template_id]
    Set To Dictionary    ${results}    template_id    ${template_id}
    Set To Dictionary    ${results}    formatted_policies    ${template_result}[formatted_policies]
    Set To Dictionary    ${results}    policy_count    ${template_result}[policy_count]
    
    # Step 4: Create or Update Site
    ${created_site_id}=    Execute Site Creation Step
    ...    ${site_name}
    ...    ${selected_engine_id}
    ...    ${template_result}[template_id]
    ...    ${benchmark}
    ...    ${vm_os}
    ...    ${vm_version}
    ...    ${service}
    ...    ${scope}
    ...    ${site_id}
    ...    @{vm_cred_types}
    
    Set To Dictionary    ${results}    site_id    ${created_site_id}
    
    # Step 5: Start Scan
    ${scan_result}=    Execute Scan Start Step
    ...    ${created_site_id}
    ...    ${selected_engine_id}
    ...    ${site_name}
    
    Set To Dictionary    ${results}    scan_id    ${scan_result}[scan_id]
    
    # Step 6: Monitor Scan
    ${monitor_result}=    Execute Scan Monitoring Step
    ...    ${scan_result}[scan_id]
    ...    ${created_site_id}
    
    Set To Dictionary    ${results}    scan_status    ${monitor_result}[status]
    Set To Dictionary    ${results}    scan_elapsed_time    ${monitor_result}[elapsed_time]
    
    # Step 7: Validate Scan Completion
    ${scan_details}=    Execute Scan Validation Step
    ...    ${scan_result}[scan_id]
    ...    ${created_site_id}
    ...    ${validate_compliance}
    ...    ${expected_vuln_count}
    
    Set To Dictionary    ${results}    scan_details    ${scan_details}
    
    # Step 8: Get Policy Natural ID (for first policy)
    ${policy_natural_ids}=    Execute Policy Natural ID Retrieval Step
    ...    ${template_result}[formatted_policies]
    
    Set To Dictionary    ${results}    policy_natural_ids    ${policy_natural_ids}
    
    # Step 9: Generate Report
    ${report_result}=    Execute Report Generation Step
    ...    ${created_site_id}
    ...    ${policy_natural_ids}
    
    Set To Dictionary    ${results}    report_ids    ${report_result}[report_ids]
    
    # Step 10: Validate Report from CSV
    ${validation_result}=    Execute Report Validation Step
    ...    ${report_result}[report_ids]
    ...    ${csv_file}
        
    Set To Dictionary    ${results}    validation_passed    ${validation_result}[passed]
    Set To Dictionary    ${results}    validation_failed    ${validation_result}[failed]
    Set To Dictionary    ${results}    os_name    ${os_name}
    Set To Dictionary    ${results}    benchmark    ${benchmark}
    Set To Dictionary    ${results}    version    ${version}
    
    # Step 11: Validate Compliance Results
    Validate Compliance Results
    ...    os_name=${os_name}
    ...    benchmark=${benchmark}
    ...    version=${version}
    ...    validation_passed=${validation_result}[passed]
    ...    validation_failed=${validation_result}[failed]
    
    RETURN    ${results}


Execute Login Step
    [Documentation]    Step 1: Login to Console
    Log    ========================================    console=True
    Log    STEP 1: LOGGING IN TO CONSOLE    console=True
    Log    ========================================    console=True
    
    ${session_id}=    Login To Console
    Log    ✓ Successfully obtained Session ID: ${session_id}    console=True
    Log    ========================================    console=True
    
    RETURN    ${session_id}


Execute Engine Selection Step
    [Documentation]    Step 2: Get Available Scan Engines
    [Arguments]    ${engine_id}
    
    Log    ========================================    console=True
    Log    STEP 2: SELECTING SCAN ENGINE    console=True
    Log    ========================================    console=True
    
    # Use provided engine_id or get available engines
    IF    '${engine_id}' == '${EMPTY}'
        ${engine_ids}=    Get Available Engines
        Log    Available Engines: ${engine_ids}    console=True
        
        ${engine_count}=    Get Length    ${engine_ids}
        ${selected_engine_id}=    Set Variable If    ${engine_count} > 0    ${engine_ids}[0]    3
    ELSE
        ${selected_engine_id}=    Set Variable    ${engine_id}
    END
    
    Log    ✓ Selected Engine ID: ${selected_engine_id}    console=True
    Log    ========================================    console=True
    
    RETURN    ${selected_engine_id}


Execute Template Processing Step
    [Documentation]    Step 3: Process template and create scan template
    [Arguments]    ${scan_template}    ${os_name}    ${version}    ${policy_list}    ${template_name}
    
    Log    ========================================    console=True
    Log    STEP 3: PROCESSING SCAN TEMPLATE    console=True
    Log    ========================================    console=True
    Log    OS Name: ${os_name}    console=True
    Log    Version: ${version}    console=True
    Log    Policies: ${policy_list}    console=True
    Log    Template Name: ${template_name}    console=True
    Log    ========================================    console=True
    
    # Process template
    ${template_result}=    Process Template For OS
    ...    ${scan_template}
    ...    ${os_name}
    ...    ${version}
    ...    ${policy_list}
    ...    ${template_name}
    
    Log    Template processing complete. Deprecated count: ${template_result}[deprecated_count]    console=True
    
    # Log formatted policies
    ${formatted_policies}=    Set Variable    ${template_result}[formatted_policies]
    ${policy_count}=    Get Length    ${formatted_policies}
    
    Log    ========================================    console=True
    Log    POLICIES (${policy_count} total):    console=True
    FOR    ${policy}    IN    @{formatted_policies}
        Log    ${policy}    console=True
    END
    Log    ========================================    console=True
    
    # Create scan template
    ${template_xml}=    Set Variable    ${template_result}[template_xml]
    ${create_result}=    Create Scan Template    ${template_xml}    ${template_name}
    ${scan_template_id}=    Set Variable    ${create_result}[template_id]
    
    Log    ✓ Template created - ID: ${scan_template_id}, Title: ${create_result}[template_title]    console=True
    Log    ========================================    console=True
    
    # Return results with template ID
    ${result}=    Create Dictionary
    ...    template_id=${scan_template_id}
    ...    formatted_policies=${formatted_policies}
    ...    policy_count=${policy_count}
    ...    deprecated_count=${template_result}[deprecated_count]
    
    RETURN    ${result}


Execute Site Creation Step
    [Documentation]    Step 4: Create or update site with VM configuration
    ...    Uses VM config path directly (e.g., CIS → RHEL → 9 → server)
    [Arguments]    
    ...    ${site_name}
    ...    ${engine_id}
    ...    ${scan_template_id}
    ...    ${benchmark}
    ...    ${vm_os}
    ...    ${vm_version}
    ...    ${service}
    ...    ${scope}
    ...    ${site_id}
    ...    @{vm_cred_types}
    
    Log    ========================================    console=True
    Log    STEP 4: CREATING/UPDATING SITE    console=True
    Log    ========================================    console=True
    Log    Site Name: ${site_name}    console=True
    Log    Engine ID: ${engine_id}    console=True
    Log    Template ID: ${scan_template_id}    console=True
    Log    VM Config Path: ${benchmark} → ${vm_os} → ${vm_version} → @{vm_cred_types}    console=True
    Log    ========================================    console=True
    
    # Determine if we're creating or updating
    IF    '${site_id}' != '${EMPTY}'
        Log    Updating existing site ID: ${site_id}    console=True
        ${result_site_id}=    Update Site With VM Config
        ...    ${site_id}
        ...    ${site_name}
        ...    ${benchmark}
        ...    ${vm_os}
        ...    ${vm_version}
        ...    @{vm_cred_types}
        ...    scan_template=${scan_template_id}
        ...    service=${service}
        ...    scope=${scope}
        ...    engine_id=${engine_id}
    ELSE
        Log    Creating new site    console=True
        ${result_site_id}=    Create Site With VM Config
        ...    ${site_name}
        ...    ${benchmark}
        ...    ${vm_os}
        ...    ${vm_version}
        ...    @{vm_cred_types}
        ...    scan_template=${scan_template_id}
        ...    service=${service}
        ...    scope=${scope}
        ...    engine_id=${engine_id}
    END
    
    Log    ✓ Site ID: ${result_site_id}    console=True
    Log    ========================================    console=True
    
    RETURN    ${result_site_id}


Execute Scan Start Step
    [Documentation]    Step 5: Start scan on the site
    [Arguments]    ${site_id}    ${engine_id}    ${site_name}
    
    Log    ========================================    console=True
    Log    STEP 5: STARTING SCAN    console=True
    Log    ========================================    console=True
    Log    Site ID: ${site_id}    console=True
    Log    Engine ID: ${engine_id}    console=True
    Log    ========================================    console=True
    
    ${scan_result}=    scan_operations.Start Scan    ${site_id}    ${engine_id}    ${site_name}
    ${scan_id}=    Set Variable    ${scan_result}[scan_id]
    
    Log    ✓ Scan started - Scan ID: ${scan_id}    console=True
    Log    ========================================    console=True
    
    RETURN    ${scan_result}


Execute Scan Monitoring Step
    [Documentation]    Step 6: Monitor scan until completion
    [Arguments]    ${scan_id}    ${site_id}    ${poll_interval}=5    ${timeout}=7200    ${log_interval}=60
    
    Log    ========================================    console=True
    Log    STEP 6: MONITORING SCAN PROGRESS    console=True
    Log    ========================================    console=True
    Log    Scan ID: ${scan_id}    console=True
    Log    Polling every ${poll_interval}s, logging every ${log_interval}s    console=True
    Log    ========================================    console=True
    
    ${monitor_result}=    scan_operations.Monitor Scan Until Complete
    ...    ${scan_id}
    ...    ${site_id}
    ...    poll_interval=${poll_interval}
    ...    log_interval=${log_interval}
    
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
    Should Be Equal As Strings    ${final_status}    finished
    ...    msg=Scan should complete with 'finished' status
    
    RETURN    ${monitor_result}


Execute Scan Validation Step
    [Documentation]    Step 7: Validate scan completion and check vulnerability count
    [Arguments]    ${scan_id}    ${site_id}    ${validate_compliance}    ${expected_vuln_count}
    
    Log    ========================================    console=True
    Log    STEP 7: VALIDATING SCAN RESULTS    console=True
    Log    ========================================    console=True
    
    ${scan_details}=    scan_operations.Get Scan Details    ${scan_id}    ${site_id}
    Log    Scan Details: ${scan_details}    console=True
    
    # Validate vulnerability count if compliance validation is enabled
    IF    ${validate_compliance}
        ${has_vulnerabilities}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${scan_details}    vulnerabilities
        
        IF    ${has_vulnerabilities}
            ${vuln_count}=    Set Variable    ${scan_details}[vulnerabilities]
            Log    Vulnerability Count: ${vuln_count}    console=True
            
            ${vuln_count_int}=    Convert To Integer    ${vuln_count}
            Should Be Equal As Integers    ${vuln_count_int}    ${expected_vuln_count}
            ...    msg=COMPLIANCE FAILED: Expected ${expected_vuln_count} vulnerabilities but found ${vuln_count_int}
            
            Log    ✓ COMPLIANCE PASSED: Vulnerability count is ${expected_vuln_count}    console=True
        ELSE
            Log    Warning: Vulnerabilities field not found in scan statistics    console=True
        END
    END
    
    Log    ========================================    console=True
    
    RETURN    ${scan_details}


Execute Policy Natural ID Retrieval Step
    [Documentation]    Step 8: Get surrogate identifier for first policy
    [Arguments]    ${formatted_policies}
    
    Log    ========================================    console=True
    Log    STEP 8: GETTING POLICY NATURAL ID (FIRST POLICY)    console=True
    Log    ========================================    console=True
    
    &{policy_natural_ids}=    Create Dictionary
    
    # Get only the first policy
    ${first_policy}=    Set Variable    ${formatted_policies}[0]
    Log    Processing first policy: ${first_policy}    console=True
    
    ${surrogate_response}=    scan_template_api.Get Policy Surrogate Identifier    ${first_policy}
    
    # Extract policy ID from formatted string (benchmark_id:version:policy_id)
    @{policy_parts}=    Split String    ${first_policy}    :
    ${policy_id}=    Set Variable    ${policy_parts}[2]
    
    # Extract policy name from policy ID
    ${policy_name}=    Evaluate
    ...    $policy_id.split('_profile_')[-1] if '_profile_' in $policy_id else $policy_id
    
    # Convert to lowercase and replace spaces/special chars
    ${policy_var_name}=    Evaluate
    ...    'profile_' + $policy_name.lower().replace('-', '_').replace(' ', '_')
    
    # Store natural ID in dictionary
    Set To Dictionary    ${policy_natural_ids}    ${policy_var_name}    ${surrogate_response}[natural_id]
    
    Log    ✓ Policy: ${first_policy}    console=True
    Log    ✓ Variable Name: ${policy_var_name}    console=True
    Log    ✓ Natural ID: ${surrogate_response}[natural_id]    console=True
    Log    ========================================    console=True
    
    RETURN    ${policy_natural_ids}


Execute Report Generation Step
    [Documentation]    Step 9: Generate XCCDF report for first policy
    [Arguments]    ${site_id}    ${policy_natural_ids}
    
    Log    ========================================    console=True
    Log    STEP 9: GENERATING XCCDF REPORT (FIRST POLICY)    console=True
    Log    ========================================    console=True
    
    ${report_ids}=    Create Dictionary
    
    # Get first policy from dictionary
    ${var_name}=    Evaluate    list($policy_natural_ids.keys())[0]
    ${natural_id}=    Get From Dictionary    ${policy_natural_ids}    ${var_name}
    
    # Create descriptive report name with timestamp to avoid collisions
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${report_name}=    Set Variable    XCCDF_Report_${var_name}_${timestamp}
    
    Log    Policy Variable: ${var_name}    console=True
    Log    Natural ID: ${natural_id}    console=True
    Log    Report Name: ${report_name}    console=True
    Log    ========================================    console=True
    
    # Generate report
    ${report_result}=    report_operations.Generate XCCDF Report For Policy
    ...    site_id=${site_id}
    ...    policy_natural_id=${natural_id}
    ...    report_name=${report_name}
    
    # Store report ID
    Set To Dictionary    ${report_ids}    ${var_name}    ${report_result}[report_id]
    
    Log    ✓ Report ID: ${report_result}[report_id]    console=True
    Log    ========================================    console=True
    
    ${result}=    Create Dictionary    report_ids=${report_ids}
    RETURN    ${result}


Execute Report Validation Step
    [Documentation]    Step 10: Download report and validate from CSV
    [Arguments]    ${report_ids}    ${csv_file}
    
    Log    ========================================    console=True
    Log    STEP 10: VALIDATING REPORT FROM CSV    console=True
    Log    ========================================    console=True
    Log    CSV File: ${csv_file}    console=True
    Log    ========================================    console=True
    
    # Get first report ID
    ${var_name}=    Evaluate    list($report_ids.keys())[0]
    ${report_id}=    Get From Dictionary    ${report_ids}    ${var_name}
    
    Log    Checking report status for Report ID: ${report_id}    console=True
    
    # Get report status
    ${status_result}=    report_operations.Get Report Status    ${report_id}
    
    # Check if report has been generated
    ${has_latest}=    Run Keyword And Return Status
    ...    Dictionary Should Contain Key    ${status_result}    latest_status
    
    IF    ${has_latest}
        Log    Latest Report ID: ${status_result}[latest_report_id]    console=True
        Log    Latest Status: ${status_result}[latest_status]    console=True
        
        # Wait for report to complete
        ${max_attempts}=    Set Variable    12
        ${attempt}=    Set Variable    0
        
        WHILE    '${status_result}[latest_status]' == 'Started' and ${attempt} < ${max_attempts}
            ${attempt}=    Evaluate    ${attempt} + 1
            Log    ⏳ Report generating (Attempt ${attempt}/${max_attempts}), waiting 10s...    console=True
            Sleep    10s
            
            # Try to get status with error handling for connection issues
            TRY
                ${status_result}=    report_operations.Get Report Status    ${report_id}
                Log    Latest Status: ${status_result}[latest_status]    console=True
            EXCEPT    AS    ${error}
                Log    ⚠️ Error checking status: ${error}    console=True
                Log    Will retry on next iteration...    console=True
                # Re-login to get fresh session on connection error
                ${new_session}=    login.Login To Console
                Log    ✓ Re-authenticated with new session    console=True
            END
        END
        
        # Verify report completed
        Should Not Be Equal    ${status_result}[latest_status]    Started
        ...    msg=Report generation did not complete within 2 minutes
        
        # Download report
        Log    Downloading report...    console=True
        ${download_result}=    report_operations.Download Report
        ...    report_config_id=${report_id}
        ...    report_instance_id=${status_result}[latest_report_id]
        
        Log    Downloaded Report Size: ${download_result}[content_length] bytes    console=True
        
        # Validate using CSV file
        ${passed}    ${failed}    ${results}=    report_operations.Validate Report From Excel
        ...    excel_path=${csv_file}
        ...    xml_content=${download_result}[report_content]
        ...    file_type=csv
        
        Log    ========================================    console=True
        Log    ✅ VALIDATION COMPLETE    console=True
        Log    Passed: ${passed} ✓    console=True
        Log    Failed: ${failed} ✗    console=True
        Log    ========================================    console=True
        
        ${validation_result}=    Create Dictionary    passed=${passed}    failed=${failed}
        RETURN    ${validation_result}
    ELSE
        Fail    Report generation did not start or complete
    END


Validate Compliance Results
    [Documentation]    Validate compliance test results and assert all controls passed
    ...    
    ...    This keyword validates that all security controls passed compliance testing.
    ...    It provides OS-specific failure messages for better traceability.
    ...    
    ...    Arguments:
    ...    - os_name: Operating system name (e.g., Red Hat Enterprise Linux 9, Ubuntu Linux 20.04 LTS)
    ...    - benchmark: Benchmark standard (e.g., CIS, DISA)
    ...    - version: Benchmark version (e.g., 2.0.0, 3.0.0)
    ...    - validation_passed: Number of controls that passed
    ...    - validation_failed: Number of controls that failed
    ...    
    ...    Fails the test if any controls failed validation.
    [Arguments]    ${os_name}    ${benchmark}    ${version}    ${validation_passed}    ${validation_failed}
    
    Log    ════════════════════════════════════════════════════════    console=True
    Log    COMPLIANCE VALIDATION RESULTS    console=True
    Log    ════════════════════════════════════════════════════════    console=True
    Log    Target OS: ${os_name}    console=True
    Log    Benchmark: ${benchmark} v${version}    console=True
    Log    Controls Passed: ${validation_passed} ✓    console=True
    Log    Controls Failed: ${validation_failed} ✗    console=True
    Log    ════════════════════════════════════════════════════════    console=True
    
    # Assert all controls passed
    Should Be Equal As Integers    ${validation_failed}    0
    ...    msg=${os_name} ${benchmark} v${version} compliance test FAILED: ${validation_failed} security control(s) did not meet compliance requirements. Expected all controls to pass but ${validation_failed} failed validation.


Cleanup Test Resources
    [Documentation]    Cleanup - Delete site and scan template after test execution
    ...    
    ...    This keyword deletes the site and template created during the test,
    ...    regardless of whether the test passed or failed. This ensures
    ...    no orphaned resources remain in the console.
    ...    
    ...    Should be used as [Teardown] in test cases.
    ...    
    ...    Arguments:
    ...    - site_id: Site ID to delete
    ...    - template_id: Scan template ID to delete
    [Arguments]    ${site_id}    ${template_id}
    
    Log    ========================================    console=True
    Log    CLEANUP: DELETING TEST RESOURCES    console=True
    Log    ========================================    console=True
    
    # Delete site if it was created
    IF    '${site_id}' != '${EMPTY}'
        TRY
            Log    Deleting site: ${site_id}    console=True
            site.Delete Site    ${site_id}
            Log    ✓ Site deleted successfully    console=True
        EXCEPT    AS    ${error}
            Log    ⚠️ Failed to delete site ${site_id}: ${error}    console=True
            Log    Site may need manual cleanup    console=True
        END
    ELSE
        Log    No site to delete (site_id is empty)    console=True
    END
    
    # Delete scan template if it was created
    IF    '${template_id}' != '${EMPTY}'
        TRY
            Log    Deleting scan template: ${template_id}    console=True
            Delete Scan Template    ${template_id}
            Log    ✓ Scan template deleted successfully    console=True
        EXCEPT    AS    ${error}
            Log    ⚠️ Failed to delete template ${template_id}: ${error}    console=True
            Log    Template may need manual cleanup    console=True
        END
    ELSE
        Log    No template to delete (template_id is empty)    console=True
    END
    
    Log    ========================================    console=True
    Log    ✓ CLEANUP COMPLETE    console=True
    Log    ========================================    console=True


Delete Scan Template
    [Documentation]    Delete a scan template by template ID using REST API v3
    ...    
    ...    Arguments:
    ...    - template_id: Scan template ID to delete (e.g., "acme-cis-rhel9-template")
    ...    
    ...    Returns: Success confirmation
    ...    
    ...    Example: Delete Scan Template    my-custom-template-123
    [Arguments]    ${template_id}
    
    # Validate session
    ${session_valid}=    Run Keyword And Return Status    Should Not Be Equal    ${SESSION_ID}    ${EMPTY}
    
    IF    not ${session_valid}
        Login To Console
    END
    
    # Prepare headers
    ${headers}=    Create Dictionary
    ...    Content-Type=application/json
    ...    Cookie=nexposeCCSessionID=${SESSION_ID}
    
    Log    ========================================    console=True
    Log    DELETING SCAN TEMPLATE    console=True
    Log    Template ID: ${template_id}    console=True
    Log    ========================================    console=True
    
    # Send DELETE request
    ${response}=    DELETE
    ...    ${BASE_URL}/api/3/scan_templates/${template_id}
    ...    headers=${headers}
    ...    verify=${False}
    ...    expected_status=any
    
    Log    ========================================    console=True
    Log    DELETE TEMPLATE RESPONSE    console=True
    Log    Status Code: ${response.status_code}    console=True
    Log    Response Body: ${response.text}    console=True
    Log    ========================================    console=True
    
    # Validate status code (200 or 204 for successful deletion)
    ${is_success}=    Evaluate    ${response.status_code} in [200, 204]
    Should Be True    ${is_success}
    ...    msg=Failed to delete template ${template_id}. Status Code: ${response.status_code}, Response: ${response.text}
    
    Log    ========================================    console=True
    Log    ✓ SCAN TEMPLATE DELETED SUCCESSFULLY    console=True
    Log    Template ID: ${template_id}    console=True
    Log    Status Code: ${response.status_code}    console=True
    Log    ========================================    console=True
    
    RETURN    ${response.text}
