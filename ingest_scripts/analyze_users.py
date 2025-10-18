import pandas as pd
import json
import os

print("--- Starting data analysis script ---")

# Define the path to the input file
input_file = os.path.join("raw_data", "raw_users.json")

# --- 1. Load the Data ---
try:
    with open(input_file, 'r') as f:
        users_data = json.load(f)
    print(f"Successfully loaded data from {input_file}")
    
    # Convert the list of dictionaries into a Pandas DataFrame
    df = pd.DataFrame(users_data)
    print("Data loaded into Pandas DataFrame.")

except FileNotFoundError:
    print(f"Error: The file {input_file} was not found.")
    exit()

# --- 2. Explore the Data ---
print("\n--- Basic Data Exploration ---")

# Print the first 5 rows of the table
print("\nFirst 5 rows of data (df.head()):")
print(df.head())

# Print a summary of the DataFrame (data types, non-null counts)
print("\nDataFrame Info (df.info()):")
df.info()

# --- 3. A Simple Analysis ---
print("\n--- Simple Analysis: User's Company Names ---")
# Select and display just the 'name' and 'company' columns
# Note: The 'company' column contains another dictionary. We need to extract the 'name' from it.
df['company_name'] = df['company'].apply(lambda company_dict: company_dict['name'])

# Display the names and their company names
print(df[['name', 'company_name']].head(10))


print("\n--- Analysis script finished ---")