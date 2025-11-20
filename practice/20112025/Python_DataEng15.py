🐼 Pandas Inbuilt Functions
===========================
👉 Pandas inbuilt functions are methods available directly on Pandas objects — such as DataFrame, Series, or at the library level (pd.<function>).
They help you perform data manipulation, cleaning, transformation, aggregation, visualization, etc.

There are hundreds of functions, but they can be grouped into categories.

⚙️ 1. Data Loading & Saving (I/O Functions)

Used to read/write data from/to files and databases.

| Function               | Description              |
| ---------------------- | ------------------------ |
| `pd.read_csv()`        | Read CSV file            |
| `pd.read_excel()`      | Read Excel file          |
| `pd.read_json()`       | Read JSON data           |
| `pd.read_sql()`        | Read SQL query or table  |
| `pd.read_parquet()`    | Read Parquet file        |
| `pd.read_html()`       | Read tables from HTML    |
| `pd.read_clipboard()`  | Read data from clipboard |
| `DataFrame.to_csv()`   | Write DataFrame to CSV   |
| `DataFrame.to_excel()` | Write to Excel           |
| `DataFrame.to_sql()`   | Write to SQL table       |
| `DataFrame.to_json()`  | Write to JSON            |


🧱 2. DataFrame Creation

| Function           | Description                        |
| ------------------ | ---------------------------------- |
| `pd.DataFrame()`   | Create a DataFrame                 |
| `pd.Series()`      | Create a Series                    |
| `pd.concat()`      | Concatenate DataFrames             |
| `pd.merge()`       | Merge DataFrames                   |
| `pd.join()`        | Join DataFrames                    |
| `pd.crosstab()`    | Create cross-tabulation            |
| `pd.pivot_table()` | Create pivot table                 |
| `pd.get_dummies()` | One-hot encode categorical columns |


📊 3. Data Exploration & Summary

| Function            | Description              |
| ------------------- | ------------------------ |
| `df.info()`         | Summary of DataFrame     |
| `df.describe()`     | Statistical summary      |
| `df.head()`         | First 5 rows             |
| `df.tail()`         | Last 5 rows              |
| `df.sample()`       | Random sample of rows    |
| `df.shape`          | Get (rows, cols)         |
| `df.columns`        | List of column names     |
| `df.dtypes`         | Data types of columns    |
| `df.memory_usage()` | Memory used by DataFrame |



🧹 4. Data Cleaning & Preparation

| Function               | Description                 |
| ---------------------- | --------------------------- |
| `df.dropna()`          | Remove missing values       |
| `df.fillna()`          | Fill missing values         |
| `df.replace()`         | Replace values              |
| `df.drop_duplicates()` | Remove duplicate rows       |
| `df.rename()`          | Rename columns              |
| `df.astype()`          | Change data type            |
| `df.apply()`           | Apply function to DataFrame |
| `df.applymap()`        | Apply function elementwise  |
| `df.map()`             | Apply function to Series    |
| `df.query()`           | Query rows using expression |
| `df.clip()`            | Limit values between bounds |


🔄 6. Sorting & Ranking

| Function           | Description                |
| ------------------ | -------------------------- |
| `df.sort_values()` | Sort by column values      |
| `df.sort_index()`  | Sort by index              |
| `df.rank()`        | Rank values within columns |


📈 7. Aggregation & Grouping

| Function            | Description                       |
| ------------------- | --------------------------------- |
| `df.groupby()`      | Group data by one or more columns |
| `df.agg()`          | Apply multiple aggregations       |
| `df.aggregate()`    | Aggregate data                    |
| `df.transform()`    | Transform grouped data            |
| `df.pivot()`        | Pivot data                        |
| `df.pivot_table()`  | Aggregate pivot table             |
| `df.value_counts()` | Count unique values               |


🪟 8. Window & Rolling Functions

