CREATE OR REPLACE PROCEDURE DDL(duenno IN VARCHAR2) IS
  v_owner VARCHAR2(100) := UPPER(duenno);
  archivo_create  utl_file.file_type;
  
  columna VARCHAR2(8000);
  tipo VARCHAR2(8000);
  nulo VARCHAR2(8000);  

 CURSOR tabla IS select OBJECT_NAME from ALL_OBJECTS where OWNER = v_owner AND OBJECT_TYPE = 'TABLE' ORDER BY OBJECT_ID;

cursor_tablas SYS_REFCURSOR; 
cursor_keys SYS_REFCURSOR;

l_nombre_key VARCHAR2(8000);
l_constraint_name VARCHAR2(8000);
l_type_key VARCHAR2(8000);
l_reference_key VARCHAR2(8000);

 valor_maxC number := 0;
 valor_menorC number := 0;
 valor_maxK number := 0;
 valor_menorK number := 0;
 archivo_extension VARCHAR(100);
BEGIN
	--initialize archivos
	archivo_extension := v_owner || '.ddl';
	archivo_create := utl_file.fopen('DATA_PUMP_DIR', archivo_extension, 'w');
		
--CREATE TABLE
	
	FOR dato_tabla IN tabla LOOP
	UTL_FILE.PUT_LINE(archivo_create, to_char('CREATE TABLE  ' || dato_tabla.OBJECT_NAME ||' ('));		
			
		select count(rownum) into valor_maxC  from all_tab_cols where owner = v_owner AND table_name = dato_tabla.OBJECT_NAME ;
		
		OPEN cursor_tablas FOR select tc.column_name,case substr(tc.data_type,1,1)
			 when 'C' then 'char('||tc.data_length||')'
			 when 'V' then 'varchar2('||tc.data_length||')'
			 when 'N' then 'number('||tc.data_precision||')'
			 when 'D' then 'date'
			 else ' '
		   end type, decode(tc.nullable,'Y','Not Null') notnull 
			from (select table_name,column_name,nullable,data_type,data_length,data_precision,OWNER from all_tab_cols) tc
			where tc.owner = v_owner AND table_name = dato_tabla.OBJECT_NAME ; 
			LOOP 
			FETCH cursor_tablas INTO columna, tipo, nulo; 
			EXIT WHEN cursor_tablas%NOTFOUND; 
			
				valor_menorC := cursor_tablas%ROWCOUNT;
				
				IF valor_menorC < valor_maxC THEN
				
					UTL_FILE.PUT_LINE(archivo_create, to_char(RPAD(to_char(columna),13)||'  '|| to_char(tipo)||'   '||to_char(nulo)||','));
				ELSE 
					
					UTL_FILE.PUT_LINE(archivo_create, to_char(RPAD(to_char(columna),13)||'  '|| to_char(tipo)||'   '||to_char(nulo) ));
				END IF;
		END LOOP; 
		
		CLOSE cursor_tablas; 
		
		
		select count(rownum) registro into valor_maxK from (select table_name,column_name,nullable,data_type,data_length,data_precision from all_tab_cols) tc
				left join (select constraint_name, ucc.table_name,constraint_type, column_name, r_constraint_name
				from all_cons_columns ucc
				join all_constraints usc using(constraint_name)
				where constraint_type in ('P','R')) cc
				on (tc.column_name=cc.column_name and tc.table_name=cc.table_name)
				left join all_constraints ruc on (ruc.constraint_name=cc.r_constraint_name)
				where tc.table_name = dato_tabla.OBJECT_NAME and  cc.constraint_type is not null
				order by cc.constraint_type asc;
			
		IF valor_maxK > 0 THEN 
			UTL_FILE.PUT(archivo_create, ',');
		END IF;
		
		OPEN cursor_keys FOR select cc.constraint_name,tc.column_name, decode(cc.constraint_type,'P','Primary Key','R','Foreign Key','  ') key, ruc.table_name ref
			from (select table_name,column_name,nullable,data_type,data_length,data_precision from all_tab_cols) tc
			left join (select constraint_name, ucc.table_name,constraint_type, column_name, r_constraint_name
			from all_cons_columns ucc
			join all_constraints usc using(constraint_name)
			where constraint_type in ('P','R')) cc
			on (tc.column_name=cc.column_name and tc.table_name=cc.table_name)
			left join all_constraints ruc on (ruc.constraint_name=cc.r_constraint_name)
			where tc.table_name = dato_tabla.OBJECT_NAME and  cc.constraint_type is not null
			order by cc.constraint_type asc;
			LOOP 
			FETCH cursor_keys INTO l_constraint_name, l_nombre_key, l_type_key, l_reference_key; 
			EXIT WHEN cursor_keys%NOTFOUND; 
	
			valor_menorK := cursor_keys%ROWCOUNT;
		
			IF valor_menorK < valor_maxK THEN
				
				IF l_type_key = 'Primary Key' THEN 
					UTL_FILE.PUT_LINE(archivo_create, to_char('CONSTRAINT '||to_char(l_constraint_name)||'   '|| to_char(l_type_key)||' ('||to_char(l_nombre_key)||'),'));
				ELSE 
					UTL_FILE.PUT_LINE(archivo_create, to_char('CONSTRAINT '||to_char(l_constraint_name)||'  '|| to_char(l_type_key)||'   ('||to_char(l_nombre_key)||') REFERENCES '||l_reference_key||','));
				END IF;
				
			ELSE 
				IF l_type_key = 'Primary Key' THEN 
					UTL_FILE.PUT_LINE(archivo_create, to_char('CONSTRAINT '||to_char(l_constraint_name)||'   '|| to_char(l_type_key)||' ('||to_char(l_nombre_key)||')'));
				ELSE 
					UTL_FILE.PUT_LINE(archivo_create, to_char('CONSTRAINT '||to_char(l_constraint_name)||'  '|| to_char(l_type_key)||'   ('||to_char(l_nombre_key)||') REFERENCES '||l_reference_key));
				END IF;
			END IF;
		END LOOP;
		CLOSE cursor_keys;
		UTL_FILE.PUT_LINE(archivo_create,');');
		UTL_FILE.PUT_LINE(archivo_create,'/');
		
		
	END LOOP; 
	UTL_FILE.FCLOSE(archivo_create);
	DBMS_OUTPUT.PUT_LINE('El archivo ' || archivo_extension || ' se encuentra en el siguiente directorio:');
	DBMS_OUTPUT.PUT_LINE('C:\oraclexe\app\oracle\admin\XE\dpdump');
END DDL; 
/
