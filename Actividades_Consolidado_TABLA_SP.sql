USE [BI_SAPB1];
GO

/* =====================================================================
   TABLA CONSOLIDADA DE ACTIVIDADES (Empresa + 32 columnas de la vista)
   Fuente: vistas HANA AG_VS_ACTIVIDADES_* via linked server LK_HANA.
   ===================================================================== */
IF OBJECT_ID('dbo.Actividades_Consolidado', 'U') IS NOT NULL
    DROP TABLE dbo.Actividades_Consolidado;
GO

CREATE TABLE dbo.Actividades_Consolidado (
    [Empresa]                NVARCHAR(50),
    [CodigoActividad]        INT,
    [CodigoCliente]          NVARCHAR(15),
    [Notas]                  NVARCHAR(255),
    [FechaContacto]          VARCHAR(5000),
    [HoraContacto]           VARCHAR(6),
    [FechaRecontacto]        VARCHAR(5000),
    [Cerrado]                NVARCHAR(1),
    [FechaCierre]            VARCHAR(5000),
    [CodigoAsunto]           SMALLINT,
    [IDUsuarioAsignado]      SMALLINT,
    [IDUsuarioCreador]       SMALLINT,
    [NombreUsuarioCreador]   NVARCHAR(155),
    [Calle]                  NVARCHAR(100),
    [Ciudad]                 NVARCHAR(100),
    [Pais]                   NVARCHAR(3),
    [Region]                 NVARCHAR(3),
    [CodigoAccion]           NVARCHAR(1),
    [DescripcionAccion]      VARCHAR(19),
    [NombreVendedor]         NVARCHAR(155),
    [Asunto]                 NVARCHAR(20),
    [CodigoTipoContacto]     SMALLINT,
    [TipoContacto]           NVARCHAR(20),
    [Duracion]               DECIMAL(21,6),
    [Detalles]               NVARCHAR(100),
    [TipoDocumentoID]        NVARCHAR(20),
    [NumeroDocumento]        NVARCHAR(50),
    [IDEmpleadoAsignado]     INT,
    [NombreCliente]          NVARCHAR(100),
    [TipoDocumento]          VARCHAR(29),
    [NombreUsuarioAsignado]  NVARCHAR(155),
    [TipoPadre]              NVARCHAR(20),
    [IDPadre]                INT
);
GO


/* =====================================================================
   PROCEDIMIENTO DE ACTUALIZACION
   Carga a staging, valida, y hace swap atomico (la tabla final nunca
   queda vacia si un pais falla).
   ===================================================================== */
CREATE OR ALTER PROCEDURE [dbo].[SP_Actualizar_Actividades_Consolidado]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Staging con la misma estructura
        IF OBJECT_ID('dbo.Actividades_Consolidado_STG', 'U') IS NOT NULL
            TRUNCATE TABLE dbo.Actividades_Consolidado_STG;
        ELSE
            SELECT * INTO dbo.Actividades_Consolidado_STG
            FROM dbo.Actividades_Consolidado WHERE 1 = 0;

        -- Carga de los 10 origenes a staging
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Rental',   * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_RENTAL"."AG_VS_ACTIVIDADES_RENTAL"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Training', * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_TRAINING"."AG_VS_ACTIVIDADES_TRAI"');
        INSERT INTO dbo.Actividades_Consolidado_STG
        SELECT 'Chile - Logistic', * FROM OPENQUERY([LK_HANA], 'SELECT * FROM "SBO_PARAMETROS_ALOLOGISTIC"."AG_VS_ACTIVIDADES_LOGIS"');
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

        -- Swap atomico
        BEGIN TRANSACTION;
            TRUNCATE TABLE dbo.Actividades_Consolidado;
            INSERT INTO dbo.Actividades_Consolidado
            SELECT * FROM dbo.Actividades_Consolidado_STG;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
