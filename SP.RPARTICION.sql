
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[sp_cl_reparticion]
/*
-----------------------------------------

	CREATED BY : CARLOS MOREYRA NOEL
	FECHA : 30/03/2023

-----------------------------------------
*/

AS
	TRUNCATE TABLE RESULTADO_REPARTICION
	BEGIN

	/*	Calculo Linea L1	*/
		DECLARE @TotalAutorizaciones INT
		DECLARE	@TotalErrores INT
		DECLARE @TotalFraude INT
		DECLARE @TotalServicios INT
		DECLARE @NumAnalistas INT
		DECLARE @AsignacionAutorizaciones INT
		DECLARE @AsignacionErrores INT
		DECLARE @AsignacionFraude INT
		DECLARE @AsignacionServicios INT
	
	/*	Calculo Linea L3  */

		DECLARE @TotalAutorizaciones_L3 INT
		DECLARE	@TotalErrores_L3 INT
		DECLARE @TotalFraude_L3 INT
		DECLARE @TotalServicios_L3 INT
		DECLARE @NumAnalistas_L3 INT
		DECLARE @AsignacionAutorizaciones_L3 INT
		DECLARE @AsignacionErrores_L3 INT
		DECLARE @AsignacionFraude_L3 INT
		DECLARE @AsignacionServicios_L3 INT


		SET NOCOUNT ON

		-- Obtener el número total de registros por categoría L1
		SELECT @NumAnalistas = (SELECT SUM(Flag_Activo)FROM TB_Analistas WHERE Tipo_Linea = 'L1')
			SELECT @TotalAutorizaciones = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Autorizacion' AND TIPO_LINEA = 'L1'
				SELECT @TotalErrores = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Errores de procesamiento' AND TIPO_LINEA = 'L1'
					SELECT @TotalFraude = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Fraude' AND TIPO_LINEA = 'L1'
						SELECT @TotalServicios = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Servicios/MercaderÃ­a - Disputas del consumidor' AND TIPO_LINEA = 'L1'
		
		-- Calcular el número de registros para asignar a cada analista L1
		SET @AsignacionAutorizaciones = @TotalAutorizaciones / @NumAnalistas
		SET @AsignacionErrores = (@TotalErrores + (@TotalAutorizaciones % @NumAnalistas)) / @NumAnalistas
		SET @AsignacionFraude = (@TotalFraude + (@TotalErrores % @NumAnalistas)) / @NumAnalistas
		SET @AsignacionServicios = (@TotalServicios + (@TotalFraude % @NumAnalistas)) / @NumAnalistas;


		-- Obtener el número total de registros por categoría L3
		SELECT @NumAnalistas_L3 = (SELECT SUM(Flag_Activo)FROM TB_Analistas WHERE Tipo_Linea = 'L3')
			SELECT @TotalAutorizaciones_L3 = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Autorizacion' AND TIPO_LINEA = 'L3'
				SELECT @TotalErrores_L3 = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Errores de procesamiento' AND TIPO_LINEA = 'L3'
					SELECT @TotalFraude_L3 = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Fraude' AND TIPO_LINEA = 'L3'
						SELECT @TotalServicios_L3 = COUNT(*) FROM [dbo].[Controversias_final] WHERE CategoriaCC = 'Servicios/MercaderÃ­a - Disputas del consumidor' AND TIPO_LINEA = 'L3'
		
		-- Calcular el número de registros para asignar a cada analista L3
		SET @AsignacionAutorizaciones_L3 = @TotalAutorizaciones_L3 / @NumAnalistas_L3
		SET @AsignacionErrores_L3 = (@TotalErrores_L3 + (@TotalAutorizaciones_L3 % @NumAnalistas_L3)) / @NumAnalistas_L3
		SET @AsignacionFraude_L3 = (@TotalFraude_L3 + (@TotalErrores_L3 % @NumAnalistas_L3)) / @NumAnalistas_L3
		SET @AsignacionServicios_L3 = (@TotalServicios_L3 + (@TotalFraude_L3 % @NumAnalistas_L3)) / @NumAnalistas_L3;


		
		WITH L1_RESUMEN
		AS(
		SELECT 
			 [ARD_ARN]
			,[NroControl_ROLCase]
			,[Orden]
			,[RUC]
			,[CategoriaCC]
			,
			CASE
				WHEN CategoriaCC = 'Autorizacion' THEN
				ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL)) % @NumAnalistas + 1
				WHEN CategoriaCC = 'Errores de procesamiento' THEN
				(ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL) ) + @TotalAutorizaciones) % @NumAnalistas + 1
				WHEN CategoriaCC = 'Fraude' THEN
				(ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL) ) + @TotalAutorizaciones + @TotalErrores) % @NumAnalistas + 1 
				WHEN CategoriaCC = 'Servicios/MercaderÃ­a - Disputas del consumidor' THEN
				(ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL) ) + @TotalAutorizaciones + @TotalErrores + @TotalFraude) % @NumAnalistas + 1
				END AS Asignacion
				,GETDATE() AS [Fecha_Evento]
				,TIPO_LINEA AS [Tipo de Linea]
					FROM [dbo].[Controversias_final] AS CS
						WHERE TIPO_LINEA = 'L1' 
						),				
			L3_RESUMEN AS (
					SELECT 
						[ARD_ARN]
						,[NroControl_ROLCase]
						,[Orden]
						,[RUC]
						,[CategoriaCC]
						,
						CASE
							WHEN CategoriaCC = 'Autorizacion' THEN
							ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL)) % @NumAnalistas_L3 + 1
							WHEN CategoriaCC = 'Errores de procesamiento' THEN
							(ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL) ) + @TotalAutorizaciones_L3) % @NumAnalistas_L3 + 1
							WHEN CategoriaCC = 'Fraude' THEN
							(ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL) ) + @TotalAutorizaciones_L3 + @TotalErrores_L3) % @NumAnalistas_L3 + 1 
							WHEN CategoriaCC = 'Servicios/MercaderÃ­a - Disputas del consumidor' THEN
							(ROW_NUMBER() OVER (PARTITION BY CategoriaCC ORDER BY (SELECT NULL) ) + @TotalAutorizaciones_L3 + @TotalErrores_L3 + @TotalFraude_L3) % @NumAnalistas_L3 + 1
							END AS Asignacion
							,GETDATE() AS [Fecha_Evento]
							,TIPO_LINEA AS [Tipo de Linea]
								FROM [dbo].[Controversias_final]
									WHERE TIPO_LINEA = 'L3' 
							)
							INSERT INTO RESULTADO_REPARTICION
							SELECT * 
							FROM (
							SELECT * 
								FROM L3_RESUMEN L3R
									LEFT JOIN TB_Analistas AS TBA3 ON L3R.Asignacion = TBA3.Id AND L3R.[Tipo de Linea] = TBA3.Tipo_Linea
							UNION ALL
							SELECT * 
								FROM L1_RESUMEN AS LA1
									LEFT JOIN TB_Analistas AS AN ON LA1.Asignacion = AN.Id AND LA1.[Tipo de Linea] = AN.Tipo_Linea)UNION_RESUMEN;
									END


									--EXEC [dbo].[sp_cl_reparticion]


/*

En este Store se procedió con la intersección de 2 tablas en relación a un ID propuesto de manera aleatoria mediante un objeto especifico donde el objeto residente
determinara la cantidad repartida para cada colaborar cuyo objetivo es proceder con un entorno productivo equitativo.

*/
