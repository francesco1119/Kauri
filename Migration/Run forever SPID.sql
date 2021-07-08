


DECLARE @i INT = 1;

WHILE (@i <= 10)
 BEGIN
  WAITFOR DELAY '00:00:01'

       print FORMAT(GETDATE(),'hh:mm:ss')

 SET  @i = @i + 1;
END 



