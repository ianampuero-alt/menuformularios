/* =====================================================================
   VW_MKT_OPORTUNIDADES - MAESTRO v2 (11 esquemas)
   Mejoras aplicadas (igual que la vista de test):
     - Eliminada la columna "razon" duplicada.
     - + CodIndustria (OCRD.IndustryC) y NomIndustria (OOND.IndName).
     - + NroAsunto (OCLG.CntctSbjct).
     - Sucursal = COALESCE(OUBR.Name, OTER.descript)  [via OUSR.Branch]
     - Una fila por oportunidad (ultima actividad).

   Grupos por campos U_:
     A) COMPLETO (todos los U_): Rental, Argentina, Peru, Colombia,
        Paraguay, Uruguay, Ecuador.
     B) SIN U_TipoNegocio (resto U_ real): Training, Panama, Ventas.
     C) SIN NINGUN U_ (todos NULL): Logistic.

   OJO: agrega 3 columnas -> actualizar la tabla+SP de SQL Server y la
   VW_..._GLOBAL para que el job consolidado no falle.
   ===================================================================== */


/* ===== 1) RENTAL  SBO_PARAMETROS_RENTAL  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_CL" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PARAMETROS_RENTAL"."OOPR" OPR
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PARAMETROS_RENTAL"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 2) ARGENTINA  SBO_PRD_AGAR_V2  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGAR_V2"."VW_MKT_OPORTUNIDADES_AR" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_AGAR_V2"."OOPR" OPR
LEFT JOIN "SBO_PRD_AGAR_V2"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_AGAR_V2"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGAR_V2"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGAR_V2"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_AGAR_V2"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGAR_V2"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGAR_V2"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 3) PERU  SBO_PRD_AGP2  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGP2"."VW_MKT_OPORTUNIDADES_PE" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_AGP2"."OOPR" OPR
LEFT JOIN "SBO_PRD_AGP2"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_AGP2"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_AGP2"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGP2"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGP2"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGP2"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGP2"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGP2"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_AGP2"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGP2"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGP2"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 4) COLOMBIA  SBO_PRD_AGCO  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGCO"."VW_MKT_OPORTUNIDADES_COL" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_AGCO"."OOPR" OPR
LEFT JOIN "SBO_PRD_AGCO"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_AGCO"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_AGCO"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGCO"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGCO"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGCO"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGCO"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGCO"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_AGCO"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGCO"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGCO"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 5) PARAGUAY  SBO_PRD_ALOPY  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_ALOPY"."VW_MKT_OPORTUNIDADES_PY" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_ALOPY"."OOPR" OPR
LEFT JOIN "SBO_PRD_ALOPY"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_ALOPY"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_ALOPY"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_ALOPY"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_ALOPY"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_ALOPY"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_ALOPY"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_ALOPY"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_ALOPY"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_ALOPY"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_ALOPY"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 6) URUGUAY  SBO_PRD_ALOUY  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_ALOUY"."VW_MKT_OPORTUNIDADES_UY" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_ALOUY"."OOPR" OPR
LEFT JOIN "SBO_PRD_ALOUY"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_ALOUY"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_ALOUY"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_ALOUY"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_ALOUY"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_ALOUY"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_ALOUY"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_ALOUY"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_ALOUY"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_ALOUY"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_ALOUY"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 7) ECUADOR  SBO_PRD_AREC  (Grupo A) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AREC"."VW_MKT_OPORTUNIDADES_ECU" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", OPR."U_TipoNegocio" AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_AREC"."OOPR" OPR
LEFT JOIN "SBO_PRD_AREC"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_AREC"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_AREC"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AREC"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AREC"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AREC"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AREC"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AREC"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_AREC"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AREC"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AREC"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 8) TRAINING  SBO_PARAMETROS_TRAINING  (Grupo B: TipoNegocio NULL) ===== */
CREATE OR REPLACE VIEW "SBO_PARAMETROS_TRAINING"."VW_MKT_OPORTUNIDADES_TRAINING" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", CAST(NULL AS NVARCHAR(50)) AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PARAMETROS_TRAINING"."OOPR" OPR
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PARAMETROS_TRAINING"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 9) PANAMA  SBO_PRD_AGPA  (Grupo B: TipoNegocio NULL) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGPA"."VW_MKT_OPORTUNIDADES_PAN" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", CAST(NULL AS NVARCHAR(50)) AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_AGPA"."OOPR" OPR
LEFT JOIN "SBO_PRD_AGPA"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_AGPA"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_AGPA"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGPA"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGPA"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGPA"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGPA"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGPA"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_AGPA"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGPA"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGPA"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 10) VENTAS  SBO_PRD_ALOVENTAS_USD  (Grupo B: TipoNegocio NULL) ===== */
CREATE OR REPLACE VIEW "SBO_PRD_ALOVENTAS_USD"."VW_MKT_OPORTUNIDADES_VTA" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    OPR."U_ContConf" AS "FueContactado", OPR."U_ContDate" AS "FechaContacto", CAST(OPR."U_ContHour" AS NVARCHAR(50)) AS "HoraContacto",
    OPR."U_SolCotConf" AS "SolicitoCotizacion", OPR."U_RecCotConf" AS "RecibioCotizacion",
    OPR."U_RecCotDate" AS "FechaRecepcion", CAST(OPR."U_RecCotHour" AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", CAST(NULL AS NVARCHAR(50)) AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PRD_ALOVENTAS_USD"."OOPR" OPR
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_ALOVENTAS_USD"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== 11) LOGISTIC  SBO_PARAMETROS_ALOLOGISTIC  (Grupo C: todos los U_ NULL) ===== */
CREATE OR REPLACE VIEW "SBO_PARAMETROS_ALOLOGISTIC"."VW_MKT_OPORTUNIDADES_LOG" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(NULL AS NVARCHAR(100)) AS "NomCompetidor", CAST(NULL AS NVARCHAR(100)) AS "Ganador",
    T2."E_Mail" AS "Email", CL."Name" AS "Cliente_Actividad", A."CntctDate" AS "FechaActividad", CL."E_MailL" AS "CorreoCliente",
    CAST(NULL AS NVARCHAR(50)) AS "FueContactado", CAST(NULL AS TIMESTAMP) AS "FechaContacto", CAST(NULL AS NVARCHAR(50)) AS "HoraContacto",
    CAST(NULL AS NVARCHAR(50)) AS "SolicitoCotizacion", CAST(NULL AS NVARCHAR(50)) AS "RecibioCotizacion",
    CAST(NULL AS TIMESTAMP) AS "FechaRecepcion", CAST(NULL AS NVARCHAR(50)) AS "HoraRecepcion",
    OPR."MaxSumLoc" AS "ImportePotencial", CURRENT_DATE AS "FechaInforme", CURRENT_TIME AS "HoraInforme",
    OPR."PrjCode" AS "Proyecto", CAST(NULL AS NVARCHAR(50)) AS "TipodeNegocio",
    OPR."Name" AS "Nombredeoportunidad", T9."U_NAME" AS "UsuarioCreacion"
FROM "SBO_PARAMETROS_ALOLOGISTIC"."OOPR" OPR
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OCRD" T2 ON T2."CardCode" = OPR."CardCode"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOND" IND ON IND."IndCode" = T2."IndustryC"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PARAMETROS_ALOLOGISTIC"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;
