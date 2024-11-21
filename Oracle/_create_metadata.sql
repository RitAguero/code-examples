set serveroutput on size 100000
set feedback off

declare
  procedure ExportTable (v_table_name in varchar2) is 
      v_column_list     varchar2(2000);
      v_insert_list     varchar2(2000);
      v_ref_cur_columns varchar2(4000);
      v_ref_cur_query   varchar2(2000);
      v_ref_cur_output  varchar2(2000);
      v_column_name     varchar2(2000);
      cursor c1 is select column_name, data_type 
                     from user_tab_columns 
                    where table_name = v_table_name 
                 order by column_id;
      refcur            sys_refcursor; 
  begin
      for i in c1 loop
         v_column_list := v_column_list||','||i.column_name;
         if i.data_type = 'NUMBER' then
            v_column_name := i.column_name;
         elsif i.data_type = 'DATE' then
            v_column_name := 
                chr(39)||'to_date('||chr(39)||'||chr(39)'||'||to_char('||i.column_name||','||chr(39)||'dd/mm/yyyy 
                hh:mi:ss'||chr(39)||')||chr(39)||'||chr(39)||', '||chr(39)||'||chr(39)||'||chr(39)||'dd/mm/rrrr 
                hh:mi:ss'||chr(39)||'||chr(39)||'||chr(39)||')'||chr(39);
         elsif i.data_type in ('VARCHAR2','CHAR','NVARCHAR2') then
            v_column_name := 'chr(39)||'||i.column_name||'||chr(39)';
         end if;
         v_ref_cur_columns := v_ref_cur_columns||'||'||chr(39)||','||chr(39)||'||'||v_column_name;
      end loop; 

      v_column_list     := ltrim(v_column_list,',');
      v_ref_cur_columns := substr(v_ref_cur_columns,8);

      v_insert_list     := 'INSERT INTO '||v_table_name||' ('||v_column_list||') VALUES ';
      v_ref_cur_query   := 'SELECT '||v_ref_cur_columns||' FROM '||v_table_name;
      
      open refcur for v_ref_cur_query;
      loop
      fetch refcur into v_ref_cur_output; 
      exit when refcur%notfound;
        v_ref_cur_output := '('||v_ref_cur_output||');'; 
        v_ref_cur_output := replace(v_ref_cur_output,',,',',null,');
        v_ref_cur_output := replace(v_ref_cur_output,'(,','(null,');
        v_ref_cur_output := replace(v_ref_cur_output,',,)',',null)');
        v_ref_cur_output := replace(v_ref_cur_output,'null,)','null,null)');
        v_ref_cur_output := v_insert_list||v_ref_cur_output; 
        dbms_output.put_line (v_ref_cur_output); 
      end loop; 
    end;
 begin
    ExportTable('DECISIONREASON');
 end;
/