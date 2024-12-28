import pygame
import psutil  # For CPU usage
import subprocess  # For pinging
import time
import socket

# Initialize Pygame
pygame.init()

# Set up display
screen_width = 128  # Adjust according to your OLED screen resolution
screen_height = 64  # Adjust according to your OLED screen resolution
screen = pygame.display.set_mode((screen_width, screen_height))

# Set up font
font = pygame.font.SysFont("times", 15)

# Initial screen index
screen_index = 0  # Controls which screen is displayed

# Function to check ping/latency to the master node
def get_connection_status():
    try:
        response = subprocess.run(['ping', '-c', '1', '192.168.1.1'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if response.returncode == 0:
            ping_time = float(response.stdout.decode().split('time=')[1].split(' ')[0])
            return f"Connected: {round(ping_time)} ms"
        else:
            return "Disconnected"
    except (IndexError, ValueError):
        return "Disconnected"

# Function to check if there's a breach risk
def get_breach_status():
    try:
        with open("/tmp/security_status", "r") as status_file:
            return status_file.read().strip()
    except FileNotFoundError:
        return None  # If the file doesn't exist, there's no breach

# Main loop
running = True
while running:
    screen.fill((0, 0, 0))  # Clear the screen
    
    # Check if there's a breach
    breach_status = get_breach_status()
    
    # Display breach message if there's a breach
    if breach_status == "BREACH" and screen_index % 2 == 0:  # Only show every other screen
        breach_text = font.render("--Breach Risk--", True, (255, 0, 0))  # Red text for breach
        screen.blit(breach_text, (10, 10))
        pygame.display.flip()
        time.sleep(1)  # Show breach for 1 second

    else:
        # Display other screens normally
        if screen_index == 1:
            hostname = socket.gethostname()
            text = font.render(f"{hostname}", True, (255, 255, 255))
            screen.blit(text, (10, 10))

        elif screen_index == 3:
            connection_status = get_connection_status()
            text = font.render(connection_status, True, (255, 255, 255))
            screen.blit(text, (10, 10))

        elif screen_index == 5:
            cpu_usage = psutil.cpu_percent(interval=1)
            cpu_text = font.render(f"CPU: {cpu_usage}%", True, (255, 255, 255))
            screen.blit(cpu_text, (10, 10))

        pygame.display.flip()
        time.sleep(1)

    # Event handling
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    # Cycle through screens
    screen_index += 1
    if screen_index > 5:  # Cycle back after the last screen
        screen_index = 1

# Quit Pygame
pygame.quit()
