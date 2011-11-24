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
IF OBJECT_ID('Accelerator.IsExperimentReady') IS NOT NULL DROP FUNCTION Accelerator.IsExperimentReady;
GO

CREATE FUNCTION Accelerator.IsExperimentReady()
RETURNS BIT
AS
BEGIN 
  DECLARE @NumParticles INT;
  
  SELECT @NumParticles = COUNT(1) FROM Accelerator.Particle;
  
  IF @NumParticles > 2
    RETURN 1;

  RETURN 0;
END;
GO


IF OBJECT_ID('Accelerator.GetParticlesInRectangle') IS NOT NULL DROP FUNCTION Accelerator.GetParticlesInRectangle;
GO

CREATE FUNCTION Accelerator.GetParticlesInRectangle(
  @X1 DECIMAL(10,2),
  @Y1 DECIMAL(10,2),
  @X2 DECIMAL(10,2),
  @Y2 DECIMAL(10,2)
)
RETURNS TABLE
AS RETURN (
  SELECT Id, X, Y, Value 
    FROM Accelerator.Particle
   WHERE X > @X1 AND X < @X2
         AND
         Y > @Y1 AND Y < @Y2
);
GO

IF OBJECT_ID('Accelerator.SendHiggsBosonDiscoveryEmail') IS NOT NULL DROP PROCEDURE Accelerator.SendHiggsBosonDiscoveryEmail;
GO

CREATE PROCEDURE Accelerator.SendHiggsBosonDiscoveryEmail
  @EmailAddress NVARCHAR(MAX)
AS
BEGIN
  RAISERROR('Not Implemented - yet',16,10);
END;
GO

IF OBJECT_ID('Accelerator.AlertParticleDiscovered') IS NOT NULL DROP PROCEDURE Accelerator.AlertParticleDiscovered;
GO

CREATE PROCEDURE Accelerator.AlertParticleDiscovered
  @ParticleDiscovered NVARCHAR(MAX)
AS
BEGIN
  IF @ParticleDiscovered = 'Higgs Boson'
  BEGIN
    EXEC Accelerator.SendHiggsBosonDiscoveryEmail 'particle-discovery@new-era-particles.tsqlt.org';
  END;
END;
GO

IF OBJECT_ID('Accelerator.GetStatusMessage') IS NOT NULL DROP FUNCTION Accelerator.GetStatusMessage;
GO

CREATE FUNCTION Accelerator.GetStatusMessage()
  RETURNS NVARCHAR(MAX)
AS
BEGIN
  DECLARE @NumParticles INT;
  SELECT @NumParticles = COUNT(1) FROM Accelerator.Particle;
  RETURN 'The Accelerator is prepared with ' + CAST(@NumParticles AS NVARCHAR(MAX)) + ' particles.';
END;
GO

IF OBJECT_ID('Accelerator.FK_ParticleColor') IS NOT NULL ALTER TABLE Accelerator.Particle DROP CONSTRAINT FK_ParticleColor;
GO

ALTER TABLE Accelerator.Particle ADD CONSTRAINT FK_ParticleColor FOREIGN KEY (ColorId) REFERENCES Accelerator.Color(Id);
GO