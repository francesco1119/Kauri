  if object_id('tempdb..#run_status') is not null begin drop table #run_status end
    create table #run_status (ID int, description varchar(55))
    insert into #run_status (ID, description)
    values
    (0 , 'Failed'),
    (1 , 'Succeeded'),
    (2 , 'Retry'),
    (3 , 'Canceled'),
    (4 , 'In Progress')

    ;with jobs1 as (SELECT sj.name, sh.run_time as basic_run_time, sh.run_duration as basic_run_duration
    ,STUFF(STUFF(RIGHT('000000' + CAST ( sh.run_time AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') as run_time 
    ,STUFF(STUFF(RIGHT('000000' + CAST ( sh.run_duration AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') as run_duration 
    FROM msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobhistory sh
    ON sj.job_id = sh.job_id
    where run_duration != 0),

    jobs as(
    select *
    ,datediff(minute, 0, run_duration) as calculated_minutes
    from jobs1
    )

    ,averages as (
    select name, avg(calculated_minutes) as average_minutes, round(stdev(calculated_minutes),0) as give_or_take from jobs
    group by name)

    ,last_night1 as (select sj.name, sh.step_id, sh.step_name, sh.message, sh.run_status, sh.run_duration, 
    STUFF(STUFF(RIGHT('000000' + CAST ( sh.run_time AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') as start_time
    ,STUFF(STUFF(RIGHT('000000' + CAST ( sh.run_duration AS VARCHAR(6 ) ) ,6),5,0,':'),3,0,':') as time_running
    ,ROW_NUMBER() over(partition by sj.job_id order by run_date, run_time desc) as ranker FROM 
    msdb.dbo.sysjobs sj
    JOIN msdb.dbo.sysjobhistory sh
    ON sj.job_id = sh.job_id),

    last_night as (select * from last_night1
    where ranker = 1)

    select l.name, l.step_name, r.description as run_status, l.start_time, l.time_running, a.average_minutes, a.give_or_take, 
    left(cast(cast(dateadd(minute, a.average_minutes + a.give_or_take, start_time) as time) as varchar(55)),8)
     as what_time_to_worry 
    from last_night l
    left join averages a on l.name = a.name
    left join #run_status r on l.run_status = r.id
    order by l.name
