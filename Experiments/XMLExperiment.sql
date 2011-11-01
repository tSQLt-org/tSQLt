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
 
 -- select @cmd as cmd
 --for xml raw
 
 --this is the problem:
 set @cmd=@cmd+char(0)
 
 
  select @cmd as cmd,cast(@cmd as varbinary(max)) as cmd2,null as cmd3
 for xml path('')
 
 declare @x xml = (
 select @cmd as cmd,cast(@cmd as varbinary(max)) as cmd2,null as cmd3
 for xml path(''))
 select a.value('cmd[1]', 'varchar(max)') cmd,CAST(a.value('cmd2[1]', 'varBINARY(max)') as NVARCHAR(MAX)) cmd2
 from @x.nodes('.') n(a)
 
go 3
drop table #tst