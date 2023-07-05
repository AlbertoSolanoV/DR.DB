CREATE OR REPLACE PROCEDURE DataDictionary(user in VARCHAR2) IS

rows NUMBER(10); 
vtable VARCHAR2(100);
menor_valor VARCHAR2(100);
mayor_valor VARCHAR2(100);
valor VARCHAR2(200);
usuario VARCHAR2(50) := UPPER(user);
cursor_values SYS_REFCURSOR;
sql_statement VARCHAR2(8888);
CURSOR datos is select distinct  tc.column_name, case substr(tc.data_type,1,1)
         when 'C' then 'CHAR('||tc.data_length||')'
         when 'V' then 'VARCHAR2('||tc.data_length||')'
         when 'N' then 'NUMBER('||tc.data_precision||')'
         when 'D' then 'DATE'
         else ' '
       end type, tc.table_name, tc.owner
		from (select table_name,column_name,nullable,data_type,data_length,data_precision, owner from all_tab_cols) tc
		where tc.owner = usuario;

BEGIN
	

	


	DBMS_OUTPUT.PUT_LINE('COLUMNA                 TIPO DATO                     TABLA                                        VALOR'); 
	DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------------------------------------------');
	FOR datos_tabla IN datos
	LOOP
		vtable := usuario||'.'||datos_tabla.table_name;
		sql_statement := 'select MIN('|| datos_tabla.column_name ||'), MAX('|| datos_tabla.column_name ||') FROM '|| vtable ||' ORDER BY '|| datos_tabla.column_name||' ASC';
	
		OPEN cursor_values FOR sql_statement;
			LOOP
				FETCH cursor_values INTO menor_valor, mayor_valor;
				EXIT WHEN cursor_values%NOTFOUND;
				
				valor := to_char(menor_valor) || '..' || to_char(mayor_valor);
				
				DBMS_OUTPUT.PUT_LINE(RPAD(to_char(datos_tabla.column_name),16) ||'   '|| LPAD(to_char(datos_tabla.type),14) ||'    '||LPAD(to_char(datos_tabla.table_name),15) ||'  '||LPAD(valor,60)); 
				
		END LOOP;
	
		
	END LOOP; 
END DataDictionary; 
/