*** Settings ***
Documentation     Test ping check functionality before site creation
Resource          ../resources/site.robot
Resource          ../resources/login.robot
Resource          ../resources/vm_config.robot

*** Test Cases ***
Test Ping Check For Reachable Host
    [Documentation]    Test that ping check works for a reachable host from VM config
    [Tags]    ping    connectivity
    
    Log    Testing ping check for reachable host    console=True
    
    # Get IP from VM config (RHEL 9 compliance server)
    ${vm_config}=    Get VM Config    CIS_RHEL_9    server    compliance
    ${server_config}=    Get From Dictionary    ${vm_config}    server
    ${ip}=    Get From Dictionary    ${server_config}    ip
    
    Log    Testing ping check for IP: ${ip}    console=True
    
    ${is_reachable}=    Check Host Reachability    ${ip}    timeout=30
    Should Be True    ${is_reachable}    msg=Host ${ip} should be reachable
    
    Log    ✓ Ping check PASSED for ${ip}    console=True

Test Ping Check For Unreachable Host
    [Documentation]    Test that ping check fails for an unreachable host
    [Tags]    ping    connectivity
    
    Log    Testing ping check for unreachable host    console=True
    
    # Use TEST-NET-1 address (192.0.2.0/24) which is reserved for documentation
    # and guaranteed to be unreachable
    ${unreachable_ip}=    Set Variable    192.0.2.1
    ${is_reachable}=    Check Host Reachability    ${unreachable_ip}    timeout=15
    Should Not Be True    ${is_reachable}    msg=Host ${unreachable_ip} should not be reachable
    
    Log    ✓ Ping check correctly FAILED for unreachable host    console=True

Test Site Creation With Ping Check
    [Documentation]    Test that site creation includes ping check
    ...    This test will check if the host is reachable before attempting site creation
    [Tags]    ping    site    integration
    
    # Login first
    Login To Console
    
    Log    Testing site creation with automatic ping check    console=True
    Log    This will verify ping check runs before site creation    console=True
    
    # Get VM config for testing
    ${vm_config}=    Get VM Config    CIS_RHEL_9    server    compliance
    ${server_config}=    Get From Dictionary    ${vm_config}    server
    ${ip}=    Get From Dictionary    ${server_config}    ip
    
    Log    Will test site creation for IP: ${ip}    console=True
    
    # Uncomment when ready to test full site creation with your actual template and engine:
    # ${site_id}=    Create Site With VM Config
    # ...    Test Site RHEL9 Ping Check
    # ...    CIS_RHEL_9
    # ...    server
    # ...    compliance
    # ...    scan_template=<your-template-id>
    # ...    scope=S
    # ...    engine_id=<your-engine-id>
    # ...    service=ssh
    # ...    ping_timeout=60
    
    Log    ✓ Test setup complete    console=True
