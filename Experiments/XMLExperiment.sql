/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
GO
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