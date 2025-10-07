Data Classification/Data Masking/Data Encryption/Data Marketplace/Data Exchange/Data Clean Room
===============================================================================================

Data Classification
===================
Data Classification in Snowflake is the process of automatically detecting, identifying, and labeling sensitive data (like PII — personally identifiable information) stored in your Snowflake tables or views.
It helps you understand what type of data you’re storing, and where sensitive data (like email addresses, phone numbers, credit card numbers, etc.) lives in your database.

⚙️ How It Works
You use Snowflake’s system function SYSTEM$CLASSIFY or the data classification service in Snowsight.
Snowflake scans column data and metadata (names, values, patterns).
It identifies potential data categories and data types (like “Name”, “Email”, “SSN”, “Credit Card”).
It returns a JSON result or stores the classification in Snowflake’s governance metadata.


CREATE OR REPLACE TABLE customers (
    id NUMBER,
    full_name STRING,
    email STRING,
    phone STRING,
    credit_card STRING
);


SELECT SYSTEM$CLASSIFY('MYDB.MYSCHEMA.CUSTOMERS');
Output as below
{
  "columns": {
    "FULL_NAME": { "category": "PII", "type": "PERSON_NAME" },
    "EMAIL": { "category": "PII", "type": "EMAIL_ADDRESS" },
    "PHONE": { "category": "PII", "type": "PHONE_NUMBER" },
    "CREDIT_CARD": { "category": "SENSITIVE", "type": "CREDIT_CARD_NUMBER" },
    "ID": { "category": "IDENTIFIER", "type": "PRIMARY_KEY" }
  }
}

✅ This tells you what kind of sensitive data exists in each column.


🔖 Types of Metadata Returned
| Metadata Field       | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| **CATEGORY**         | Broad class of data (PII, SENSITIVE, IDENTIFIER, etc.)                    |
| **TYPE**             | Specific kind of data (EMAIL_ADDRESS, PERSON_NAME, SSN, etc.)             |
| **CONFIDENCE_LEVEL** | Indicates how confident Snowflake is in the detection (HIGH, MEDIUM, LOW) |


🧰 Other Useful Functions
| Function                    | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `SYSTEM$CLASSIFY`           | Runs classification on a table or schema          |
| `SYSTEM$GET_TAGS`           | Retrieves existing data classification tags       |
| `SYSTEM$APPLY_TAGS`         | Applies classification tags manually              |
| `SYSTEM$CATEGORIZE_COLUMNS` | Identifies potential categories from column names |


🧷 Example — Apply Tags Automatically
You can tag columns with the classification output to make them queryable in governance reports:
CALL SYSTEM$APPLY_CLASSIFICATION(
  'MYDB.MYSCHEMA.CUSTOMERS',
  TRUE
);


This automatically applies Snowflake tags like:
TAG: DATA_CATEGORY = 'PII'
TAG: DATA_TYPE = 'EMAIL_ADDRESS'

Later, you can query all PII data:
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.COLUMNS
WHERE TAG_VALUE = 'PII';


🧱 Integration with Data Masking
Once columns are classified, you can easily attach masking policies:

CREATE MASKING POLICY mask_email AS
  (VAL STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_ADMIN') THEN VAL
    ELSE '*****@*****.com'
  END;

ALTER TABLE CUSTOMERS
  MODIFY COLUMN EMAIL
  SET MASKING POLICY mask_email;
  
✅ So classification helps you automatically detect what to mask and where.


🧩 Typical Workflow
| Step | Action                     | Tool                          |
| ---- | -------------------------- | ----------------------------- |
| 1    | Identify sensitive columns | `SYSTEM$CLASSIFY`             |
| 2    | Review results             | Snowsight / SQL               |
| 3    | Apply tags                 | `SYSTEM$APPLY_CLASSIFICATION` |
| 4    | Set masking policies       | `CREATE MASKING POLICY`       |
| 5    | Monitor & audit            | Account Usage views           |


📊 Benefits
| Benefit                  | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| **Automated detection**  | AI/ML-based pattern recognition of sensitive data    |
| **Consistent tagging**   | Standardized governance metadata                     |
| **Easy integration**     | Works with masking, row access, and tagging policies |
| **Regulatory readiness** | Helps with GDPR, HIPAA, and CCPA compliance          |


⚠️ Limitations
| Limitation          | Note                                                    |
| ------------------- | ------------------------------------------------------- |
| Not perfect         | Sometimes misclassifies (manual validation recommended) |
| Data volume impact  | Large tables take time to scan                          |
| Requires privileges | Need `MONITOR` and `USAGE` rights on objects            |


✅ In Short
Data Classification in Snowflake = Automatic detection and labeling of sensitive data (PII, financial, etc.), helping you build secure, governed, and compliant data systems.


Data Masking
============
Data Masking in Snowflake is a security mechanism that hides or obfuscates sensitive data (like emails, SSNs, phone numbers, or credit card info) from unauthorized users — while still allowing authorized users to see the full data.

It’s implemented using masking policies, which are logical rules defined at the column level.


⚙️ How It Works (Concept)
You create a masking policy (a function-like object).
Attach the policy to a specific column in a table.
When a user queries that column:
	Snowflake checks the user’s role or condition.
	Based on that, the column value is masked or shown.

✅ The original data remains unchanged in storage.
❌ Only the query result is masked dynamically.


🧩 Example — Basic Dynamic Masking Policy
Let’s take a simple example of a customer table:
CREATE OR REPLACE TABLE customers (
  id NUMBER,
  full_name STRING,
  email STRING,
  credit_card STRING
);


1) Create a Masking Policy
CREATE MASKING POLICY mask_email_policy AS
  (email STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('DATA_ADMIN', 'SECURITY_ADMIN') THEN email
    ELSE '*****@*****.com'
  END;

2) Apply Masking Policy to a Column
ALTER TABLE customers
  MODIFY COLUMN email
  SET MASKING POLICY mask_email_policy;
  
