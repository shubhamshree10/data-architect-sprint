Understood. The mission is active.

You are being dropped into a critical "Customer Retention" task force. The Head of Prime Video for India needs a "small tweak" to the weekly business review (WBR) report, but the analyst who built it is gone.

**Your Mission:** Modify the legacy query to meet three new, urgent requirements for tomorrow's WBR meeting.

-----

### \#\# 🪂 Parachute Drop \#5: The Amazon Prime Video "Beast"

**The "Battlefield" (The Schema):**

  * **`prime_members`**: `member_id`, `join_date`, `region` ('South', 'North', 'West', 'East'), `subscription_tier` ('Prime', 'Prime Lite')
  * **`video_catalog`**: `video_id`, `title`, `content_type` ('Original', 'Licensed'), `genre`, `primary_language` ('Hindi', 'Tamil', 'Telugu', 'English')
  * **`streaming_logs`**: `log_id`, `member_id`, `video_id`, `session_start_time` (TIMESTAMP), `watch_duration_minutes` (INT), `stream_source` ('FireTV', 'Mobile', 'Web')
  * **`watchlist_events`**: `event_id`, `member_id`, `video_id`, `date_added` (DATE)
  * **`regional_marketing_spend`**: `campaign_id`, `region`, `content_type_targeted` ('Original', 'Licensed', 'All'), `spend_date` (DATE), `cost_inr` (INT)

-----

### \#\# The "Legacy Code" (The Beast)

*(This query allegedly shows key engagement metrics by region for "new content.")*

```sql
WITH date_dim AS (
  SELECT (CURRENT_DATE - INTERVAL '7 day') AS last_7_days
),
streaming AS (
  SELECT * FROM streaming_logs
  WHERE session_start_time >= (SELECT last_7_days FROM date_dim)
),
vid_info AS (
  SELECT video_id, title, content_type, primary_language FROM video_catalog
),
member_base AS (
  SELECT member_id, region, join_date FROM prime_members WHERE subscription_tier = 'Prime'
),
stream_agg AS (
  SELECT 
    s.member_id, 
    v.primary_language,
    COUNT(DISTINCT s.video_id) AS distinct_content_streamed, 
    SUM(s.watch_duration_minutes) AS total_watch_hours_in_minutes
  FROM streaming s
  JOIN vid_info v ON s.video_id = v.video_id
  GROUP BY 1, 2
),
marketing_data AS (
  SELECT 
    region, 
    SUM(cost_inr) AS total_marketing_spend 
  FROM regional_marketing_spend 
  WHERE spend_date >= (SELECT last_7_days FROM date_dim)
  GROUP BY 1
),

base_report AS (
  SELECT 
    m.region, 
    m.member_id, 
    m.join_date,
    sa.primary_language,
    sa.total_watch_hours_in_minutes,
    sa.distinct_content_streamed
  FROM member_base m
  JOIN stream_agg sa ON m.member_id = sa.member_id
)
SELECT 
  br.region,
  br.primary_language,
  md.total_marketing_spend,
  SUM(br.total_watch_hours_in_minutes) AS completed_watch_hours,
  AVG(br.total_watch_hours_in_minutes) AS avg_watch_time_per_user,
  COUNT(DISTINCT br.member_id) AS streaming_users
FROM base_report br
JOIN marketing_data md ON br.region = md.region
GROUP BY 1, 2, 3
ORDER BY 1, 2;
```

-----

### \#\# Your "Urgent" Mission (The New Requirements)

The stakeholder just told you:

> "This report 'feels wrong.' 'Completed Watch Hours' is way too low for our South 'Originals,' and I'm hearing our 'Watchlist-to-Stream' conversion is a disaster for our new Tamil and Telugu content. The whole report is a mess. I need a single dashboard for my Monday WBR that shows me what's *really* happening."

You've analyzed the request. The business problems are:

