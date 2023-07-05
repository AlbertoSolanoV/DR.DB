CREATE OR REPLACE PROCEDURE TablesStructure(nombreTabla VARCHAR2, user VARCHAR2) IS

usuario VARCHAR2(20) := UPPER(user);
rows NUMBER(6);
table_nombre VARCHAR(20); 
cant_tablas NUMBER(10);
tabla VARCHAR2(15) := UPPER(nombreTabla); 
secuencias NUMBER(20);
sinonimos NUMBER(20); 
tableSpace VARCHAR(20); 
quota VARCHAR2(15);
vistas NUMBER(15);

CURSOR datos_cursor IS select tc.column_name, decode(tc.nullable,'Y','Not Null','N','   ') notnull,
              case substr(tc.data_type,1,1)
              when 'C' then 'CHAR('||tc.data_length||')'
              when 'V' then 'VARCHAR2('||tc.data_length||')'
              when 'N' then 'NUMBER('||tc.data_precision||')'
              when 'D' then 'DATE'
              else ' '
              end type,
              decode(cc.constraint_type,'P','PK','R','FK','  ') key,
              ruc.table_name ref
       from (select table_name,column_name,nullable,data_type,data_length,data_precision from all_tab_cols) tc
       left join (select constraint_name, ucc.table_name,constraint_type, column_name, r_constraint_name
              from all_cons_columns ucc
              join all_constraints usc using(constraint_name)
              where constraint_type in ('P','R')) cc
       on (tc.column_name=cc.column_name and tc.table_name=cc.table_name)
       left join all_constraints ruc on (ruc.constraint_name=cc.r_constraint_name)
       where tc.table_name = tabla; 

BEGIN
DBMS_OUTPUT.PUT_LINE('TABLA INGRESADA: ' ||TO_CHAR(tabla));
--quota 
select decode(max_bytes, -1, 'Unlimited') dato INTO quota 
from dba_ts_quotas
where tablespace_name = 'USERS';
--views
select count(view_name) INTO vistas
from all_views
where owner = usuario; 
--table_space
select distinct tablespace_name into tableSpace
 from all_indexes 
 where table_name = tabla and owner = usuario;
--sequences
select count(sequence_name) INTO secuencias
from all_sequences
where sequence_owner = usuario; 
--synonyms
select count(synonym_name) INTO sinonimos 
from all_synonyms
where owner = usuario;
--table 
SELECT table_name, count(rownum) INTO table_nombre,rows
FROM all_tab_cols
WHERE table_name = tabla AND owner = usuario
group by table_name;
--rows
select count(distinct table_name) into cant_tablas
FROM all_tab_cols
WHERE owner = usuario; 
--begin
DBMS_OUTPUT.PUT_LINE('USER:  ' || RPAD(TO_CHAR(usuario),15)  || 'TableSpace: ' || RPAD(TO_CHAR(tableSpace),15) || 'Quota: ' || TO_CHAR(quota));
DBMS_OUTPUT.PUT_LINE('TABLES:  ' || RPAD(TO_CHAR(cant_tablas),15) || 'Views: '|| RPAD(TO_CHAR(vistas),15) || 'Synonyms: '|| RPAD(TO_CHAR(secuencias),15) || 'Sequences: '|| TO_CHAR(secuencias));

DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
DBMS_OUTPUT.PUT_LINE('TABLE: '|| TO_CHAR(table_nombre) ||' '||'ROWS:  '||TO_CHAR(rows)); 
DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
DBMS_OUTPUT.PUT_LINE('COLUMN_NAME'||'            '||'NULL?'||'                '||'TYPE'||'            '||'KEY'||'            '||'REF');
DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
FOR emp_datos IN datos_cursor LOOP
DBMS_OUTPUT.PUT_LINE(RPAD(TO_CHAR(emp_datos.column_name),16)||'   '||LPAD(TO_CHAR(emp_datos.notnull),10)||' '||LPAD(TO_CHAR(emp_datos.type),20)||' '||LPAD(TO_CHAR(emp_datos.key),12)||' '||LPAD(TO_CHAR(emp_datos.ref),15));
END LOOP;
END TablesStructure;
/