CREATE OR REPLACE PROCEDURE data_search(duenno in varchar2, tipo_dato in varchar2, valor in varchar2) 
as
	p_owner varchar2(300) := UPPER(duenno);
	p_type VARCHAR2(300) := UPPER(tipo_dato);
	p_value varchar2(300):= upper(valor);
	
	--cursores
	CURSOR cursor_tables IS select table_name, column_name,data_type,owner from all_tab_cols where owner = p_owner and data_type = p_type;
	cursor_cols SYS_REFCURSOR;
	cursor_data SYS_REFCURSOR;
	l_sql_2    VARCHAR2(32767);
	l_columna2  VARCHAR2(32767);

	--variables temporales
	l_sql     VARCHAR2(32767);
	l_columna  VARCHAR2(32767);
	l_rownum  NUMBER(38);
	l_table  VARCHAR2(32767);
	vtable varchar2(32767);
	vcol varchar2(32767);
	vowner varchar2(32767);
	
	--excepciones
	data_type_excep EXCEPTION;

BEGIN
	p_type := UPPER(p_type);
	p_owner := UPPER(p_owner);
	p_value := UPPER(p_value);
	IF p_type IN ('V', 'C', 'CHAR', 'VARCHAR2', 'VARCHAR','N', 'NUMBER', 'D', 'DATE') THEN
		
		p_type := 
			CASE p_type
				WHEN 'V' THEN 'VARCHAR2'
				WHEN 'VARCHAR' THEN 'VARCHAR2'
				WHEN 'C' THEN 'CHAR'
				WHEN 'D' THEN'DATE'
				WHEN 'N'  THEN 'NUMBER'
				WHEN 'VARCHAR2' THEN 'VARCHAR2'
				WHEN 'DATE' THEN 'DATE'
				WHEN 'NUMBER' THEN 'NUMBER'
				WHEN 'CHAR' THEN'CHAR'
			END;
			
		DBMS_OUTPUT.PUT_LINE(chr(13));
		DBMS_OUTPUT.PUT_LINE(chr(13));
		DBMS_OUTPUT.put_line('Result:');
		
		DBMS_OUTPUT.PUT_LINE('   '||RPAD('Table',16)||'   '||LPAD('Column',10)||'       '||LPAD('Rownum',12));
		DBMS_OUTPUT.put_line('   ---------------------- ----------------- ---------------');
		
		
		FOR record_tables IN cursor_tables LOOP
		
			l_table := record_tables.table_name;
			vtable := record_tables.owner || '.' ||record_tables.table_name;
			vcol := record_tables.column_name;
			vowner := record_tables.owner;		

			l_sql := 'SELECT '|| vcol ||', ROWNUM FROM ' ||vtable ;						
			
			OPEN cursor_cols FOR l_sql;
				LOOP
				FETCH cursor_cols INTO  l_columna, l_rownum;
				EXIT WHEN cursor_cols%NOTFOUND;
				 IF p_type IN ('D', 'DATE') then 
					if to_date(p_value, 'DD/MM/YY') = l_columna THEN
											
						DBMS_OUTPUT.PUT_LINE('  '||RPAD(SUBSTR(vtable, (INSTR(vtable,'.',1,1)+1)),20)||'    '||RPAD(vcol,15)||'    '||to_char(l_rownum));
						
					END IF;	 
				 ELSE
					IF p_value = to_char(UPPER(l_columna)) THEN
						DBMS_OUTPUT.PUT_LINE('   '||RPAD(SUBSTR(vtable, (INSTR(vtable,'.',1,1)+1)),20)||'   '||RPAD(vcol,15)||'     '||to_char(l_rownum));
				
					END IF;	
				END IF;
					
		  END LOOP;
		  CLOSE cursor_cols;	  
		END LOOP;	 		
	ELSE 
		RAISE data_type_excep;
	END IF;

EXCEPTION
	WHEN data_type_excep THEN
		DBMS_OUTPUT.PUT_LINE('Tipo de dato inválido');
	WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('No se encontraron  datos');
END data_search;
/