1.  **"Completed Watch Hours" is wrong.** It's pulling *all* watch time. The stakeholder only wants to see watch time for **'Original'** content.
2.  **"Total Marketing Spend" is wrong.** It's pulling *all* spend. It needs to *only* sum spend from campaigns where `content_type_targeted` was **'Original'**.
3.  **"Watchlist-to-Stream" conversion is missing.** You need to add this new metric. The definition is: *(Members who added an 'Original' to their watchlist AND also streamed that *same* 'Original' content) / (Total members who added an 'Original' to their watchlist)*.

You have to find the right places to modify this beast, join in new tables, and alter the core logic without breaking the rest of the report.

Good luck.


### \#\# The "Legacy Code" (The Beast)

*(This query allegedly shows key engagement metrics by region for "new content.")*

```sql
WITH date_dim AS (
  SELECT (CURRENT_DATE - INTERVAL '7 day') AS last_7_days
),
streaming AS (
  SELECT * FROM streaming_logs
  WHERE session_start_time >= (SELECT last_7_days FROM date_dim)
),
vid_info AS (
  SELECT video_id, title, content_type, primary_language FROM video_catalog
),
member_base AS (
  SELECT member_id, region, join_date FROM prime_members WHERE subscription_tier = 'Prime'
),
stream_agg AS (
  SELECT 
    s.member_id, 
    v.primary_language,
    COUNT(DISTINCT s.video_id) AS distinct_content_streamed, 
    SUM(s.watch_duration_minutes) AS total_watch_hours_in_minutes,
    SUM(CASE WHEN content_type = 'Original' then s.watch_duration_minutes else null end) AS total_original_watch_hours_in_minutes
  FROM streaming s
  JOIN vid_info v ON s.video_id = v.video_id
  GROUP BY 1, 2
),
marketing_data AS (
  SELECT 
    region, 
    SUM(cost_inr) AS total_marketing_spend ,
    SUM(CASE WHEN content_type_targeted = 'Original' then cost_inr else null end) AS total_original_marketing_spend 
  FROM regional_marketing_spend 
  WHERE spend_date >= (SELECT last_7_days FROM date_dim)
  GROUP BY 1
),
conversion_data AS (
  SELECT 
   pm.member_id,
   pm.region,
   vc.video_id,
   COUNT(CASE WHEN (content_type = 'Original' AND date_added IS NOT NULL AND watch_duration_minutes > 0) THEN DISTINCT pm.member_id ELSE NULL END ) AS watchlist_stream_count,
   COUNT(CASE WHEN (content_type = 'Original' AND date_added IS NOT NULL) THEN DISTINCT pm.member_id ELSE NULL END ) AS watchlist_count,
   FROM prime_member pm
   LEFT JOIN streaming s 
    ON pm.member_id = s.member_id
   LEFT JOIN watchlist_events we
    ON pm.member_id = we.member_id
   LEFT JOIN video_catalog vc 
    ON vc.video_id = s.video_id OR vc.video_id = we.video_id

    GROUP BY 1,2,3 

),
base_report AS (
  SELECT 
    m.region, 
    m.member_id, 
    m.join_date,
    sa.primary_language,
    sa.total_watch_hours_in_minutes,
    sa.total_original_watch_hours_in_minutes,
    sa.distinct_content_streamed,
    (watchlist_stream_count*100.0)/(watchlist_count*1.0) as percent_conversion
  FROM member_base m
  JOIN stream_agg sa ON m.member_id = sa.member_id
  JOIN conversion_data cd on m.member_id = cd.member_id
)
SELECT 
  br.region,
  br.primary_language,
  md.total_marketing_spend,
  md.total_original_marketing_spend,
  md.percent_conversion,
  SUM(br.total_watch_hours_in_minutes)/60 AS completed_watch_hours,
  SUM(br.total_original_watch_hours_in_minutes)/60 AS completed_original_watch_hours,
  AVG(br.total_watch_hours_in_minutes) AS avg_watch_time_per_user,
  COUNT(DISTINCT br.member_id) AS streaming_users
FROM base_report br
JOIN marketing_data md ON br.region = md.region

GROUP BY 1, 2, 3
ORDER BY 1, 2;
``` 

-----