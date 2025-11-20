Pandas DataFrame MiniProject
============================

'''This code cleanses, standardize data and also removes duplicates'''

import pandas as pd
from datetime import datetime

#add lstrip and rstrip


def check_missing_values(df, column_name, df_name):
    """
    Checks for missing (NaN/None) values in the specified column of a DataFrame.
    """
    if column_name not in df.columns:
        print(f" Column '{column_name}' does not exist in the DataFrame.")
        return None

    missing_count = df[column_name].isna().sum()

    if missing_count > 0:
        print(f"  Column '{column_name}' has {missing_count} missing value(s).")
        print("Rows with missing values:")
        print(df[df[column_name].isna()])
    else:
        print(f" Column '{column_name}' has no missing values.")

    return missing_count

def check_email_validity(df, column_name,check_str, df_name):
    if not isinstance(df,pd.DataFrame):
        print(" Error: THe input df is not a pandas DataFrame")
        return

    if column_name not in df.columns:
        print(f"Column {column_name} not found in DataFrame.")

    v_count=0
    #v_count=df_stg_customers[column_name].str.find(check_str)
    v_count=(~df_stg_customers[column_name].str.contains(check_str, case=False, na=False)).sum()

    return v_count

def validate_column_length(df, column_name, expected_length, df_name):
    """
    Checks whether the values in a given column have the specified length (default = 15).
    Returns a DataFrame of invalid rows.
    """
    invalid_rows = 0
    if column_name not in df.columns:
        print(f" Column '{column_name}' not found in DataFrame.")
        return pd.DataFrame()

    if not isinstance(df, pd.DataFrame):
        print(" Error: The input 'df' is not a pandas DataFrame.")
        return
        
    if isinstance(df, pd.DataFrame) and df_name == "df_stg_customers" and column_name == "pincode":
        df_stg_customers["pincode"] = df_stg_customers["pincode"].round(0).astype(int)
        #print(df[column_name].astype(str).str.len().astype(int).head())
        #print("rounding done")

    if isinstance(df, pd.DataFrame) and df_name == "df_stg_customers" and column_name == "mobile":
        df_stg_customers["mobile"] = df_stg_customers["mobile"].round(0).astype(int)
        #print(df[column_name].astype(str).str.len().astype(int).head())
        #print("rounding done")        

    invalid_rows = df[df[column_name].astype(str).str.len() != expected_length]

    if not invalid_rows.empty:
        print(f" Invalid rows found in column '{column_name}':")
        print(invalid_rows[[column_name]])
    else:
        print(f" All entries in column '{column_name}' have length {expected_length}.")
        
    return invalid_rows

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

missing_count = check_missing_values(df_stg_customers, "pincode","df_stg_customers")
print(missing_count)
if missing_count == 0:
    validate_column_length(df_stg_customers, "pincode",6,"df_stg_customers")
    validate_column_length(df_stg_customers, "mobile",10,"df_stg_customers")
    #validate_column_length(df_stg_customers, "city")
else:
    print("column length check not triggered due to presence of missing values")

missing_count = check_missing_values(df_stg_customers, "mobile","df_stg_customers")
print(missing_count)
if missing_count == 0:
    validate_column_length(df_stg_customers, "mobile",10,"df_stg_customers")
else:
    print("column length check not triggered due to presence of missing values")

#invalid_email_count = check_email_validity(df_stg_customers, "email","df_stg_customers")
invalid_email_count=check_email_validity(df_stg_customers, "email","@","df_stg_customers")
if invalid_email_count>0:
    print(f"Invalid Email entries {invalid_email_count} found ")
else:
    print(f"Invalid Email entries {invalid_email_count} found ")


cols_to_display = ["customer_id","name","city","state","join_date"]
df_selected = df_stg_customers[cols_to_display]

df_selected = df_selected.drop_duplicates(subset=None, keep='first', inplace=False)

#df_selected.to_csv("stg_customers.csv", index=False)

#print("Transformed data written successfully to stg_customers.csv")
#print(df_selected.head())
