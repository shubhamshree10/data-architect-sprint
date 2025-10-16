import requests
import json
import os

print("--- Starting data ingestion script ---")

# The URL for the public API
API_URL = "https://jsonplaceholder.typicode.com/users"

# Define the path to save the output file
output_folder = "raw_data"
output_file = os.path.join(output_folder, "raw_users.json")

# Create the output folder if it doesn't exist
os.makedirs(output_folder, exist_ok=True)
print(f"Output will be saved to: {output_file}")

try:
    # Make the API request
    response = requests.get(API_URL)
    # Raise an exception if the request was unsuccessful
    response.raise_for_status() 
    print(f"Successfully fetched data from {API_URL}")

    # Get the JSON data from the response
    users_data = response.json()

    # Save the data to a file
    with open(output_file, 'w') as f:
        json.dump(users_data, f, indent=4)
    
    print(f"Data successfully saved to {output_file}")

except requests.exceptions.RequestException as e:
    print(f"An error occurred during the API request: {e}")

print("--- Ingestion script finished ---")