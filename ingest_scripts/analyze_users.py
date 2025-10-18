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

# --- 4. Visualize the Data ---
import matplotlib.pyplot as plt

print("\n--- Creating Visualization ---")

try:
    # The 'address' column is a dictionary, so we extract the 'city' from it
    city_counts = df['address'].apply(lambda addr: addr.get('city')).value_counts()

    # Create a bar chart
    plt.figure(figsize=(10, 6)) # Set the figure size
    city_counts.plot(kind='bar')
    plt.title('Number of Users by City')
    plt.ylabel('Number of Users')
    plt.xlabel('City')
    plt.xticks(rotation=45, ha='right') # Rotate city names for better readability
    plt.tight_layout() # Adjust layout to make room for labels

    # Save the chart to a file
    output_viz_file = "user_city_distribution.png"
    plt.savefig(output_viz_file)
    
    print(f"Chart successfully saved to {output_viz_file}")

except Exception as e:
    print(f"An error occurred during visualization: {e}")

print("\n--- Practice Exercises ---")

# Exercise 1: Extract the 'zipcode' from the 'address' column
print("\nExercise 1: User Zipcodes")
df['user_zip'] = df['address'].apply(lambda user_zipcode: user_zipcode.get('zipcode'))
print(df[['name','user_zip']].head(10))

# Exercise 2: Create a new DataFrame with only users from "South Christy"
print("\nExercise 2: Users from South Christy")


# Exercise 3: Create a new column to classify website type based on its ending
print("\nExercise 3: Website Type Classification")


print("\n--- Analysis script finished ---")