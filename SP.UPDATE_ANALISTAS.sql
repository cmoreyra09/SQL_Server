USE BD_PERSONAL
GO

/*
-----------------------------------------

	CREATED BY : CARLOS MOREYRA NOEL
	FECHA : 30/03/2023

-----------------------------------------
*/


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROCEDURE [dbo].[sp_update_analistas] @Flag INT ,@Linea VARCHAR(2),@Tipo VARCHAR(13)
AS
	TRUNCATE TABLE TB_Analistas
	BEGIN
		
		SET NOCOUNT ON
		
		UPDATE IZIPAY.dbo.Analistas_IZIPAY
			SET Flag_Activo = @Flag , Tipo_Linea = @Linea
				WHERE Codigo = @Tipo

		INSERT INTO TB_Analistas
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY [Tipo_Linea] ORDER BY NEWID()) AS [Id]
			,[Nombres]
			,[Apellidos]
			,[Codigo]
			,[Cargos]
			,[Correo]
			,[Tipo_Linea]
			,[Flag_Activo]
				FROM [IZIPAY].[dbo].[Analistas_IZIPAY]
					WHERE Flag_Activo = 1
	END
	
GO

/*

En este Query se creó un store Procedure para poder automatizar el proceso de repartición de trabajo de un área específica, en el siguiente caso se está utilizando un caso de negocio ficticio.
Donde se tiene como principal objetivo poder realizar una repartición equitativa a cada trabajador. Por ello la creación de este store Procedure es importante para poder determinar la salida y - 
entrada de analista dependiendo de la duración de diferentes Líneas (Tipos de linea). Además, tambien se consideró un atributo activo (Flag_Activo), en este parametro tenemos la situación de 
colaboradores que tienen salida de vacaciones o cierta contingencia que suceda por eso se creo dicha tarea automatizada para poder deshabilitar y que el proyecto corra de manera adecuada.

*/