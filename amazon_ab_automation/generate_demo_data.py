import pandas as pd
from faker import Faker
import random
from datetime import date, timedelta
import os

print("--- Starting demo data generation script ---")

fake = Faker()

def create_mock_data(start_date, num_rows):
    """Generates a DataFrame with mock A/B test data."""
    data = []
    for i in range(num_rows):
        current_date = start_date + timedelta(days=i % 30)
        data.append({
            'date': current_date,
            'user_id': fake.uuid4(),
            'variant': random.choice(['Control', 'Treatment']),
            'metric_C': random.randint(100, 1000),
            'metric_D': random.uniform(0.1, 5.0),
            'conversions': random.choice([0, 1])
        })
    return pd.DataFrame(data)

# --- Define file names and date ranges ---
output_folder = "input_data"
today = date.today()
first_of_month = today.replace(day=1)
end_of_last_week = today - timedelta(days=today.weekday() + 2)
start_of_last_week = end_of_last_week - timedelta(days=6)
start_of_this_week = today - timedelta(days=today.weekday())

# --- THIS IS THE NEW LINE ---
# Create the output folder if it doesn't exist
os.makedirs(output_folder, exist_ok=True)

# --- Generate and Save the Files ---
print("Generating mock data files...")
df_monthly = create_mock_data(start_date=first_of_month, num_rows=8000)
df_monthly.to_excel(os.path.join(output_folder, "mock_monthly_data.xlsx"), index=False)

df_last_week = create_mock_data(start_date=start_of_last_week, num_rows=1000)
df_last_week.to_excel(os.path.join(output_folder, "mock_last_week_data.xlsx"), index=False)

df_this_week = create_mock_data(start_date=start_of_this_week, num_rows=500)
df_this_week.to_excel(os.path.join(output_folder, "mock_this_week_data.xlsx"), index=False)

print(f"--- Demo data successfully generated in '{output_folder}' folder. ---")