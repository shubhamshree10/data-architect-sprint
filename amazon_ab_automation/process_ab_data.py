import pandas as pd
import os

print("--- Starting data consolidation script ---")

# Define the folder where our input files are located
input_folder = "input_data"

# List the specific files we want to process
file_names = [
    "mock_monthly_data.xlsx",
    "mock_last_week_data.xlsx",
    "mock_this_week_data.xlsx"
]

# Create an empty list to hold each file's data (as a DataFrame)
list_of_dfs = []

print("Reading and collecting data from Excel files...")
for file in file_names:
    file_path = os.path.join(input_folder, file)
    try:
        # Read the current Excel file into a DataFrame
        df = pd.read_excel(file_path)
        # Add the DataFrame to our list
        list_of_dfs.append(df)
        print(f"  - Successfully read {file}")
    except FileNotFoundError:
        print(f"  - WARNING: File not found at {file_path}")

# Concatenate all the DataFrames in the list into one master DataFrame
master_df = pd.concat(list_of_dfs, ignore_index=True)

print("\nData successfully consolidated into a single DataFrame.")

# --- Display a summary of the master DataFrame ---
print("\n--- Master DataFrame Info ---")
master_df.info()

print("\n--- Master DataFrame Head ---")
print(master_df.head())

print("\n--- Consolidation script finished ---")

# --- 2. Clean and Filter Data ---
from datetime import date, timedelta

print("\n--- Cleaning and Filtering Data ---")

# Convert the 'date' column to a proper datetime format
# The errors='coerce' will turn any problematic dates into 'NaT' (Not a Time)
master_df['date'] = pd.to_datetime(master_df['date'], errors='coerce')
print("'date' column converted to datetime format.")

# Define the 7-week date range
today = date.today()
# End date is the most recent Friday
end_date = today - timedelta(days=today.weekday() + 3) 
# Start date is 7 weeks (49 days) before the end date
start_date = end_date - timedelta(days=48)

print(f"Filtering data between {start_date} and {end_date}...")

# Filter the DataFrame to keep only the rows within our date range
filtered_df = master_df[
    (master_df['date'].dt.date >= start_date) & 
    (master_df['date'].dt.date <= end_date)
].copy()

print("\nData successfully filtered for the last 7 full weeks.")

# --- Display a summary of the filtered DataFrame ---
print("\n--- Filtered DataFrame Info ---")
filtered_df.info()

print("\n--- Filtered DataFrame Head ---")
print(filtered_df.head())

print("\n--- Cleaning script finished ---")