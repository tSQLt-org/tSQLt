IF OBJECT_ID('Practice.GetParticlesInRectangle') IS NOT NULL DROP FUNCTION Practice.GetParticlesInRectangle;
GO

CREATE FUNCTION Practice.GetParticlesInRectangle(
  @X1 DECIMAL(10,2),
  @Y1 DECIMAL(10,2),
  @X2 DECIMAL(10,2),
  @Y2 DECIMAL(10,2)
)
RETURNS TABLE
AS RETURN (
  SELECT Id, X, Y, Value 
    FROM Practice.Particle
   WHERE X > @X1 + 0.01 AND X < @X2  -- " + 0.01" added to show missing 'expected' row
         AND
         Y > @Y1 AND Y <= @Y2        -- "<= @Y2" instead of "< @Y2" to show missing 'actual' row
);