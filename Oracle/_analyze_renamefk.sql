declare 
    procedure rename_fk(p_parent varchar2, p_relative varchar2, p_column varchar2, p_new_name varchar2, p_type varchar2) is 
    begin
        for rec in (select u.constraint_name from user_constraints u
                   left join user_constraints r on U.R_CONSTRAINT_NAME = R.CONSTRAINT_NAME
                   left join USER_CONS_COLUMNS cc on CC.CONSTRAINT_NAME = U.CONSTRAINT_NAME
                     where U.TABLE_NAME = p_parent
                       and u.constraint_Type = p_type
                       and nvl(R.TABLE_NAME,'-') = p_relative
                        and ( p_column is null or p_column = cc.column_name)
                    )
        loop
          dbms_output.put_line('alter table '||p_parent||' rename constraint '||rec.constraint_name||' to '||p_new_name);
          -- execute immediate 'alter table '||p_parent||' drop constraint '||rec.constraint_name;
        end loop;    
    end;
    
    procedure renamefk(p_parent varchar2, p_relative varchar2, p_column varchar2, p_new_name varchar2) is 
    begin
        rename_fk(p_parent, p_relative, p_column, p_new_name, 'R');
    end;
begin

renamefk('PREF_CONTACT','PREF_ADDRESS','LEGALADDRESS','PREF_CONTACT_LEGALADDRESS'); -- SYS_C00..._
--------------
renamefk('PREF_CONTACT','PREF_ADDRESS','POSTALADDRESS','PREF_CONTACT_POSTALADDRESS'); -- SYS_C00..._
--------------
renamefk('PREF_PHONE','PREF_CONTACT','','PREF_PHONE_CONTACT'); -- SYS_C00..._
--------------
renamefk('PREF_FAX','PREF_CONTACT','','PREF_FAX_CONTACT'); -- SYS_C00..._
--------------
renamefk('PREF_TAXESPAIDCONFIRM','-','','PREF_TAXESPAIDCONFIRM_PK'); -- SYS_C00..._
--------------
renamefk('PREF_FOUNDER','PREF_PERSON','','PREF_FOUNDER_CHIEF'); -- SYS_C00..._
--------------
renamefk('PREF_NOTE','PREF_INSURANCE','','PREF_NOTE_INSURANCE'); -- SYS_C00..._
--------------
renamefk('PREF_NOTE','PREF_PERMIT','','PREF_NOTE_PERMIT'); -- SYS_C00..._
--------------
renamefk('PREF_STATUS','PREF1_USER','','PREF_STATUS_PREF1_USER_FK1'); -- SYS_C00..._
--------------
renamefk('PREF_STOREHOUSE','PREF_OWNERTYPE','','PREF_STOREHOUSE_OWNERTYPE'); -- SYS_C00..._
--------------
renamefk('PREF_INSURANCECONFIRM','PREF_INSURANCE','','PREF_INSCONF_INSURANCE'); -- SYS_C00..._

end;
/