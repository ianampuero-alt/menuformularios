/* =====================================================================
   TABLA FISICA + PROCEDIMIENTO DE REFRESCO
   Objeto consolidado de oportunidades (11 sociedades/paises).

   Requisito previo: debe existir la vista
     "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_GLOBAL"

   Flujo:
     1) Crear tabla fisica (una sola vez).
     2) Crear/actualizar el procedimiento de refresco.
     3) El job llama al procedimiento (CALL) segun la frecuencia deseada.
   ===================================================================== */


/* =====================================================================
   PASO 1 - CREAR LA TABLA FISICA (ejecutar UNA sola vez)
   Se crea con la MISMA estructura y tipos que la vista, vacia.
   Si necesitas recrearla, primero: DROP TABLE ... (abajo hay comentario)
   ===================================================================== */
-- DROP TABLE "SBO_PARAMETROS_RENTAL"."MKT_OPORTUNIDADES_GLOBAL";   -- usar solo si necesitas recrearla

CREATE COLUMN TABLE "SBO_PARAMETROS_RENTAL"."MKT_OPORTUNIDADES_GLOBAL" AS (
    SELECT * FROM "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_GLOBAL"
) WITH NO DATA;


/* =====================================================================
   PASO 2 - PROCEDIMIENTO ALMACENADO DE REFRESCO
   Vacia la tabla y la vuelve a llenar desde la vista consolidada.
   Registra fecha/hora de la ultima carga (opcional, ver tabla de log).
   ===================================================================== */
CREATE OR REPLACE PROCEDURE "SBO_PARAMETROS_RENTAL"."SP_REFRESH_MKT_OPORTUNIDADES_GLOBAL"
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS
BEGIN
    -- Vacia la tabla (rapido, no genera log fila por fila)
    TRUNCATE TABLE "SBO_PARAMETROS_RENTAL"."MKT_OPORTUNIDADES_GLOBAL";

    -- Recarga desde la vista consolidada (los 11 esquemas)
    INSERT INTO "SBO_PARAMETROS_RENTAL"."MKT_OPORTUNIDADES_GLOBAL"
    SELECT * FROM "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_GLOBAL";

    COMMIT;
END;


/* =====================================================================
   PASO 3 - EJECUCION MANUAL (para probar)
   ===================================================================== */
-- CALL "SBO_PARAMETROS_RENTAL"."SP_REFRESH_MKT_OPORTUNIDADES_GLOBAL";

-- Validar carga:
-- SELECT "Pais","Sociedad", COUNT(*) FROM "SBO_PARAMETROS_RENTAL"."MKT_OPORTUNIDADES_GLOBAL" GROUP BY "Pais","Sociedad" ORDER BY 1,2;


/* =====================================================================
   PASO 4 - JOB PROGRAMADO (opcion nativa de HANA)
   Ajusta CRON a la frecuencia que necesites.
   CRON: <anio> <mes> <dia> <dia_semana> <hora> <min> <seg>
   Ejemplo: todos los dias a las 06:00 -> '* * * * 6 0 0'
   Requiere el privilegio de sistema para crear scheduler jobs.
   Si usas tu propio job/planificador externo, simplemente que ejecute:
     CALL "SBO_PARAMETROS_RENTAL"."SP_REFRESH_MKT_OPORTUNIDADES_GLOBAL";
   ===================================================================== */
-- CREATE SCHEDULER JOB "SBO_PARAMETROS_RENTAL"."JOB_REFRESH_MKT_OPORTUNIDADES_GLOBAL"
--   CRON '* * * * 6 0 0'
--   ENABLE
--   PROCEDURE "SBO_PARAMETROS_RENTAL"."SP_REFRESH_MKT_OPORTUNIDADES_GLOBAL";

-- Para ver / habilitar / borrar el job:
-- SELECT * FROM SYS.SCHEDULER_JOBS WHERE SCHEMA_NAME = 'SBO_PARAMETROS_RENTAL';
-- ALTER SCHEDULER JOB "SBO_PARAMETROS_RENTAL"."JOB_REFRESH_MKT_OPORTUNIDADES_GLOBAL" ENABLE;
-- DROP SCHEDULER JOB "SBO_PARAMETROS_RENTAL"."JOB_REFRESH_MKT_OPORTUNIDADES_GLOBAL";
