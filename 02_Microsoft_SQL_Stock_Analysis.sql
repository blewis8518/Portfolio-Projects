-----------------------------------------------------------------------------------------
--Historical Info Processing
--01 Selects the most recent Dates Info.
with singlerowhistorical as (
select *
	   , dense_rank() over(partition by Ticker order by Date Desc) as prio
from portfolio.dbo.Historical_Data
)
select Ticker
	   , Annual_High - Annual_Low as AnnualDiff
	   , SMA_50 as RecentSMA_50
	   , High as RecentHigh
	   , Low as RecentLow
	   , Volume as RecentVolume
	   , Annual_High as AnnualHigh
	   , Annual_Low as AnnualLow
into #HistoricalRecentData
from singlerowhistorical
where prio = 1;

-- 02 Creates the caluclation for the historical data.
select Ticker
	   ,AVG(High) as AverageHigh
	   ,AVG(Low) as AverageLow
	   ,AVG(Volume) as AverageVolume
	   ,AVG(SMA_50) as AverageSMA_50
	   ,count(Ticker) over () as TotalCounts
into #HistoricalAverageData
from portfolio.dbo.Historical_Data
group by Ticker;

--03 Creates calculations and score based on ranking. (Why is average volume being retarded look into this Maybe reload as bigger into or float)

with HistoricalRankings  as (
select hist.Ticker
	,DENSE_RANK() over(order by AverageHigh - AverageSMA_50 asc) as AverageHighToAverageSMA
	,DENSE_RANK() over(order by AverageLow - AverageSMA_50 asc) as AverageLowToAverageSMA
	,DENSE_RANK() over(order by RecentHigh - AverageSMA_50 asc) as RecentHighToAverageSMA
	,DENSE_RANK() over(order by RecentLow - AverageSMA_50 asc) as RecentLowToAverageSMA
	,DENSE_RANK() over(order by AverageHigh - RecentSMA_50 asc) as AverageHighToRecentSMA
	,DENSE_RANK() over(order by AverageLow - RecentSMA_50 asc) as AverageLowToRecentSMA
	,DENSE_RANK() over(order by RecentHigh - RecentSMA_50 asc) as RecentHighToRecentSMA
	,DENSE_RANK() over(order by RecentLow - RecentSMA_50 asc) as RecentLowToRecentSMA
	,DENSE_RANK() over(order by AnnualHigh - RecentSMA_50 asc) as AnnualHighToRecentSMA
	,DENSE_RANK() over(order by AnnualLow - RecentSMA_50 asc) as AnnualLowToRecentSMA
	,DENSE_RANK() over(order by AnnualHigh - AverageSMA_50 asc) as AnnualHighToAverageSMA
	,DENSE_RANK() over(order by AnnualLow - AverageSMA_50 asc) as AnnualLowToAverageSMA
	,DENSE_RANK() over(order by RecentVolume - AverageVolume asc) as AverageVolumeToRecentVolume
	,TotalCounts
	from #HistoricalAverageData as hist
inner join #HistoricalRecentData as rec
on hist.Ticker = rec.Ticker
)
select Ticker
		,cast(cast(AverageHighToAverageSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AverageHighToAverageSMA_Score
		,cast(cast(AverageLowToAverageSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AverageLowToAverageSMA_Score
		,cast(cast(RecentHighToAverageSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as RecentHighToAverageSMA_Score
		,cast(cast(RecentLowToAverageSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as RecentLowToAverageSMA_Score
		,cast(cast(AverageHighToRecentSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AverageHighToRecentSMA_Score
		,cast(cast(AverageLowToRecentSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AverageLowToRecentSMA_Score
		,cast(cast(RecentHighToRecentSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as RecentHighToRecentSMA_Score
		,cast(cast(RecentLowToRecentSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as RecentLowToRecentSMA_Score
		,cast(cast(AnnualHighToRecentSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AnnualHighToRecentSMA_Score
		,cast(cast(AnnualLowToRecentSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AnnualLowToRecentSMA_Score
		,cast(cast(AnnualHighToAverageSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AnnualHighToAverageSMA_Score
		,cast(cast(AnnualLowToAverageSMA as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AnnualLowToAverageSMA_Score
		,cast(cast(AverageVolumeToRecentVolume as float) / cast(TotalCounts as float) as decimal(7,5)) * 7.69230 as AverageVolumeToRecentVolume_Score		
into #HistoricalScoring
from HistoricalRankings
order by AverageHighToAverageSMA desc

--------------------------------------------------------------------------------------------------------------------------
--Final score 
with FinalScoreCreation as (
select Ticker
	  ,sum(AverageHighToAverageSMA_Score + AverageLowToAverageSMA_Score + RecentHighToAverageSMA_Score + RecentLowToAverageSMA_Score +AverageHighToRecentSMA_Score +
	  AverageLowToRecentSMA_Score + RecentHighToRecentSMA_Score + RecentLowToRecentSMA_Score + AnnualHighToRecentSMA_Score + AnnualLowToRecentSMA_Score
	  + AnnualHighToAverageSMA_Score + AnnualLowToAverageSMA_Score + AverageVolumeToRecentVolume_Score) as FinalHistoricalScore
	  ,sum (short_score + price_to_book_score + quick_ratio_score + current_ratio_score + debt_to_equity_score +
		return_on_assets + return_on_equity_score + expert_score) as FinalInfoScore
from #HistoricalScoring as hist
inner join Portfolio.dbo.Info_Data as info
on info.Symbol = hist.Ticker
group by Ticker 
)
select Ticker
	  ,AVG(FinalHistoricalScore + FinalInfoScore) / 2 as FinalAverageScore
from FinalScoreCreation
group by Ticker
Order by FinalAverageScore desc


---------------------------------------------------------------------------------
