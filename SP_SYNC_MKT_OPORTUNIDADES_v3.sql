USE [BI_SAPB1];
GO

/* =====================================================================
   CONSOLIDADO DE OPORTUNIDADES - v3  (SQL Server)
   Alineado con las vistas HANA MAESTRO v3:
     - Industria del cliente (CodIndustria / NomIndustria)
     - Industria de la oportunidad (CodIndustriaOport / NomIndustriaOport)
     - NroAsunto, Sucursal (OUBR/fallback), sin columna "razon"

   Requisito: las 11 vistas VW_MKT_OPORTUNIDADES_* (v3) ya creadas en HANA.
   La tabla se auto-infiere desde la vista (SELECT TOP 0 ... INTO) -> sin
   adivinar tipos. Ejecutar TODO el script de corrido.
   ===================================================================== */


/* ---------------------------------------------------------------------
   PASO 1 - Borrar tablas viejas (consolidada y staging) por cambio de columnas
   --------------------------------------------------------------------- */
IF OBJECT_ID('dbo.TBL_MKT_OPORTUNIDADES_STG', 'U') IS NOT NULL
    DROP TABLE dbo.TBL_MKT_OPORTUNIDADES_STG;
GO
IF OBJECT_ID('dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO', 'U') IS NOT NULL
    DROP TABLE dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO;
GO


/* ---------------------------------------------------------------------
   PASO 2 - Crear la tabla consolidada con estructura AUTO-INFERIDA
   (Sociedad + todas las columnas de la vista, tipos exactos)
   --------------------------------------------------------------------- */
SELECT TOP 0
    CAST(N'' AS NVARCHAR(50)) AS [Sociedad],
    *
INTO dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO
FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_CL"');
GO


/* ---------------------------------------------------------------------
   PASO 3 - Crear / actualizar el procedimiento (staging + swap atomico)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE [dbo].[SP_SYNC_MKT_OPORTUNIDADES]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Staging con la misma estructura que la consolidada
        IF OBJECT_ID('dbo.TBL_MKT_OPORTUNIDADES_STG', 'U') IS NOT NULL
            TRUNCATE TABLE dbo.TBL_MKT_OPORTUNIDADES_STG;
        ELSE
            SELECT * INTO dbo.TBL_MKT_OPORTUNIDADES_STG
            FROM dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO WHERE 1 = 0;

        -- Carga de los 11 origenes a staging
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'RENTAL',      * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_CL"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'TRAINING',    * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_TRAINING"."VW_MKT_OPORTUNIDADES_TRAINING"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'ALOLOGISTIC', * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_ALOLOGISTIC"."VW_MKT_OPORTUNIDADES_LOG"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'VENTAS_USD',  * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_ALOVENTAS_USD"."VW_MKT_OPORTUNIDADES_VTA"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'ARGENTINA',   * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGAR_V2"."VW_MKT_OPORTUNIDADES_AR"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'COLOMBIA',    * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGCO"."VW_MKT_OPORTUNIDADES_COL"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'PERU',        * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGP2"."VW_MKT_OPORTUNIDADES_PE"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'PANAMA',      * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGPA"."VW_MKT_OPORTUNIDADES_PAN"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'PARAGUAY',    * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_ALOPY"."VW_MKT_OPORTUNIDADES_PY"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'URUGUAY',     * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_ALOUY"."VW_MKT_OPORTUNIDADES_UY"');
        INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_STG
        SELECT 'ECUADOR',     * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AREC"."VW_MKT_OPORTUNIDADES_ECU"');

        -- Swap atomico: la tabla final nunca queda vacia si un pais falla
        BEGIN TRANSACTION;
            TRUNCATE TABLE dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO;
            INSERT INTO dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO
            SELECT * FROM dbo.TBL_MKT_OPORTUNIDADES_STG;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


/* ---------------------------------------------------------------------
   PASO 4 - Primera ejecucion
   --------------------------------------------------------------------- */
EXEC dbo.SP_SYNC_MKT_OPORTUNIDADES;
GO


/* ---------------------------------------------------------------------
   PASO 5 - Validaciones
   --------------------------------------------------------------------- */
-- Conteo por sociedad
SELECT Sociedad, COUNT(*) AS Registros
FROM dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO
GROUP BY Sociedad
ORDER BY Sociedad;

-- Verificar columnas nuevas de industria
SELECT TOP 20 Sociedad, CodIndustria, NomIndustria, CodIndustriaOport, NomIndustriaOport
FROM dbo.TBL_MKT_OPORTUNIDADES_CONSOLIDADO;
GO
