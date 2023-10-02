# Portfolio-Projects
Used to showcase my python and sql skills through projects

# Objective
The objective of this project was to use python and sql in a systematic manner to evaluate what stocks look like good investments.
I used the info portion of the project that evaluates how good companies are doing financially by using a bunch of different ratios
and assigning a score based on how good the ratio looks. The historical portion was more of a prices comparison to different historical
marks and the moving average. This will assign a higher score even if the market is bad because its based on whats the best available. 
This info will assign a much worse score in worse market conditions and a better score under better market coditions. This was we can
see the overal market, but still see oppurtunity when the conditions are less. Then take that information and graph its current price to 
the high and lows over a rolling window.

# 01 -Historical Pull
The historical pull takes all the stock tickers from the nasdaq screen file included here on github and assigns them to a list. 
It then runs that last and passes it into the yahoo finance API and pulls the historical stock data from  the api by iterating 
through the list of tickers and creating a dataframe from that. I then appened/concat the database from that iteration to a final
database. I then took that full database and created some calculation with it and outputed that final database to the csv.

# 01-Info Pull
There was a secondary step that can be run at the same time as the other 01 pull and it pulls the .info from the yahoo finance pull.
This has additional information about the stock including financial information and a bunch of other fields. I did the same thing with 
the nasdaq screener file and iterated through the list I created. Each iteration it would append/concat the new dataframe to the final
database. Once that was done I cut down the fields to just what I was going to use and assigned conditional scores to each field I was 
using by passing conditional logic held within a function into the lambda capabilities in python. I then cut it down to the final fields
that I created here. This process had two outputs. One being the full info file with all the fields and the other being the filtered file
for the load to snowflake.

# 02-SQL Scoring and processing
This process down multiple things and its split up with dashes between each set and it is numbered based on order it needs to be run.

This first portion of the process is selecting a few of the fields based on the most recent record. This is down with a dense_rank and
assigning a 1 to the most recent record of each ticker. That logic was put into a CTE and then that CTE output was pulled in to run the 
aggregation needed to isolate the fields used.

The second portion runs aggregation on the full historical infomation and that leads to a 1 record view with aggregated calculation on the 
historical information.

The third part joins the temp tables created from the first two steps and uses the dense_rank() function with calculation to assign the highest 
number possible tothe best calculation. Each ticker gets a number based on this. that is all done within a CTE. That CTE with the assigned fields 
for each calculation is then assigned a score to get a portion of 100 percent based on how the numbers look. 

The sql processing so far has all be done to get a score based on the historical data and each calculation has a score. Those scores from the historical
portion of the process are then summed up and assigned to a field. The score that was created by python is also loaded into sql with the filtered table
and this is also summed up to assign the score. At this point we have a historical score and an information score based on 2 different sides. Those
two scores are then averaged and ordered based on highest average score.

# 03-Graphing selected stocks
From the 02 SQL Process I plugged in the top 5 tickers by score into a list for the graphing portion of the process. 

The graphing process takes in the full
historical file and the full info file and isolates high and low fields and current prices and assigns that all to a dataframe for plotting as well as 
filtering down to the the tickers located in the list. 

Theres then a rolling average of the high and low fields calculated to create the annaul high in 
a rolling fashion for graphing and a monthly fashion. This is recreated, because the other was the most recent snap shot of it. 

I also had to cut down the number of datapoints  to every 20 days to make sure the graph looks clean on a quarterly graph over 5 years.

The final step was to use matplot lib to create a graph looking at the current price in comparision to the rolling yearly high and low alongside the rolling
monthly high and low.

# Conclusion
Based on the information at the time of this project last being run Calm and CEPH both look like decent options for investment.

CELH looks to have been on a pretty good upwar trajectory over the last couple of years with financial scores showing up pretty good. The current prices
is pretty close to the monthly low and has room to grow to get back to the monthly high. The overal growth has been good over the recent time and the price is 
in a good place based on where it looks to be going.

CALM took a pretty decent hit to the heights it reached back in 2022 where previously it had a huge uptick. The price appears to have bottomed out from that drop 
and appears to be makeing its way back up from that price drop. It had good financials so its in a good position for a rebound and the information looks like it could
be rebounding.
