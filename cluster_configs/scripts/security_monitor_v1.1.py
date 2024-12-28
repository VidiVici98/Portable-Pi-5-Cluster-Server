import os
import time
import sys
import psutil  # Requires installation: pip install psutil

# Function to check for breaches
def check_for_breach():
    breach_detected = False
    # Placeholder for additional breach conditions
    # Example: Check privilege escalation or file tampering
    # breach_detected = True  # Uncomment to simulate a breach

    # Check resource usage
    resource_breach = check_resources()
    if resource_breach:
        breach_detected = True

    if breach_detected:
        with open("/tmp/security_status", "w") as status_file:
            status_file.write("BREACH")
    else:
        try:
            os.remove("/tmp/security_status")
        except FileNotFoundError:
            pass  # No file to remove if it's not there

# Function to check resource usage
def check_resources():
    high_usage_detected = False
    cpu_threshold = 80  # CPU usage percentage threshold
    memory_threshold = 90  # Memory usage percentage threshold

    # Check CPU usage
    cpu_usage = psutil.cpu_percent(interval=1)
    if cpu_usage > cpu_threshold:
        print(f"WARNING: High CPU usage detected: {cpu_usage}%")
        high_usage_detected = True

    # Check memory usage
    memory = psutil.virtual_memory()
    memory_usage = memory.percent
    if memory_usage > memory_threshold:
        print(f"WARNING: High memory usage detected: {memory_usage}%")
        high_usage_detected = True

    return high_usage_detected

# Function to run in test mode
def test_mode():
    print("Running in test mode. Checking for breaches...")
    check_for_breach()
    time.sleep(5)  # Wait a bit for testing purposes
    print("Test mode completed.")

# Function to run in passive mode
def passive_mode():
    print("Running in passive mode. Monitoring system without active enforcement...")
    while True:
        check_for_breach()  # Check for breaches periodically
        time.sleep(60)  # Adjust the frequency as needed

# Function to run in active mode
def active_mode():
    print("Running in active mode. Monitoring system and taking actions for breaches...")
    while True:
        check_for_breach()  # Check for breaches periodically
        if os.path.exists("/tmp/security_status"):  # If breach detected, show breach message
            print("BREACH DETECTED!")
        time.sleep(60)  # Adjust the frequency as needed

# Main function to parse command-line arguments and run in the appropriate mode
def main():
    mode = 'passive'  # Default mode

    if len(sys.argv) > 1:
        flag = sys.argv[1].lower()  # Get the flag from command line argument
        if flag == 'p':  # Passive mode
            mode = 'passive'
        elif flag == 'a':  # Active mode
            mode = 'active'
        elif flag == 't':  # Test mode
            mode = 'test'
        else:
            print(f"Unknown flag: {flag}. Defaulting to passive mode.")
    
    # Run the appropriate mode
    if mode == 'test':
        test_mode()
    elif mode == 'active':
        active_mode()
    elif mode == 'passive':
        passive_mode()

if __name__ == "__main__":
    main()
