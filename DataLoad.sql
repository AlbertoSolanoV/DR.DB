CREATE OR REPLACE PROCEDURE DataLoad IS


 --sql_statement VARCHAR2(800000);
columna VARCHAR2(8000);
  tipo VARCHAR2(8000);
  nulo VARCHAR2(8000);  

 CURSOR tabla IS select distinct table_name from all_tab_cols where owner = 'ASOLANO';

cursor_tablas SYS_REFCURSOR; 
cursor_columnas SYS_REFCURSOR;
cursor_inserts SYS_REFCURSOR;
l_columna VARCHAR2(8000);
l_tipo VARCHAR2(8000);
l_dato VARCHAR2(8000);
vdato VARCHAR2(8000);
prueba VARCHAR2(8000);

sql_statement VARCHAR2(8000);
vtable VARCHAR2(8000);
 
BEGIN

	FOR dato_tabla IN tabla LOOP
	DBMS_OUTPUT.PUT_LINE('CREATE TABLE  ' || dato_tabla.table_name ||' (');

		OPEN cursor_tablas FOR select tc.column_name,case substr(tc.data_type,1,1)
			 when 'C' then 'char('||tc.data_length||')'
			 when 'V' then 'varchar2('||tc.data_length||')'
			 when 'N' then 'number('||tc.data_precision||')'
			 when 'D' then 'date'
			 else ' '
		   end type, decode(tc.nullable,'Y','Not Null') notnull 
			from (select table_name,column_name,nullable,data_type,data_length,data_precision,OWNER from all_tab_cols) tc
			where tc.owner = 'ASOLANO' AND table_name = dato_tabla.table_name ; LOOP 

			FETCH cursor_tablas INTO columna, tipo, nulo; 
			EXIT WHEN cursor_tablas%NOTFOUND; 

				DBMS_OUTPUT.PUT_LINE(RPAD(to_char(columna),13)||'  '|| to_char(tipo)||'   '||to_char(nulo)||','); 

		END LOOP; 
		CLOSE cursor_tablas; 
		DBMS_OUTPUT.PUT_LINE(');');
		DBMS_OUTPUT.PUT_LINE('/');
	END LOOP; 


	--INSERT INTO

	FOR dato_tabla IN tabla LOOP
		vtable := 'SELECT chr(39) || ';
		
		OPEN cursor_columnas FOR select tc.column_name, tc.data_type from (select table_name,column_name, data_type, OWNER from all_tab_cols) tc
			where tc.owner = 'ASOLANO' AND table_name = dato_tabla.table_name ; 
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

		vtable := LPAD(vtable, LENGTH(vtable) - 25) || ' FROM ASOLANO.'||dato_tabla.table_name;
		sql_statement := vtable;
		
		OPEN cursor_inserts FOR sql_statement;
		LOOP
			FETCH cursor_inserts into l_dato;
			EXIT WHEN cursor_inserts%NOTFOUND;
				prueba := chr(39) || '<'||chr(39);			
				DBMS_OUTPUT.PUT_LINE('INSERT INTO ' || dato_tabla.table_name ||' VALUES (' ||  REPLACE(l_dato, prueba, 'NULL') || ');');
		END LOOP;
		CLOSE cursor_inserts;
		
	END LOOP; 
END DataLoad; 
/