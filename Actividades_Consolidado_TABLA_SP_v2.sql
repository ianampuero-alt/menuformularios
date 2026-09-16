USE [BI_SAPB1];
GO

/* =====================================================================
   CONSOLIDADO DE ACTIVIDADES - v2 (SQL Server)
   Cambios vs v1:
     - Tabla AUTO-INFERIDA desde la vista (sin tipos a mano -> sin truncado)
     - Se agrega VENTAS_USD (11 sociedades, alineado con Oportunidades)
   Requisito: las 11 vistas AG_VS_ACTIVIDADES_* ya creadas en HANA
   (incluida AG_VS_ACTIVIDADES_VTA en el esquema SBO_PRD_ALOVENTAS_USD).
   Ejecutar los PASO 1 y 2 UNA sola vez; el PASO 3 (procedure) queda fijo.
   ===================================================================== */


/* ---------------------------------------------------------------------
   PASO 1 - Borrar tablas viejas (tipos a mano) y su staging
   --------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Actividades_Consolidado_STG', 'U') IS NOT NULL
    DROP TABLE dbo.Actividades_Consolidado_STG;
GO
IF OBJECT_ID('dbo.Actividades_Consolidado', 'U') IS NOT NULL
    DROP TABLE dbo.Actividades_Consolidado;
GO


/* ---------------------------------------------------------------------
   PASO 2 - Recrear la tabla consolidada con estructura AUTO-INFERIDA
   ([Empresa] primero + las 32 columnas de la vista, tipos exactos)
   --------------------------------------------------------------------- */
SELECT TOP 0
    CAST(N'' AS NVARCHAR(50)) AS [Empresa],
    *
INTO dbo.Actividades_Consolidado
FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_RENTAL"."AG_VS_ACTIVIDADES_RENTAL"');
GO


/* ---------------------------------------------------------------------
   PASO 3 - Crear / actualizar el procedimiento (staging + swap atomico)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE [dbo].[SP_Actualizar_Actividades_Consolidado]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Fecha de corte: hoy menos 1 AÑO (formato ISO para comparar con el texto 'YYYY-MM-DD')
    DECLARE @Desde CHAR(10) = CONVERT(CHAR(10), DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)), 23);

    BEGIN TRY
        -- Staging con la misma estructura que la consolidada
        IF OBJECT_ID('dbo.Actividades_Consolidado_STG', 'U') IS NOT NULL
            TRUNCATE TABLE dbo.Actividades_Consolidado_STG;
        ELSE
            SELECT * INTO dbo.Actividades_Consolidado_STG
            FROM dbo.Actividades_Consolidado WHERE 1 = 0;

        -- Carga de los 11 origenes a staging
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Rental',   * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_RENTAL"."AG_VS_ACTIVIDADES_RENTAL"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Training', * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_TRAINING"."AG_VS_ACTIVIDADES_TRAI"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Logistic', * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_ALOLOGISTIC"."AG_VS_ACTIVIDADES_LOGIS"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Ventas',   * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_ALOVENTAS_USD"."AG_VS_ACTIVIDADES_VTA"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Panama',           * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGPA"."AG_VS_ACTIVIDADES_PAN"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Argentina',        * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGAR_V2"."AG_VS_ACTIVIDADES_ARG"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Colombia',         * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGCO"."AG_VS_ACTIVIDADES_COL"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Ecuador',          * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AREC"."AG_VS_ACTIVIDADES_ECU"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Peru',             * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AGP2"."AG_VS_ACTIVIDADES_PE"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Paraguay',         * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_ALOPY"."AG_VS_ACTIVIDADES_PY"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Uruguay',          * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_ALOUY"."AG_VS_ACTIVIDADES_UY"');

        -- Swap atomico: solo ultimo AÑO por FECHA DE CONTACTO
        BEGIN TRANSACTION;
            TRUNCATE TABLE dbo.Actividades_Consolidado;
            INSERT INTO dbo.Actividades_Consolidado
            SELECT * FROM dbo.Actividades_Consolidado_STG
            WHERE [FechaContacto] >= @Desde;      -- <<< ultimo año
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
EXEC dbo.SP_Actualizar_Actividades_Consolidado;
GO


/* ---------------------------------------------------------------------
   PASO 5 - Validaciones
   --------------------------------------------------------------------- */
SELECT Empresa, COUNT(*) AS Registros
FROM dbo.Actividades_Consolidado
GROUP BY Empresa
ORDER BY Empresa;
GO

-- Chequeo puntual de Ecuador (si no aparece arriba, confirmar que la vista trae filas)
-- SELECT COUNT(*) AS FilasEcuador
-- FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PRD_AREC"."AG_VS_ACTIVIDADES_ECU"');
