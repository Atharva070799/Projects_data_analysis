select * from project.dbo.Data1

select * from project.dbo.Data2

-- number of rows into our dataset
select count(*) from project..Data1

select count(*) from project..Data2

-- dataset for jharkhand and bihar
select * from Project..Data1 where State in ('jharkhand', 'bihar')

-- population of India
select sum(population)  as Total_population from project..Data2

-- avg growth 
select avg(growth) * 100 as avg_growth from project..data1 

-- avg growth by state
select state, avg(growth) * 100 as avg_growth from project..data1 group by state

-- avg sex ratio
select state, round(avg(Sex_Ratio),0) as avg_sex_ratio from project..data1 group by state order by avg(Sex_Ratio) desc

-- avg literacy rate
select state, round(avg(Literacy),0) as avg_literacy from project..data1 
group by state having round(avg(Literacy),0)>90 order by avg(Literacy) desc

-- top 3 state showing highest growth ratio
select top 3 state, avg(growth) * 100 as avg_growth from project..data1 group by state order by avg_growth desc

--bottom 3 state showing lowest sex ratio
select top 3 state, round(avg(Sex_Ratio),0) as avg_sex_ratio from project..data1 group by state order by avg(Sex_Ratio) asc

-- top and bottom 3 states in literacy state
drop table if exists #topstates
create table #topstates
(state nvarchar(255),
  topstate float
  )

  insert into #topstates
  select state, round(avg(Literacy),0) as avg_literacy_ratio from project..data1 
group by state order by avg_literacy_ratio  desc

select top 3 * from #topstates order by #topstates.topstate desc

drop table if exists #bottomstates
create table #bottomstates
(state nvarchar(255),
  bottomstate float
  )

  insert into #bottomstates
  select state, round(avg(Literacy),0) as avg_literacy_ratio from project..data1 
group by state order by avg_literacy_ratio  asc

select top 3 * from #bottomstates order by #bottomstates.bottomstate asc

--union operator
select * from (
select top 3 * from #topstates order by #topstates.topstate desc) a

union

select * from (
select top 3 * from #bottomstates order by #bottomstates.bottomstate asc) b;

-- states starting with letter a
select distinct state from project..Data1 where lower(state) like  'a%' or lower(state) like 'b%'

select distinct state from project..Data1 where lower(state) like  'a%' or lower(state) like '%d'


-- joining both table

--total males and females

select d.state, sum(d.males) as total_males, sum(d.females) as total_females from
(select c.district,c.state, round(c.population/(c.sex_ratio + 1),0) as males, round((c.population*c.sex_ratio)/(c.sex_ratio+1),0) as females from 
(select a.district,a.state,a.sex_ratio/1000 as sex_ratio,b.population from project..data1 as a join project..data2 as b on a.district=b.district) as c) d
group by d.state;

-- total literacy rate

select e.state,sum(e.literate_people) as total_literate_people,sum(e.illiterate_people) as total_illiterate_pepole from
(select d.district,d.state,round(d.literacy_ratio*d.population,0) literate_people,
round((1-d.literacy_ratio)* d.population,0) illiterate_people from 
(select a.district,a.state,a.literacy/100 literacy_ratio,b.population from project..data1 a 
 join project..data2 b on a.district=b.district) d) e
 group by e.state;

 -- population in previous census

 select sum(f.previous_census_population),sum(f.currenr_census_population) from
 (select d.state,sum(d.previous_census_population) as previous_census_population ,sum(d.currenr_census_population)  currenr_census_population from
 (select c.district,c.state,round(c.population/(1+c.growth),0) previous_census_population,c.population as currenr_census_population from
 (select a.district,a.state,a.Growth as growth,b.population from project..data1 as a join project..data2 as b on a.district=b.district)c)d
 group by d.state) f

 -- population vs area

 select (i.total_area/i.previous_census_population)  as previous_census_population_vs_area, (i.total_area/i.current_census_population) as 
current_census_population_vs_area from

(select x.*,y.total_area from(

 select '1' as keyy,g. * from(
  select sum(f.previous_census_population) previous_census_population,sum(f.current_census_population) current_census_population from
 (select d.state,sum(d.previous_census_population) as previous_census_population ,sum(d.current_census_population)  current_census_population from
 (select c.district,c.state,round(c.population/(1+c.growth),0) previous_census_population,c.population as current_census_population from
 (select a.district,a.state,a.Growth as growth,b.population from project..data1 as a join project..data2 as b on a.district=b.district)c)d
 group by d.state) f)g)x join (

 select '1' as keyy,h.* from(
 select sum(area_km2) as total_area from project..data2)h) y on x.keyy = y.keyy)i

 --window 
--output top 3 districts from each state with highest literacy rate

select a.* from (
select district,state,literacy, rank() over(partition by state order by literacy) rnk from project..data1) a
where rnk in(1,2,3) order by state,literacy desc

 




