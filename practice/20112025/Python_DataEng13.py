Pandas DataFrame
================

Read employee.csv and Create a Pandas DataFrame
-----------------------------------------------
import pandas as pd

df = pd.read_csv("employee.csv")  #Creating Dataframe from employee.csv

print(df)  		 	 			  #Display DataFrame
print(df.info()) 	 			  #DataFrame Info
print(df.describe()) 			  #Summary Statistics
print(df.isnull().sum())  		  #Null Value Check

Referencing Dataframe columns 			  : DataFrame['column_name']   --> df_stg_customers['join_date']
Referencing Dataframe columns dynamically : DataFrame[column_name]     --> DataFrame[column_name]


Calling function
----------------

df_stg_customers['join_date'] = df_stg_customers['join_date'].apply(clean_and_format_date)

-Passing join_date as an argument to function clean_and_format_date
-apply method is used to call the function


The pandas.isna() function is used to detect missing or null values within pandas Series, DataFrames, or Index objects


'''This code cleanses, standardize data and also removes duplicates'''

import pandas as pd
from datetime import datetime

def validate_data(col_str):
    if pd.isna(col_str): #returns True if None, NaN, NaT
        return pd.NaN
    print(col_str)

def clean_and_format_date(date_str):
    #print("The value here is : " + str(date_str))
    '''Cleans and converts mixed-format date strings to DD-MON-YYYY format.
       Returns NaT if parsing fails.'''

    if pd.isna(date_str): #returns True if None, NaN, NaT
        return pd.NaT

    for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%d%m%Y"):  
        try:
            parsed_date = datetime.strptime(date_str, fmt)    #strptime() converts string   → datetime,
            return parsed_date.strftime("%d-%b-%Y").upper()   #strftime() converts datetime → string
        except ValueError:
            continue
    return pd.NaT  # Anything else becomes NULL

# Apply the function
df_stg_customers = pd.read_csv("customers.csv")
df_stg_customers['join_date'] = df_stg_customers['join_date'].apply(clean_and_format_date)

cols_to_display = ["customer_id","name","city","state","join_date"]
#print(df_stg_customers[cols_to_display])
df_selected = df_stg_customers[cols_to_display]


df_stg_customers['customer_id'].apply(validate_data)
#df_selected = df_selected.drop_duplicates()  #Pandas inbulit method
df_selected = df_selected.drop_duplicates(subset=None, keep='first', inplace=False)

# Write the transformed data to a new CSV file
df_selected.to_csv("stg_customers.csv", index=False)

# ✅ Confirm output
print("Transformed data written successfully to stg_customers.csv")
#print(df_selected.head())
