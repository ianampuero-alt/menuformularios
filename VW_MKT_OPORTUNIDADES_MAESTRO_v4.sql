/* =====================================================================
   VW_MKT_OPORTUNIDADES - MAESTRO v4 (11 esquemas)
   Novedad v4: se pueblan NomCompetidor y Ganador desde OPR3 (hija de
   competidores por oportunidad) + maestra OCMT (CompetId -> Name).
     - NomCompetidor : lista de competidores concatenada (STRING_AGG)
     - Ganador       : 'Nosotros' si Status='W'; si no, el competidor Won='Y'
   Mantiene todo lo de v3 (doble industria, NroAsunto, Sucursal OUBR/fallback).

   OJO: NomCompetidor pasa a NVARCHAR(255) -> re-ejecutar el PASO 1/2 del
   script de SQL Server (la tabla se auto-infiere de nuevo).

   Grupos:
     A) COMPLETO (U_TipoNegocio + contacto): Rental, Argentina, Peru,
        Colombia, Paraguay, Uruguay, Ecuador
     B) SIN U_TipoNegocio (con contacto): Training, Panama, Ventas
     C) SIN NINGUN U_ (contacto NULL): Logistic
   ===================================================================== */


/* ===== RENTAL (Grupo A)  SBO_PARAMETROS_RENTAL.VW_MKT_OPORTUNIDADES_CL ===== */
CREATE OR REPLACE VIEW "SBO_PARAMETROS_RENTAL"."VW_MKT_OPORTUNIDADES_CL" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PARAMETROS_RENTAL"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PARAMETROS_RENTAL"."OPR3" C LEFT JOIN "SBO_PARAMETROS_RENTAL"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PARAMETROS_RENTAL"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== ARGENTINA (Grupo A)  SBO_PRD_AGAR_V2.VW_MKT_OPORTUNIDADES_AR ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGAR_V2"."VW_MKT_OPORTUNIDADES_AR" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_AGAR_V2"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_AGAR_V2"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGAR_V2"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGAR_V2"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGAR_V2"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_AGAR_V2"."OPR3" C LEFT JOIN "SBO_PRD_AGAR_V2"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_AGAR_V2"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGAR_V2"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGAR_V2"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== PERU (Grupo A)  SBO_PRD_AGP2.VW_MKT_OPORTUNIDADES_PE ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGP2"."VW_MKT_OPORTUNIDADES_PE" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_AGP2"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_AGP2"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGP2"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGP2"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGP2"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGP2"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGP2"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_AGP2"."OPR3" C LEFT JOIN "SBO_PRD_AGP2"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_AGP2"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGP2"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGP2"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== COLOMBIA (Grupo A)  SBO_PRD_AGCO.VW_MKT_OPORTUNIDADES_COL ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGCO"."VW_MKT_OPORTUNIDADES_COL" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_AGCO"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_AGCO"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGCO"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGCO"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGCO"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGCO"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGCO"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_AGCO"."OPR3" C LEFT JOIN "SBO_PRD_AGCO"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_AGCO"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGCO"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGCO"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== PARAGUAY (Grupo A)  SBO_PRD_ALOPY.VW_MKT_OPORTUNIDADES_PY ===== */
CREATE OR REPLACE VIEW "SBO_PRD_ALOPY"."VW_MKT_OPORTUNIDADES_PY" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_ALOPY"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_ALOPY"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_ALOPY"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_ALOPY"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_ALOPY"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_ALOPY"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_ALOPY"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_ALOPY"."OPR3" C LEFT JOIN "SBO_PRD_ALOPY"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_ALOPY"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_ALOPY"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_ALOPY"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== URUGUAY (Grupo A)  SBO_PRD_ALOUY.VW_MKT_OPORTUNIDADES_UY ===== */
CREATE OR REPLACE VIEW "SBO_PRD_ALOUY"."VW_MKT_OPORTUNIDADES_UY" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_ALOUY"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_ALOUY"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_ALOUY"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_ALOUY"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_ALOUY"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_ALOUY"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_ALOUY"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_ALOUY"."OPR3" C LEFT JOIN "SBO_PRD_ALOUY"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_ALOUY"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_ALOUY"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_ALOUY"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== ECUADOR (Grupo A)  SBO_PRD_AREC.VW_MKT_OPORTUNIDADES_ECU ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AREC"."VW_MKT_OPORTUNIDADES_ECU" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_AREC"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_AREC"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AREC"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AREC"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AREC"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AREC"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AREC"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_AREC"."OPR3" C LEFT JOIN "SBO_PRD_AREC"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_AREC"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AREC"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AREC"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== TRAINING (Grupo B: TipoNegocio NULL)  SBO_PARAMETROS_TRAINING.VW_MKT_OPORTUNIDADES_TRAINING ===== */
CREATE OR REPLACE VIEW "SBO_PARAMETROS_TRAINING"."VW_MKT_OPORTUNIDADES_TRAINING" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PARAMETROS_TRAINING"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PARAMETROS_TRAINING"."OPR3" C LEFT JOIN "SBO_PARAMETROS_TRAINING"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PARAMETROS_TRAINING"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== PANAMA (Grupo B: TipoNegocio NULL)  SBO_PRD_AGPA.VW_MKT_OPORTUNIDADES_PAN ===== */
CREATE OR REPLACE VIEW "SBO_PRD_AGPA"."VW_MKT_OPORTUNIDADES_PAN" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_AGPA"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_AGPA"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_AGPA"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_AGPA"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_AGPA"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_AGPA"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_AGPA"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_AGPA"."OPR3" C LEFT JOIN "SBO_PRD_AGPA"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_AGPA"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_AGPA"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_AGPA"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== VENTAS (Grupo B: TipoNegocio NULL)  SBO_PRD_ALOVENTAS_USD.VW_MKT_OPORTUNIDADES_VTA ===== */
CREATE OR REPLACE VIEW "SBO_PRD_ALOVENTAS_USD"."VW_MKT_OPORTUNIDADES_VTA" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PRD_ALOVENTAS_USD"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PRD_ALOVENTAS_USD"."OPR3" C LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PRD_ALOVENTAS_USD"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;


