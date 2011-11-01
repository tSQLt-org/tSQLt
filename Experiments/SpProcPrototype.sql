create table #tst (pn sysname,cc int, cmd varchar(max))
go
insert into #tst select 'tstp',2,'print $$cc$$';

go
declare @cmd nvarchar(max);
update #tst
  set cc=cc+1,
     @cmd = replace(cmd,'$$cc$$',cast(cc+1 as varchar(max)))
 where pn='tstp'
 exec(@cmd)
go 3
drop table #tst