✅ Done — now Snowflake enforces masking automatically.

3) Test it
If a regular analyst queries:
SELECT email FROM customers;

They’ll see:
*****@*****.com
*****@*****.com

If an admin queries:
USE ROLE DATA_ADMIN;
SELECT email FROM customers;

They’ll see:
john.doe@gmail.com
jane.smith@yahoo.com

🔒 Types of Masking
| Type                     | Description                                               | Example                        |
| ------------------------ | --------------------------------------------------------- | ------------------------------ |
| **Dynamic Data Masking** | Real-time masking when data is queried                    | Using masking policies         |
| **Static Data Masking**  | Masking done physically in stored data (usually one-time) | Used in dev/test environments  |
| **Conditional Masking**  | Masking based on conditions or role logic                 | Using `CASE` in masking policy |


🧠 Example — Conditional Masking Based on Data Value
You can also mask depending on data itself:
CREATE MASKING POLICY mask_credit_card AS
  (cc STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() = 'FINANCE_ROLE' THEN cc
    WHEN cc IS NULL THEN NULL
    ELSE CONCAT('XXXX-XXXX-XXXX-', RIGHT(cc, 4))
  END;
This shows only last 4 digits for unauthorized roles.

🧩 Combining with Data Classification
If you’ve already run data classification (e.g., found EMAIL or CREDIT_CARD columns),
you can automatically apply masking policies to those columns.

CALL SYSTEM$APPLY_CLASSIFICATION(
  'MYDB.MYSCHEMA.CUSTOMERS',
  TRUE
);

Snowflake will:
Identify sensitive columns
Apply corresponding masking tags or policies


🧩 Example — Masking Multiple Columns
You can attach one policy to multiple sensitive columns:

ALTER TABLE CUSTOMERS
MODIFY COLUMN credit_card SET MASKING POLICY mask_credit_card;

ALTER TABLE CUSTOMERS
MODIFY COLUMN email SET MASKING POLICY mask_email_policy;


SHOW MASKING POLICIES;  --To list all masking policies

SELECT TABLE_NAME, COLUMN_NAME, MASKING_POLICY_NAME  --To see columns with maskings applied
FROM INFORMATION_SCHEMA.COLUMNS
WHERE MASKING_POLICY_NAME IS NOT NULL;


📊 Example – Full Flow (End-to-End)
-- 1. Create table
CREATE TABLE emp_data (
  emp_id INT,
  emp_name STRING,
  email STRING,
  salary NUMBER
);

-- 2. Insert sample data
INSERT INTO emp_data VALUES 
(1, 'John', 'john@company.com', 80000),
(2, 'Jane', 'jane@company.com', 90000);

-- 3. Create masking policy
CREATE MASKING POLICY mask_salary_policy AS
  (salary NUMBER) RETURNS NUMBER ->
  CASE
    WHEN CURRENT_ROLE() = 'HR_ROLE' THEN salary
    ELSE NULL
  END;

-- 4. Apply it
ALTER TABLE emp_data
  MODIFY COLUMN salary
  SET MASKING POLICY mask_salary_policy;

-- 5. Test
USE ROLE ANALYST_ROLE;
SELECT * FROM emp_data;


👤 Analyst sees:
EMP_ID | EMP_NAME | EMAIL           | SALARY
1      | John      | john@company.com | NULL

👤 HR sees:
EMP_ID | EMP_NAME | EMAIL           | SALARY
1      | John      | john@company.com | 80000


✅ In short:
Data Masking in Snowflake lets you securely hide or reveal sensitive data at query time, based on who is accessing it — without changing the stored data itself.


Data Encryption
===============
Data Encryption in Snowflake is the process of converting your data into unreadable form using cryptographic algorithms — so that only authorized users or systems can decrypt and read it.

In simple terms:
🔒 Encryption = Locking your data with a key
🔑 Decryption = Unlocking it with the right key
Even if someone gains access to the storage layer, they cannot read your data without the decryption keys.

🧠 Why Encryption Matters
Snowflake automatically encrypts all customer data — at rest (stored) and in transit (moving).
This ensures:
Confidentiality 🔒 — only authorized users can access data.
Integrity ✅ — data isn’t tampered with.
Compliance 🧾 — aligns with GDPR, HIPAA, SOC 2, and FedRAMP standards.


🔄 Types of Encryption in Snowflake
Snowflake provides two main layers of encryption:

Type					Description																			Example
Encryption at Rest		Encrypts data stored in Snowflake-managed storage (internal stage, tables, etc.)	AES-256 encryption
Encryption in Transit	Encrypts data moving between client and Snowflake servers							TLS 1.2 or higher


Let’s look at both.
1 Encryption at Rest (Stored Data)
All data files, metadata, and backups stored in Snowflake are encrypted using AES-256 (Advanced Encryption Standard).
It applies to:
	-Databases and tables
	-Internal stages
	-Metadata (catalog)
	-Time travel & fail-safe data
Encryption happens automatically, with no setup required.

✅ Example:
When data is loaded into Snowflake (e.g., from Azure Blob or S3), it is automatically encrypted before being stored in Snowflake-managed storage.


2 Encryption in Transit (Data Movement)
Snowflake uses TLS (Transport Layer Security) to encrypt data between client → server → cloud storage.
Protects data while:
	-Loading/unloading files
	-Querying data
	-Connecting via SnowSQL, JDBC/ODBC, or web UI (Snowsight)

✅ Example:
When you connect using Snowsight or SnowSQL:
snowsql -a <account> -u <user> --private-key-path rsa_key.p8

TLS encrypts your login credentials and query traffic end-to-end.


🧱 3 Hierarchical Key Model (How Snowflake Manages Encryption Keys)
Snowflake uses a multi-layer key hierarchy, often called a Hierarchical Key Model.
| Key Level                     | Description                                    | Rotation                |
| ----------------------------- | ---------------------------------------------- | ----------------------- |
| **Root Key**                  | Master encryption key managed by Snowflake     | Periodically rotated    |
| **Account Key**               | Unique to each Snowflake account               | Rotated automatically   |
| **Table Key / File Key**      | Used for individual tables or micro-partitions | Rotated frequently      |
| **Data Encryption Key (DEK)** | Encrypts actual data chunks                    | Rotated with every load |

Each layer encrypts the keys below it — forming a chain of trust.

✅ So, even if a single key is compromised, the overall system remains secure.


🧩 4 Tri-Secret Secure (Customer-Managed Key Encryption)
If you want more control over encryption, Snowflake Enterprise Edition (and above) offers Tri-Secret Secure.

It combines:
	-Snowflake’s internal encryption keys, and
	-Your own key managed in AWS KMS / Azure Key Vault / GCP KMS
So your data can be decrypted only when:
	both keys (Snowflake + Customer Key) are available.

If you revoke your key — ❌ nobody (even Snowflake) can access your data.

✅ Perfect for high-security or regulated environments.


🧠 5 Encryption in Different Snowflake Areas
| Component               | Encryption Applied                    | Notes                  |
| ----------------------- | ------------------------------------- | ---------------------- |
| **Tables**              | AES-256 at rest                       | Automatic              |
| **Stage files**         | Encrypted both in transit and at rest | Internal & External    |
| **Data sharing**        | Encrypted via Secure Data Sharing     | Data never copied      |
| **Metadata**            | Encrypted at rest                     | Included in same model |
| **Backups (Fail-safe)** | Fully encrypted                       | AES-256                |
| **Snowpipe / Streams**  | TLS + internal encryption             | Automatic              |


🔐 6 Example: Using Customer-Managed Keys (Tri-Secret Secure)
If your organization wants total control:
Create a key in Azure Key Vault:
	az keyvault key create --vault-name myVault --name snowflakeKey --protection software
Register it in Snowflake:
	ALTER ACCOUNT SET MASTER_KEY = '<Azure-Key-ID>';
When Snowflake encrypts data:
	It uses both your key + Snowflake’s internal key.
	Decryption requires both.

If you disable or revoke your key — your data becomes inaccessible (zero trust model).


🔎 7 Verifying Encryption
Snowflake doesn’t require manual setup, but you can confirm encryption details:
SHOW PARAMETERS LIKE 'ENCRYPTION';
or query:
SHOW SECURITY INTEGRATION;


🧾 Compliance & Certifications
Snowflake’s encryption model meets industry standards:
✅ SOC 1 Type II, SOC 2 Type II
✅ ISO/IEC 27001, 27017, 27018
✅ FedRAMP Moderate
✅ HIPAA
✅ GDPR


🧭 Summary Table
| Aspect                    | Description                        |
| ------------------------- | ---------------------------------- |
| **Encryption at Rest**    | AES-256                            |
| **Encryption in Transit** | TLS 1.2+                           |
| **Key Management**        | Hierarchical model                 |
| **Customer Key Control**  | Tri-Secret Secure                  |
| **Automatic?**            | Yes — no user setup required       |
| **Decryption**            | Handled by Snowflake automatically |
| **Security Level**        | Enterprise-grade, end-to-end       |


✅ In short:
Data Encryption in Snowflake ensures your data is protected both when it’s stored and when it’s moving — using AES-256 + TLS — and you can even bring your own keys for maximum control using Tri-Secret Secure.

Q : How do we encrypt a customer table ?
--------------------------------------
❄️ 1 Default Encryption – Automatic Table Encryption
Every table in Snowflake (customer or system-created) is automatically encrypted at rest using AES-256 encryption.
You don’t need to run any SQL command like ALTER TABLE ENCRYPT — it’s already built into Snowflake’s architecture.

CREATE OR REPLACE TABLE customer_data (
    customer_id STRING,
    customer_name STRING,
    email STRING,
    phone STRING
);

INSERT INTO customer_data VALUES
('C001', 'John Smith', 'john.smith@email.com', '555-222-1111');

Snowflake automatically:
-Encrypts the data blocks using a Data Encryption Key (DEK).
-Wraps that DEK with a Table Key.
-Wraps that again with your Account Key (part of the hierarchical key structure).

🧠 You do not see this encryption, but it’s always there.


🧱 2 Hierarchical Key Model (Under the Hood)
| Level | Key Type                      | Rotated Automatically? | Scope                       |
| ----- | ----------------------------- | ---------------------- | --------------------------- |
| 1     | **Root Key**                  | ✅ Yes                  | Entire Snowflake deployment |
| 2     | **Account Key**               | ✅ Yes                  | Each Snowflake account      |
| 3     | **Table Key**                 | ✅ Yes                  | Each table                  |
| 4     | **Data Encryption Key (DEK)** | ✅ Yes                  | Each micro-partition        |

So even if you have 100 customer tables, each will have its own encryption keys.


🧠 3 Verifying Encryption on Your Customer Table
You can check encryption-related parameters (though not the keys themselves) using:
SHOW PARAMETERS LIKE 'ENCRYPTION';
SHOW SECURITY INTEGRATIONS;

Snowflake doesn’t allow direct inspection of keys for security reasons — but everything is encrypted by default.


🔐 4 Optional: Customer-Controlled Encryption (Tri-Secret Secure)
If you want to manage your own encryption key (for example, for a sensitive customer table), you can enable Tri-Secret Secure.
This combines:
	-Snowflake’s managed key, and
	-Your key in Azure Key Vault / AWS KMS / GCP KMS
Both are required to decrypt your table data.

Example (conceptual steps):
Step 1: Create your own KMS key (Azure example)
az keyvault key create --vault-name myVault --name snowflakeKey --protection software

Step 2: Configure your Snowflake account to use it
CREATE SECURITY INTEGRATION my_key_integration
    TYPE = EXTERNAL_OAUTH
    ENABLED = TRUE
    STORAGE_PROVIDER = AZURE
    AZURE_TENANT_ID = '<tenant_id>'
    AZURE_KEY_VAULT_URL = 'https://myVault.vault.azure.net/'
    AZURE_KEY_IDENTIFIER = 'https://myVault.vault.azure.net/keys/snowflakeKey/<version>';

Step 3: Bind that key to your Snowflake account
ALTER ACCOUNT SET MASTER_KEY = 'my_key_integration';


✅ From this point:
Your customer table (and all other data) will be encrypted with both keys.
If you disable your key in Azure Key Vault, Snowflake cannot decrypt your data — even you can’t read it until re-enabled.


🧩 5 Extra Protection: Column-Level Masking (for PII)
While encryption protects data at rest, you can combine it with Dynamic Data Masking to hide sensitive data in queries.

CREATE OR REPLACE MASKING POLICY mask_email AS
  (val STRING) RETURNS STRING ->
    CASE
      WHEN CURRENT_ROLE() IN ('DATA_ADMIN') THEN val
      ELSE '***MASKED***'
    END;

ALTER TABLE customer_data
  MODIFY COLUMN email SET MASKING POLICY mask_email;

SELECT * FROM customer_data;
-Data admins see full emails
-Others see only ***MASKED***
So encryption + masking = data confidentiality + access control

🧭 6 Summary
| Feature                    | Description                           | How to Enable      |
| -------------------------- | ------------------------------------- | ------------------ |
| **Automatic Encryption**   | All tables encrypted using AES-256    | Default            |
| **Encryption in Transit**  | TLS 1.2+ between client and Snowflake | Default            |
| **Hierarchical Key Model** | Multi-level key wrapping              | Default            |
| **Tri-Secret Secure**      | Add your own key from KMS             | Enterprise Feature |
| **Dynamic Masking**        | Hide sensitive columns dynamically    | Optional           |

✅ In short:
You don’t need to manually encrypt a customer table — Snowflake does it automatically.
But you can enhance control using Tri-Secret Secure (your own key) and Dynamic Data Masking (for fine-grained access).

Hands-on walkthrough of encrypting customer data using Tri-Secret Secure and masking together
---------------------------------------------------------------------------------------------
let’s go step-by-step and build a practical mini-demo combining
1 Automatic encryption (built-in)
2 Tri-Secret Secure (customer-managed key)
3 Dynamic Data Masking (column-level protection)
This example shows how your customer data table in Snowflake stays protected end-to-end.

🧩 SCENARIO
Your company stores customer data in Snowflake.
You want:
-All data to stay encrypted (default ✅).
-Encryption keys under your control using Azure Key Vault.
-Email + phone fields masked for non-admin users.

⚙️ 1 Built-in Encryption (Already Active)
Snowflake automatically encrypts everything using AES-256 at rest and TLS in transit — no action needed.
SHOW PARAMETERS LIKE 'ENCRYPTION';
✅ You’ll see encryption mode as ENABLED.


🔐 2 Configure Tri-Secret Secure (Customer-Managed Key)
Goal: Let Snowflake use both its own key + your Azure Key Vault key.
(Requires Enterprise edition or higher.)

	🔹 Step 1: Create a key in Azure Key Vault
	In Azure CLI:
	az keyvault create --name myVault --resource-group myRG --location eastus
	az keyvault key create --vault-name myVault --name snowflakeKey --protection software

	Copy the Key Identifier, e.g.
	https://myVault.vault.azure.net/keys/snowflakeKey/1234abcd5678efgh

	🔹 Step 2: Create a Security Integration in Snowflake
	Run in Snowflake as ACCOUNTADMIN:

	CREATE SECURITY INTEGRATION azure_key_integration
	  TYPE = EXTERNAL_OAUTH
	  ENABLED = TRUE
	  STORAGE_PROVIDER = AZURE
	  AZURE_TENANT_ID = '<your-tenant-id>'
	  AZURE_KEY_VAULT_URL = 'https://myVault.vault.azure.net/'
	  AZURE_KEY_IDENTIFIER = 'https://myVault.vault.azure.net/keys/snowflakeKey/1234abcd5678efgh';

	🔹 Step 3: Bind the integration to your account
	ALTER ACCOUNT SET MASTER_KEY = 'azure_key_integration';

	✅ From now on, all data encryption in your account uses:
	Snowflake’s root key, and
	Your Azure key (Tri-Secret Secure)
	If you disable your Azure key — ❌ your data becomes unreadable until re-enabled.


🧾 3 Create and Protect the Customer Table
CREATE OR REPLACE TABLE CUSTOMER_SECURE (
    CUSTOMER_ID STRING,
    CUSTOMER_NAME STRING,
    EMAIL STRING,
    PHONE STRING,
    REGION STRING
);


Insert sample data:
INSERT INTO CUSTOMER_SECURE VALUES
('C001', 'John Smith', 'john.smith@email.com', '555-222-1111', 'East'),
('C002', 'Mary Adams', 'mary.adams@email.com', '555-444-2222', 'West');

This table’s micro-partitions are already encrypted with AES-256, wrapped by your Tri-Secret keys.


🎭 4 Add Dynamic Data Masking (Column-Level)
Create masking policies:
CREATE OR REPLACE MASKING POLICY mask_email
AS (val STRING) RETURNS STRING ->
    CASE
      WHEN CURRENT_ROLE() IN ('SECURITYADMIN','DATA_ADMIN') THEN val
      ELSE '***MASKED***'
    END;

CREATE OR REPLACE MASKING POLICY mask_phone
AS (val STRING) RETURNS STRING ->
    CASE
      WHEN CURRENT_ROLE() IN ('SECURITYADMIN','DATA_ADMIN') THEN val
      ELSE CONCAT('XXX-XXX-', RIGHT(val,4))
    END;

Apply them:
ALTER TABLE CUSTOMER_SECURE
MODIFY COLUMN EMAIL SET MASKING POLICY mask_email;

ALTER TABLE CUSTOMER_SECURE
MODIFY COLUMN PHONE SET MASKING POLICY mask_phone;


👁️ 5 Test the Masking Behavior
As Data Admin:
USE ROLE DATA_ADMIN;
SELECT * FROM CUSTOMER_SECURE;

✅ You’ll see full data.

As Regular Analyst:
USE ROLE ANALYST;
SELECT * FROM CUSTOMER_SECURE;

🔒 You’ll see:
C001 | John Smith | ***MASKED*** | XXX-XXX-1111 | East
C002 | Mary Adams | ***MASKED*** | XXX-XXX-2222 | West

🧠 6 Verify Encryption + Key Integration
To check integration:
SHOW SECURITY INTEGRATIONS;

You’ll find your azure_key_integration listed and ENABLED.
All tables (including CUSTOMER_SECURE) are encrypted under this key hierarchy.

✅ SUMMARY
| Security Layer          | Technique                     | Enabled      |
| ----------------------- | ----------------------------- | ------------ |
| Encryption at Rest      | AES-256 (Snowflake managed)   | ✅ Default    |
| Encryption Key Control  | Tri-Secret Secure (Azure KMS) | ✅ Configured |
| Encryption in Transit   | TLS 1.2+                      | ✅ Default    |
| Column-Level Protection | Dynamic Data Masking          | ✅ Added      |
| Fine-grained Access     | Role-based                    | ✅ Used       |

👉 In essence:
Your CUSTOMER_SECURE table is now fully protected — encrypted with dual keys, masked for sensitive columns, and accessible only by the right roles.

Data Marketplace
================
Snowflake Data Marketplace is a secure, governed platform inside Snowflake where organizations can discover, share, and access live, ready-to-query data — without copying or moving it.

Think of it as:
The “App Store” for data 📊 — but inside Snowflake.

You can:
-Publish your data sets (as a data provider), or
-Subscribe to other organizations’ shared data (as a data consumer).
All this happens natively inside Snowflake’s Data Cloud — no ETL, no CSVs, no APIs.

🧩 1 Key Characteristics
| Feature                        | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| **Live Data Sharing**          | Consumers access the same live data — no replication needed              |
| **No Data Movement**           | Data remains in the provider’s Snowflake account                         |
| **Secure & Governed**          | Row/column-level security and masking preserved                          |
| **Cross-Cloud & Cross-Region** | Works across AWS, Azure, and GCP                                         |
| **Billing & Usage**            | Consumers pay (if commercial), tracked automatically                     |
| **Discoverability**            | Datasets searchable and categorized (Weather, Finance, Healthcare, etc.) |


🧠 2 Analogy: Marketplace vs Traditional Sharing
| Aspect        | Traditional Sharing | Snowflake Marketplace       |
| ------------- | ------------------- | --------------------------- |
| Data Transfer | CSV/API download    | Direct, secure sharing      |
| Latency       | Static snapshot     | Always live                 |
| Security      | Managed externally  | Built-in Snowflake security |
| Maintenance   | Manual refresh      | Automatic sync              |
| Discovery     | Private             | Public or private catalog   |

🏬 3 Types of Marketplace
| Type                      | Description                                               | Example Use                           |
| ------------------------- | --------------------------------------------------------- | ------------------------------------- |
| **Public Marketplace**    | Open to all Snowflake users globally                      | Weather, demographics, financial data |
| **Private Data Exchange** | Restricted sharing for specific partners or internal orgs | Subsidiaries, departments, vendors    |


💡 4 Example: Accessing Public Marketplace Data
	Let’s say you want to use Weather Source’s weather dataset (a real provider on Snowflake Marketplace).

	Step 1: Open Marketplace
	In Snowsight → click Data » Marketplace
	Search for Weather Source or weather data.

	Step 2: Request Access
	Click Get Data (free or paid).
	Snowflake creates a new database in your account automatically.

	For example:
	Database: WEATHER_SOURCE_FREE
	Schema: WEATHER_SOURCE_SCHEMA

	Step 3: Query It Directly
	USE DATABASE WEATHER_SOURCE_FREE;
	SHOW TABLES;

	SELECT * FROM WEATHER_SOURCE_SCHEMA.HOURLY_WEATHER
	WHERE CITY = 'Bangalore'
	LIMIT 10;

	✅ Data is live and queryable — no download, no ETL.


🧱 5 Example: Publishing Data to Marketplace (Provider Side)
	Let’s say you want to share customer purchase trends.

	Step 1: Create a Share
	CREATE SHARE my_customer_share;
	GRANT USAGE ON DATABASE sales_db TO SHARE my_customer_share;
	GRANT SELECT ON ALL TABLES IN SCHEMA sales_db.public TO SHARE my_customer_share;

	Step 2: Add Consumer Accounts
	You don’t specify them directly here — instead, the Marketplace handles it once you publish the share.

	Step 3: Publish It
	In Snowsight:
	Go to Data » Provider Studio » Create Listing
	Choose:
		Name: “Customer Purchase Trends”
		Description: “Monthly aggregated sales trends by region”
		Type: Public or Private
		Pricing: Free or Subscription
	Once approved by Snowflake, it appears in Marketplace.

🧰 6 Example: Consumer Querying the Data
Consumer’s perspective:
USE DATABASE CUSTOMER_PURCHASE_TRENDS;
SELECT REGION, AVG(SALES_AMOUNT)
FROM PUBLIC.SALES_SUMMARY
GROUP BY REGION;
They are reading your live data — you control what’s visible and can revoke access anytime.	

🔐 7️⃣ Security & Governance in Marketplace
| Feature                | Description                                       |
| ---------------------- | ------------------------------------------------- |
| **Role-based Access**  | Provider controls which objects are shared        |
| **Dynamic Masking**    | Sensitive data stays masked for consumers         |
| **No Data Copying**    | Consumers query directly from provider storage    |
| **Audit & Monitoring** | Access logs visible to both provider and consumer |


🌎 8️⃣ Cross-Region and Cross-Cloud Support
Marketplace data can be shared:
-Across regions (e.g., AWS US → Azure India)
-Across clouds (AWS ↔ Azure ↔ GCP)
Snowflake automatically replicates the data and metadata securely between the cloud platforms.

💸 9️⃣ Monetization
Providers can monetize data:
-Define pricing models (subscription-based, per-query, or free)
-Snowflake handles billing and usage tracking
-Consumers get live data — providers earn revenue

🧾 10️⃣ Summary Table
| Role               | You Can                                 | Examples                                  |
| ------------------ | --------------------------------------- | ----------------------------------------- |
| **Data Provider**  | Publish datasets to marketplace         | Banks, weather companies, analytics firms |
| **Data Consumer**  | Subscribe and query live data           | Data analysts, BI teams, ML engineers     |
| **Exchange Owner** | Manage private marketplace for partners | Enterprise groups, multi-subsidiary orgs  |

✅ In short:
Snowflake Data Marketplace is a built-in, secure platform for sharing and monetizing live, queryable data — across accounts, regions, and clouds — without moving or duplicating it.

Data Exchange
=============
Data Exchange in Snowflake is a private, secure data-sharing hub that allows an organization to create its own internal or partner-specific data marketplace.
Think of it as:
🏢 “Your organization’s private Snowflake Marketplace.”

It lets you:
-Share live data among departments, subsidiaries, or partners
-Control who sees what
-Keep everything governed, audited, and secured within your Snowflake environment

🧠 1 Marketplace vs Data Exchange
| Feature            | Snowflake **Marketplace**            | Snowflake **Data Exchange**                    |
| ------------------ | ------------------------------------ | ---------------------------------------------- |
| **Visibility**     | Public – open to all Snowflake users | Private – invite-only                          |
| **Ownership**      | Managed by Snowflake                 | Managed by your organization                   |
| **Use Case**       | Share or sell data globally          | Share data internally or with trusted partners |
| **Access Control** | Global discoverability               | Controlled by Exchange Admin                   |
| **Branding**       | Generic Snowflake marketplace        | Custom branding, description, and logo         |
| **Examples**       | Weather Source, FactSet, SafeGraph   | Your company’s private data hub                |

👉 So, Marketplace = Global data catalog
while Exchange = Your private collaboration space for data.

🧩 2️⃣ Types of Data Exchange
There are two main types of exchanges you can create:
| Type                 | Description                                    | Example Use                 |
| -------------------- | ---------------------------------------------- | --------------------------- |
| **Private Exchange** | Visible only to invited accounts               | Internal company sharing    |
| **Public Exchange**  | Visible to anyone on Snowflake (with approval) | Industry consortium sharing |

🧱 3️⃣ Example Use Cases
| Use Case                             | Description                                                                   |
| ------------------------------------ | ----------------------------------------------------------------------------- |
| **Enterprise-wide data sharing**     | Different departments (Sales, Finance, HR) share data within one organization |
| **Subsidiary/Partner collaboration** | HQ shares data with partner firms or regional branches                        |
| **Vendor integration**               | Vendors get access to live usage or billing data                              |
| **Internal analytics hub**           | Central catalog for all shared datasets in the company                        |

⚙️ 4️⃣ Architecture Overview
Here’s how it fits together:

+---------------------+             +----------------------+
|    Data Provider    |             |    Data Consumer     |
| (e.g. Finance Dept) |             | (e.g. Analytics Team)|
+----------+----------+             +-----------+----------+
           |                                    |
           |   Live, Secure Data Share          |
           +------------------------------------+
                          |
                          v
             +---------------------------+
             |   Private Data Exchange   |
             |  (Managed by Org Admin)   |
             +---------------------------+

No data copies, no ETL — all live sharing through Snowflake’s internal sharing mechanisms.

💻 5️⃣ Setting Up a Data Exchange
	Setting up a Data Exchange involves 3 roles:
	1.Exchange Owner — creates and manages the exchange
	2.Data Provider — publishes data listings
	3.Data Consumer — subscribes to listings
	
	🧩 Step-by-Step Setup (with SQL + UI flow)
		Step 1: Exchange Owner creates the Exchange (via Snowsight UI)
		Go to Data → Exchanges → Create Exchange
		Enter:
			Name: MY_ORG_EXCHANGE
			Description: “Internal exchange for all business units”
			Type: Private
		Add your company’s logo and description (optional)
		Snowflake provisions the Exchange instance in your account.	
	
		Step 2: Provider creates a data share
		CREATE SHARE sales_data_share;
		GRANT USAGE ON DATABASE sales_db TO SHARE sales_data_share;
		GRANT SELECT ON ALL TABLES IN SCHEMA sales_db.public TO SHARE sales_data_share;
		
		Step 3: Add the share to your Exchange
		In Snowsight:
		-Navigate to your Exchange
		-Click Add Listing → From Existing Share
		-Select sales_data_share
		-Add:
			Title: “Monthly Sales Metrics”
			Description: “Aggregated regional sales data updated daily”
			Pricing: Free (internal use)
		-Publish		
		
		Step 4: Invite Consumer Accounts
		Invite Snowflake account IDs of your internal teams or partners:
		ALTER SHARE sales_data_share ADD ACCOUNTS = ('ORG12345', 'ORG67890');
		Or in UI: “Invite consumers” → Add account identifiers.
		
		Step 5: Consumer accesses the shared data
		Consumer account automatically sees a new database:

		USE DATABASE SALES_DATA_SHARE;
		SHOW TABLES;
		SELECT * FROM PUBLIC.MONTHLY_SALES LIMIT 10;

		✅ No ETL, no file transfer, no duplication.
		Data stays synced and live.		
		
🧰 6️⃣ Managing and Monitoring Exchange
The Exchange owner can:
-Approve or remove consumers
-Monitor usage and queries
-Revoke or update listings anytime

Example command:
SHOW SHARES LIKE 'sales_data_share';
DESC SHARE sales_data_share;		


🔒 7️⃣ Security and Governance
| Feature                | Description                                               |
| ---------------------- | --------------------------------------------------------- |
| **Role-based control** | Limit which roles can create or publish                   |
| **Data masking**       | Sensitive columns can remain masked                       |
| **Revocation**         | Providers can revoke access anytime                       |
| **Auditing**           | Query activity visible to providers                       |
| **Compliance**         | Exchange inherits Snowflake’s SOC, HIPAA, GDPR compliance |


🧭 8️⃣ Difference Summary (Marketplace vs Exchange)
| Aspect              | Data Marketplace                | Data Exchange                      |
| ------------------- | ------------------------------- | ---------------------------------- |
| **Scope**           | Public (global)                 | Private (organization/partners)    |
| **Owner**           | Snowflake                       | You (organization)                 |
| **Data Visibility** | Discoverable by anyone          | Invitation-only                    |
| **Branding**        | Snowflake-branded               | Custom organization branding       |
| **Example Use**     | Public weather/finance datasets | Internal sales, HR, marketing data |
| **Governance**      | Central                         | Custom per Exchange                |

🧾 9️⃣ Example: Internal Exchange Scenario
| Role               | Example                                        |
| ------------------ | ---------------------------------------------- |
| **Provider**       | Finance publishes `expense_summary` dataset    |
| **Consumer**       | HR & Operations subscribe to it                |
| **Exchange Owner** | IT Admin manages who can access which listings |

Consumers query it like a normal Snowflake table — data never moves.

✅ In short:
Snowflake Data Exchange is your private data marketplace — letting your company share, discover, and collaborate on live data securely across internal teams, subsidiaries, or trusted partners.

Data Clean Room
===============
A Data Clean Room in Snowflake is a secure, privacy-preserving collaboration environment where multiple parties (such as companies, departments, or partners) can analyze and share insights from their combined data — without actually sharing or exposing the raw data.

✅ Key idea:
You can run joint analytics across datasets from different companies while ensuring data privacy, compliance, and governance — the raw data never leaves each party’s control.


💡 Real-world Example
Imagine:
Company A (Retailer) has customer purchase data
Company B (Ad Agency) has ad campaign and impression data
Both want to measure how ad campaigns influence sales, but cannot share PII (personally identifiable information) due to privacy laws (GDPR, CCPA, etc).

👉 Solution:
They create a Data Clean Room in Snowflake — both datasets remain private, but Snowflake enables:
-Secure joins on common identifiers (like hashed emails)
-Privacy-safe aggregation
-Analytics without revealing individual records

🔐 Why “Clean Room”?
The term comes from the idea of a controlled environment — like a physical clean room in a lab:
-No contaminants (here, it means no raw data exposure)
-Strict access control
-Only approved computations allowed

🧱 Core Principles
| Concept                    | Description                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------- |
| **Privacy-preserving**     | Data owners never see each other’s raw data                                        |
| **Secure computation**     | Queries run in Snowflake using controls like row access, masking, or UDF isolation |
| **Controlled outputs**     | Only aggregated or anonymized results are visible                                  |
| **Zero data movement**     | Data stays in place inside Snowflake                                               |
| **Governed collaboration** | All activity is audited and managed via roles & policies                           |


⚙️ How It Works (Step-by-Step)
Here’s the high-level flow 👇

Step 1️⃣: Each party stores data in their own Snowflake account
| Company    | Example Dataset                                    |
| ---------- | -------------------------------------------------- |
| Retailer   | `CUSTOMERS(customer_id, region, purchase_amount)`  |
| Advertiser | `AD_IMPRESSIONS(customer_id, campaign_id, clicks)` |

Step 2️⃣: They create a Clean Room project
In Snowflake, one account acts as the Clean Room Operator — defining:
-Data access boundaries
-Privacy rules (e.g., minimum aggregation threshold)
-Approved computations

CREATE CLEAN ROOM retail_ad_collab
COMMENT = 'Ad campaign performance analysis between RetailCo and AdCo';

Step 3️⃣: Define participant roles and data
ALTER CLEAN ROOM retail_ad_collab
  ADD PARTICIPANT RetailCo
  USING SHARE retail_share;

ALTER CLEAN ROOM retail_ad_collab
  ADD PARTICIPANT AdCo
  USING SHARE ad_share;
  

Step 4️⃣: Define approved functions / queries
Each query inside a clean room must be privacy-safe:
-No direct SELECT from raw data
-Only approved join keys (e.g., hashed customer_id)
-Only aggregated outputs

CREATE VIEW retail_ad_collab.shared_analytics AS
SELECT
    campaign_id,
    COUNT(*) AS matched_customers,
    AVG(purchase_amount) AS avg_spend
FROM retail.customers AS r
JOIN adco.ad_impressions AS a
  ON r.hashed_id = a.hashed_id
GROUP BY campaign_id;


Step 5️⃣: Approved results only
-Snowflake enforces output rules: no result sets smaller than a threshold (e.g., 10 users).
-Each party can only see aggregate insights.

Example result:
| Campaign_ID | Matched_Customers | Avg_Spend |
| ----------- | ----------------- | --------- |
| CAMP101     | 12,000            | 450       |
| CAMP102     | 8,500             | 390       |

No individual user info ever revealed.

🧰 Components of a Snowflake Clean Room
| Component            | Purpose                                                             |
| -------------------- | ------------------------------------------------------------------- |
| **Participants**     | Organizations contributing data                                     |
| **Data Shares**      | Mechanism for exposing approved data                                |
| **Approved Queries** | Only privacy-safe queries are allowed                               |
| **Policies**         | Define privacy constraints (aggregation threshold, join type, etc.) |
| **Audit Logs**       | Track who ran what and when                                         |
| **UDFs/UDAFs**       | For custom computations under strict controls                       |

🛡️ Privacy & Security Mechanisms
| Feature                    | Description                                    |
| -------------------------- | ---------------------------------------------- |
| **Hashing / Tokenization** | Common join keys are matched via hashed values |
| **Row Access Policies**    | Restrict access to rows by role or rule        |
| **Data Masking Policies**  | Hide sensitive columns                         |
| **Output Thresholds**      | Prevent too-small or identifiable outputs      |
| **No Raw Data Movement**   | All computation happens *inside* Snowflake     |
| **Auditing**               | Full log of queries and outputs for compliance |

💼 Common Use Cases
| Use Case                     | Description                                                           |
| ---------------------------- | --------------------------------------------------------------------- |
| **Advertising measurement**  | Retailer + Ad agency measure campaign ROI                             |
| **Joint customer analytics** | Bank + Retailer find overlapping customers without PII exchange       |
| **Healthcare collaboration** | Hospitals share aggregate research data without exposing patient info |
| **Partner benchmarking**     | Franchise networks analyze performance securely                       |

🧭 Clean Room vs Data Exchange vs Marketplace
| Feature             | Data Clean Room                | Data Exchange               | Data Marketplace              |
| ------------------- | ------------------------------ | --------------------------- | ----------------------------- |
| **Privacy Level**   | Highest (no raw data exposure) | Medium                      | Low (data shared directly)    |
| **Data Visibility** | Aggregates only                | Dataset access (controlled) | Dataset access (public)       |
| **Participants**    | Multiple parties               | Internal or partners        | Public providers/consumers    |
| **Purpose**         | Privacy-safe analytics         | Controlled data sharing     | Data discovery & monetization |
| **Data Movement**   | None                           | None                        | None (uses sharing)           |

🧮 Example SQL Snippet for Privacy-Safe Join
-- Create privacy-safe UDF for hashed join
CREATE FUNCTION HASH_ID(id STRING)
RETURNS STRING
AS 'sha2(id, 256)';

-- Each participant hashes their IDs before joining
SELECT COUNT(*), AVG(spend)
FROM retailer.customers r
JOIN advertiser.impressions a
  ON r.hashed_id = a.hashed_id
GROUP BY a.campaign_id
HAVING COUNT(*) >= 10;  -- Enforce privacy threshold

🧾 In short
🔒 Snowflake Data Clean Room = A secure collaboration environment for multiple organizations to run joint analytics on their combined data without revealing the underlying data to each other.

It’s built on:
Secure Data Sharing
Role-based access
Data masking and policies
Privacy-preserving computation