/* ===== LOGISTIC (Grupo C: todos los U_ NULL)  SBO_PARAMETROS_ALOLOGISTIC.VW_MKT_OPORTUNIDADES_LOG ===== */
CREATE OR REPLACE VIEW "SBO_PARAMETROS_ALOLOGISTIC"."VW_MKT_OPORTUNIDADES_LOG" AS SELECT
    OPR."OpprId" AS "NroOport", OPR."CardCode" AS "CodClie", OPR."CardName" AS "NomClie",
    T2."IndustryC" AS "CodIndustria", IND."IndName" AS "NomIndustria",
    OPR."Industry" AS "CodIndustriaOport", IND2."IndName" AS "NomIndustriaOport",
    OPR."SlpCode" AS "CodVend", T3."SlpName" AS "NomVend",
    OPR."Source" AS "CodSource", T6."Descript" AS "NomSource",
    OPR."OpenDate" AS "FechaInicio", OPR."PredDate" AS "FechaPrevista",
    OPR."Status" AS "CodEstado",
    CASE OPR."Status" WHEN 'O' THEN 'Abierta' WHEN 'W' THEN 'Ganada' WHEN 'L' THEN 'Perdida' ELSE OPR."Status" END AS "NomEstado",
    OPR."IntRate" AS "CodIntRate", T4."Descript" AS "MetodoContacto",
    OPR."Reason" AS "CodRazon", T7."Descript" AS "NomRazon",
    A."ClgCode" AS "NroActiv", A."CntctSbjct" AS "NroAsunto", A."Details" AS "ActivAsunt",
    CAST(COALESCE(UBR."Name", T8."descript") AS NVARCHAR(100)) AS "Sucursal",
    CAST(COMP."NomCompetidor" AS NVARCHAR(255)) AS "NomCompetidor",
    CAST(CASE WHEN OPR."Status" = 'W' THEN 'Nosotros' ELSE COMP."Ganador" END AS NVARCHAR(100)) AS "Ganador",
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
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOND" IND2 ON IND2."IndCode" = OPR."Industry"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OSLP" T3 ON T3."SlpCode" = OPR."SlpCode"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOIR" T4 ON T4."Num" = OPR."IntRate"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOSR" T6 ON T6."Num" = OPR."Source"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OOFR" T7 ON T7."Num" = OPR."Reason"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OCPR" CL ON CL."CntctCode" = OPR."CprCode"
LEFT JOIN ( SELECT "OprId","ClgCode","Details","CntctDate","CntctSbjct", ROW_NUMBER() OVER (PARTITION BY "OprId" ORDER BY "CntctDate" DESC, "ClgCode" DESC) AS "RN" FROM "SBO_PARAMETROS_ALOLOGISTIC"."OCLG" ) A ON A."OprId" = OPR."OpprId" AND A."RN" = 1
LEFT JOIN ( SELECT C."OpportId", STRING_AGG(MC."Name", ', ') AS "NomCompetidor", MAX(CASE WHEN C."Won" = 'Y' THEN MC."Name" END) AS "Ganador" FROM "SBO_PARAMETROS_ALOLOGISTIC"."OPR3" C LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OCMT" MC ON MC."CompetId" = C."CompetId" GROUP BY C."OpportId" ) COMP ON COMP."OpportId" = OPR."OpprId"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OTER" T8 ON T8."territryID" = OPR."Territory"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OUSR" T9 ON T9."USERID" = OPR."UserSign"
LEFT JOIN "SBO_PARAMETROS_ALOLOGISTIC"."OUBR" UBR ON UBR."Code" = T9."Branch"
WITH READ ONLY;
