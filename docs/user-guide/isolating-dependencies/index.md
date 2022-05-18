# Isolating dependencies

This group of objects enables you to isolate the are of code which you are testing. When you are unit testing a complex system, it is desirable to isolate certain parts to test. For example, if you have a complicated set of tables which are related through foreign keys, it can be very difficult to insert test data into one of the tables. The objects in this section provide the ability to focus on a single unit to test.

- [ApplyConstraint](applyconstraint.md)
- [ApplyTrigger](applytrigger.md)
- [FakeFunction](fakefunction.md)
- [FakeTable](faketable.md)
- [RemoveObject](removeobject.md)
- [RemoveObjectIfExists](removeobjectifexists.md)
- [SpyProcedure](spyprocedure.md)