| Function         | Description                       |
| ---------------- | --------------------------------- |
| `df.rolling()`   | Moving window calculations        |
| `df.expanding()` | Expanding window                  |
| `df.cumsum()`    | Cumulative sum                    |
| `df.cumprod()`   | Cumulative product                |
| `df.cummin()`    | Cumulative min                    |
| `df.cummax()`    | Cumulative max                    |
| `df.shift()`     | Shift values                      |
| `df.diff()`      | Calculate difference between rows |


🧮 9. Mathematical & Statistical Functions

| Function               | Description           |
| ---------------------- | --------------------- |
| `df.sum()`             | Sum                   |
| `df.mean()`            | Mean                  |
| `df.median()`          | Median                |
| `df.mode()`            | Mode                  |
| `df.std()`             | Standard deviation    |
| `df.var()`             | Variance              |
| `df.min()`, `df.max()` | Min/Max               |
| `df.count()`           | Count non-null values |
| `df.corr()`            | Correlation           |
| `df.cov()`             | Covariance            |
| `df.eval()`            | Evaluate expression   |


🧵 10. String Handling Functions (via .str)

| Function                                | Description          |
| --------------------------------------- | -------------------- |
| `.str.upper()`                          | Uppercase            |
| `.str.lower()`                          | Lowercase            |
| `.str.title()`                          | Title case           |
| `.str.strip()`                          | Remove spaces        |
| `.str.replace()`                        | Replace substring    |
| `.str.contains()`                       | Contains substring   |
| `.str.startswith()` / `.str.endswith()` | Check prefix/suffix  |
| `.str.len()`                            | String length        |
| `.str.slice()`                          | Slice substring      |
| `.str.extract()`                        | Extract regex groups |


🗓️ 11. Date & Time Functions

| Function                   | Description         |
| -------------------------- | ------------------- |
| `pd.to_datetime()`         | Convert to datetime |
| `df['date'].dt.year`       | Extract year        |
| `df['date'].dt.month`      | Extract month       |
| `df['date'].dt.day`        | Extract day         |
| `df['date'].dt.weekday`    | Extract weekday     |
| `df['date'].dt.strftime()` | Format date         |
| `pd.date_range()`          | Create date ranges  |


🔢 12. Indexing Functions

| Function           | Description                  |
| ------------------ | ---------------------------- |
| `df.set_index()`   | Set column as index          |
| `df.reset_index()` | Reset index                  |
| `df.reindex()`     | Change index                 |
| `df.rename_axis()` | Rename index or columns axis |


🧩 13. Merging & Combining

| Function      | Description         |
| ------------- | ------------------- |
| `pd.concat()` | Combine DataFrames  |
| `pd.merge()`  | Merge DataFrames    |
| `df.join()`   | Join two DataFrames |


🧮 14. Missing Data Handling

| Function                       | Description              |
| ------------------------------ | ------------------------ |
| `df.isnull()` / `df.notnull()` | Check nulls              |
| `df.fillna()`                  | Fill nulls               |
| `df.dropna()`                  | Drop nulls               |
| `df.interpolate()`             | Interpolate missing data |


💾 15. Utility Functions

| Function                             | Description         |
| ------------------------------------ | ------------------- |
| `pd.get_option()`, `pd.set_option()` | Set display options |
| `pd.options.display.max_rows`        | Control output rows |
| `pd.to_numeric()`                    | Convert to numeric  |
| `pd.cut()`, `pd.qcut()`              | Binning             |
| `pd.factorize()`                     | Encode labels       |
| `pd.unique()`                        | Unique values       |


📊 16. Visualization

| Function       | Description                |
| -------------- | -------------------------- |
| `df.plot()`    | Line/bar/scatter/hist plot |
| `df.hist()`    | Histogram                  |
| `df.boxplot()` | Box plot                   |


✅ Summary
There are 250+ inbuilt functions/methods in Pandas, but mastering around 100 will make you an expert in:
-Data ingestion
-Cleaning
-Transformation
-Aggregation
-Analysis
-Export
