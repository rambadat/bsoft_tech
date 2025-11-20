Pandas DataFrame MiniProject
============================

Staging Layer (Data Cleansing/Standardizing)
--------------------------------------------

'''This code cleanses, standardize data and also removes duplicates'''

import pandas as pd
from datetime import datetime

#add lstrip and rstrip

def values_individual_strip(df, column_name, df_name):
    if column_name not in df.columns:
        print(f" Column '{column_name}' does not exist in the DataFrame.")
        return None

    v_string = df[column_name].str.strip()

 

def check_missing_values(df, column_name, df_name):
    """
    Checks for missing (NaN/None) values in the specified column of a DataFrame.
    """
    if column_name not in df.columns:
        print(f" Column '{column_name}' does not exist in the DataFrame.")
        return None

    missing_count = df[column_name].isna().sum()
    #missing_count = df[column_name].count()

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

    for fmt in ("%m/%d/%Y","%Y-%m-%d", "%d-%m-%Y", "%d%m%Y"):  
        try:
            parsed_date = datetime.strptime(date_str, fmt)    #strptime() converts string   → datetime,
            return parsed_date.strftime("%d-%b-%Y").upper()   #strftime() converts datetime → string
        except ValueError:
            continue
    return pd.NaT  # Anything else becomes NULL

# Apply the function
df_stg_customers = pd.read_csv("customers.csv")

#df_stg_customers["state"] = df_stg_customers["state"].fillna("NA", inplace=True)

for col in df_stg_customers.columns:
    v_isnull=df_stg_customers[col].isnull().sum()
    print(f"Applied isnull() on column: {col} and the isnull count is : {v_isnull}")
    df_stg_customers["email"]= df_stg_customers["email"].str.lower()
    df_stg_customers["name"]= df_stg_customers["name"].str.upper()
    df_stg_customers["city"]= df_stg_customers["city"].str.capitalize()
    df_stg_customers["state"] = df_stg_customers["state"].apply(lambda x: x.capitalize() if pd.notna(x) and str(x).upper() != "NA" else x)

    


#join_date formatting
df_stg_customers['join_date'] = df_stg_customers['join_date'].apply(clean_and_format_date)

#strip function to remove leading and trailing characters
#df_stg_customers['email'] = df_stg_customers['email'].str.strip()
for col in df_stg_customers.columns:
    if df_stg_customers[col].dtype == 'object':   # check if column is string type
        df_stg_customers[col] = df_stg_customers[col].astype(str).str.strip()
        print(f"Applied strip() on column: {col}")
print("Whitespace cleanup completed successfully!")


#pincode checks (<6,>6,null)
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


cols_to_display = ["customer_id","name","city","state","join_date","loyalty_points","mobile","email"]
df_selected = df_stg_customers[cols_to_display]

df_selected = df_selected.drop_duplicates(subset=None, keep='first', inplace=False)

df_selected.to_csv("stg_customers.csv", index=False)

print("Transformed data written successfully to stg_customers.csv")
#print(df_selected.head())



Transformation Layer
--------------------

import pandas as pd
from datetime import datetime, timedelta

df_trnsf_customers = pd.read_csv("stg_customers.csv")

#Extract email domain using split()
df_trnsf_customers['mail_type'] = (
    df_trnsf_customers['email']
    .astype(str)                                     # Ensure all are strings
    .str.split('@')                                  # Split by '@'
    .str[1]                                          # Get part after '@'
    .str.split('.').str[0].str.lower()               # Get domain before '.'
)

# Classify customer_type based on customer_id
df_trnsf_customers["customer_type"] = df_trnsf_customers["customer_id"].apply(
    lambda x: "Regular" if str(x).startswith("C") else "Walk-in"
)

#Filter only last 3 years join_date
df_trnsf_customers["join_date"] = pd.to_datetime(df_trnsf_customers["join_date"], errors="coerce")
three_years_ago = datetime.now() - timedelta(days=3*365)
df_trnsf_customers = df_trnsf_customers[df_trnsf_customers["join_date"] >= three_years_ago]

#Categorize customers based on loyalty_points
def categorize_loyalty(points):
    if pd.isna(points):
        return "Unknown"
    elif points < 5000:
        return "Bronze"
    elif 5000 <= points < 10000:
        return "Silver"
    else:
        return "Gold"

df_trnsf_customers["loyalty_category"] = df_trnsf_customers["loyalty_points"].apply(categorize_loyalty)

#Rename column mail_type → mail_domain
df_trnsf_customers.rename(columns={"mail_type": "mail_domain"}, inplace=True)

#Save transformed data
df_trnsf_customers.to_csv("dim_customers.csv", index=False)

#Display output
print("✅ Transformation complete! Saved to dim_customers.csv")
print(df_trnsf_customers.head())

Mart Layer
----------
I have customer.csv(customer_id,name,city,state,join_date,loyalty_points,mobile,email,mail_domain,customer_type,loyalty_category) sales.csv(sales_id,sales_date,item_id,qty,price,amount) items.csv(item_id, item_name, item_category) orders.csv(order_id,order_date,item_id,qty,price,amount) Write the pandas dataframe to fetch categorywise,monthwise highest sales happened for which brand since last 1 year for Metro cities only and also within same pandas dataframe to fetch categorywise,monthwise highest sales happened for which brand since last 1 year for Non Metro cities also.

