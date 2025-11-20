Python Date Time Handling
=========================

Code to handle datetime
-----------------------
import pandas as pd
from datetime import datetime, date, time, timedelta
import time
import calendar
from zoneinfo import ZoneInfo


today1 = date.today()                     # 2025-11-09
now1   = datetime.now()                   # 2025-11-09 10:36:31.891258
str1  = "2025-10-07 15:45:30"

print(today1)
print(now1)

datetime1 = datetime.strptime(str1, "%Y-%m-%d %H:%M:%S")  #converted string to datetime
print(datetime1)

date_str = today1.strftime("%d-%b-%Y %H:%M:%S")  #09-Nov-2025 00:00:00 converted datetime to string
str2     = today1.strftime("%Y/%m/%d")   # e.g., '2025/11/09'
print(str2)

print(now1.year)       # 2025
print(now1.month)      # 11
print(now1.day)        # 9
print(now1.hour)       # 10
print(now1.minute)     # 25
print(now1.second)     # 30

tomorrow  = today1 + timedelta(days=1)
yesterday = today1 - timedelta(days=1)

print(tomorrow)
print(yesterday)

d1 = date(2025, 11, 1)
d2 = date(2025, 11, 9)

diff = d2 - d1
print(diff.days)      # 8

time.sleep(1)                # Pause execution for 2 seconds
current_time = time.time()   # Seconds since epoch

print(current_time)

dt_utc = datetime.now(ZoneInfo("UTC"))
dt_est = datetime.now(ZoneInfo("EST"))
dt_india = datetime.now(ZoneInfo("Asia/Kolkata"))

print(dt_utc)
print(dt_est)
print(dt_india)


Output
------
2025-11-09
2025-11-09 11:01:27.391983
2025-10-07 15:45:30
2025/11/09
2025
11
9
11
1
27
2025-11-10
2025-11-08
8
1762666288.4494345
2025-11-09 05:31:28.473418+00:00
2025-11-09 00:31:28.488480-05:00
2025-11-09 11:01:28.488722+05:30

