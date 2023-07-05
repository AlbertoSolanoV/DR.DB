CREATE OR REPLACE PROCEDURE DML(duenno IN VARCHAR2) IS
  v_owner VARCHAR2(100) := UPPER(duenno);
  archivo_insert  utl_file.file_type;
 CURSOR tabla IS select OBJECT_NAME from ALL_OBJECTS where OWNER = v_owner AND OBJECT_TYPE = 'TABLE' ORDER BY OBJECT_ID;
cursor_columnas SYS_REFCURSOR;
cursor_inserts SYS_REFCURSOR;
l_columna VARCHAR2(8000);
l_tipo VARCHAR2(8000);
l_dato VARCHAR2(8000);
vdato VARCHAR2(8000);
sql_statement VARCHAR2(8000);
vtable VARCHAR2(8000);
 valor_maxC number := 0;
 valor_menorC number := 0;
 valor_maxK number := 0;
 valor_menorK number := 0;
 archivo_extension VARCHAR(100);
BEGIN
	--initialize archivos
	archivo_extension := v_owner || '.dml';
	archivo_insert := utl_file.fopen('DATA_PUMP_DIR', archivo_extension, 'w');
		
	--INSERT INTO
	
	FOR dato_tabla IN tabla LOOP
		vtable := 'SELECT chr(39) || ';
		UTL_FILE.PUT_LINE(archivo_insert, to_char('---' || dato_tabla.OBJECT_NAME|| '---'));
		OPEN cursor_columnas FOR select tc.column_name, tc.data_type from (select table_name,column_name, data_type, OWNER from all_tab_cols) tc
			where tc.owner = v_owner AND table_name = dato_tabla.OBJECT_NAME ; 
			LOOP
			FETCH cursor_columnas INTO l_columna, l_tipo; 
			EXIT WHEN cursor_columnas%NOTFOUND; 
		
				if l_tipo = 'NUMBER' THEN
					vtable := LPAD(vtable, LENGTH(vtable) - 12) || ' ' || 'CASE WHEN '|| l_columna||' IS NULL THEN 0 ELSE '||l_columna||' END '|| '|| chr(44) || chr(39) || ';
				ELSE 
					vtable := vtable || ' ' || ' CASE WHEN to_char('|| l_columna||') IS NULL THEN Chr(60) ELSE to_char('||l_columna||') END '|| ' || chr(39) || chr(44) || chr(39) || ';
				END IF;

		END LOOP; 
		CLOSE cursor_columnas; 

		vtable := LPAD(vtable, LENGTH(vtable) - 25) || ' FROM ' || v_owner ||'.'||dato_tabla.OBJECT_NAME;
		sql_statement := vtable;
		
		OPEN cursor_inserts FOR sql_statement;
		LOOP
			FETCH cursor_inserts into l_dato;
			EXIT WHEN cursor_inserts%NOTFOUND;
				vdato := chr(39) || '<'||chr(39);						
				UTL_FILE.PUT_LINE(archivo_insert, to_char('INSERT INTO ' || dato_tabla.OBJECT_NAME ||' VALUES (' ||  REPLACE(l_dato, vdato, 'NULL') || ');'));
				
		END LOOP;
		CLOSE cursor_inserts;
	END LOOP; 
	UTL_FILE.FCLOSE(archivo_insert);
	DBMS_OUTPUT.PUT_LINE('');
	DBMS_OUTPUT.PUT_LINE('El archivo ' || archivo_extension || ' se encuentra en el siguiente directorio:');
	DBMS_OUTPUT.PUT_LINE('C:\oraclexe\app\oracle\admin\XE\dpdump');
END DML; 
/
