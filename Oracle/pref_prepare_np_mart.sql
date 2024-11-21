create or replace procedure pref_prepare_np_mart
is
    last_update_date date;
    v_isdone number;
    v_count number;
    v_addresscount number;
    v_rel_emprcount number;
    v_doccount number;

    v_topmark number;
    v_lowmark number;

    v_session number;

    procedure SaveSetParamDate(pName varchar2, pValue date) is
    begin
         update pref_parameters
            set paramvalue = to_char(pValue,'DD.MM.YYYY HH24:MI:SS')
          where paramname = pName;

         if (sql%notfound) then
             insert into pref_parameters(paramname, paramvalue)
             values (pName, to_char(pValue,'DD.MM.YYYY HH24:MI:SS'));
         end if;
    end;

    function SaveGetParamDate(pName varchar2) return date is
          v_Result varchar2(1500);
    begin
         select paramvalue into v_Result
           from pref_parameters
          where paramname = pName;

         return to_date(v_Result,'DD.MM.YYYY HH24:MI:SS');
    exception
        when others
            then
                return null;
    end;

begin
     pref_common.log_event('W', 'Step=CreateSpecMart: Начато выполнение процедуры.'
                , -1 , 'Заполнение витрин с данными',-1);

     debuglog_add(1,'prepare specmart: started');

--------------------------------------------------
---------- Info1 --------------------------------
--------------------------------------------------
     last_update_date := SaveGetParamDate('LastPrepareInfo1');

     if (last_update_date is null) then
          last_update_date := to_date('01.01.1990','DD.MM.YYYY');
     end if;

     delete from pref_info1_mart
      where person_id in (select person_id from hist_info1
      	                   where loaddate > last_update_date
      	                 );
debuglog_add(1,'prepare specmart: info1 deleted before update');
     commit;

     insert into pref_info1_mart(id, report_date, person_id, index1, index2, index3, update_date, address_id)
     select h.id, h.rep_date, h.person_id, p.index1, p.index2, p.reg_num, h.loaddate, h.address_id
       from hist_info1 h
 inner join pref_person p on p.id = h.person_id
      where h.loaddate > last_update_date
        and h.loadid = (select max(h1.loadid) from hist_info1 h1
                         where h1.person_id = h.person_id
        	           );
debuglog_add(1,'prepare specmart: info1 first inserted');
     commit;

     v_isdone := 0;
     v_count := 0;
 
     while (v_isdone = 0) loop
         begin 
            select t.id into v_topmark
              from ( select h.id, row_number() over (order by h.id) rn
                       from pref_info1_mart h
                      where h.person_name is null
                        and h.update_date > last_update_date
              	   ) t
             where t.rn = 60000;
             debuglog_add(1,'step 1');

            select min(h.id) into v_lowmark
              from pref_info1_mart h
              where h.person_name is null
                and h.update_date > last_update_date;
             debuglog_add(1,'step 2');

		     update pref_info1_mart
		     	set person_name = (select o.name from pref_object o where o.id = pref_info1_mart.person_id)
		      where person_name is null
		        and update_date > last_update_date
		        and id between v_lowmark and v_topmark;

               v_count := v_count + sql%rowcount;
               debuglog_add(1,'prepare specmart: info1 person_name inserted '||v_count||' records ');

       	     commit;
       	 exception
       	     when others
       	         then
       	             v_isdone := 1;
       	 end;

     end loop;

     update pref_info1_mart
     	set person_name = (select o.name from pref_object o where o.id = pref_info1_mart.person_id)
      where person_name is null
        and update_date > last_update_date;

       v_count := v_count + sql%rowcount;
       debuglog_add(1,'prepare specmart: info1 person_name inserted '||v_count||' records ');

     commit;

     v_isdone := 0;
     v_count := 0;
 
     while (v_isdone = 0) loop
         begin 
            select t.id into v_topmark
              from ( select h.id, row_number() over (order by h.id) rn
                       from pref_info1_mart h
                      where h.address is null
                        and h.address_id is not null
                        and h.update_date > last_update_date
              	   ) t
             where t.rn = 60000;

            select min(h.id) into v_lowmark
              from pref_info1_mart h
              where h.address is null
                and h.address_id is not null
                and h.update_date > last_update_date;

		     update pref_info1_mart
		     	set address = (select o.name from pref_object o
		     		                        where o.id = pref_info1_mart.address_id
		     		          )
		      where address is null
		        and address_id is not null
		        and update_date > last_update_date
		        and id between v_lowmark and v_topmark;

               v_count := v_count + sql%rowcount;
               debuglog_add(1,'prepare specmart: info1 address inserted '||v_count||' records ');

	           commit;
       	 exception
       	     when others
       	         then
       	             v_isdone := 1;
       	 end;
     end loop;

     update pref_info1_mart
     	set address = (select o.name from pref_object o
     		                        where o.id = pref_info1_mart.address_id
     		          )
      where address is null
        and address_id is not null
        and update_date > last_update_date;

       v_count := v_count + sql%rowcount;
     debuglog_add(1,'prepare specmart: info1 address inserted '||v_count||' records ');

     select max(update_date) into last_update_date
       from pref_info1_mart;

     SaveSetParamDate('LastPrepareInfo1', last_update_date);

     commit;


--------------------------------------------------
---------- Banks ---------------------------------
--------------------------------------------------

     last_update_date := SaveGetParamDate('LastPrepareBankInfo');

     if (last_update_date is null) then
          last_update_date := to_date('01.01.1990','DD.MM.YYYY');
     end if;

     delete from pref_bank_mart
      where exists (select 1 from pref_bank_info f
                     where f.id = pref_bank_mart.id
                       and f.updatedate > last_update_date
      	           );
 
     commit;
     debuglog_add(1,'prepare specmart: bank_info previous deleted');
 
     insert into pref_bank_mart (id, bindex, name, index1, index2, address, update_date)
     select b.id, b.bindex, b.name, b.index1, b.index2, b.address, b.batchdate
       from pref_bank_info b
      where b.updatedate > last_update_date;

     commit;
     debuglog_add(1,'prepare specmart: bank_info new records inserted');

     -- similar code for pref_bank_np_mart and pref_account_mart skipped
   

     select max(t.update_date) into last_update_date
       from ( select update_date from pref_bank_mart
               union
              select update_date from pref_bank_np_mart
               union
              select update_date from pref_account_mart  
       	    ) t;

     SaveSetParamDate('LastPrepareBankInfo', last_update_date);

     commit;

--------------------------------------------------
---------- REGISTRY ---------------------------------
--------------------------------------------------

     last_update_date := SaveGetParamDate('LastPrepareRegistryEX');

     if (last_update_date is null) then
          last_update_date := to_date('01.01.1990','DD.MM.YYYY');
     end if;

     select pref_object_key_sq.nextval into v_session from dual;

     insert into temp_registry_mart (id, empr_id, session_id, person_id, update_date, state)
     select pref_object_key_sq.nextval, h.id, v_session, h.person_id
          , nvl(hh.publication_date, s.dt_end) update_date, 0
       from pref_registry_empr h
  left join hist_registry_ex_info hh on hh.empr_id = h.id
  left join pref_session s on s.id = h.session_id
  left join pref_bank_np_mart b on b.person_id = h.person_id
  left join pref_info1_mart o on o.person_id = h.person_id
      where ( o.id is not null or b.id is not null )
        and nvl(hh.publication_date, s.dt_end)  > last_update_date;

     debuglog_add(1,'prepare specmart: registry preselect');

     -- temp_registry_mart is further used to create 3 production marts
     -- the code to create each of them is similar, so code for only one of the 3 is shown

     v_isdone := 0;
     v_count := 0;
     v_addresscount := 0;
     v_rel_emprcount := 0;
     v_topmark := 0;
 
     while (v_isdone = 0) loop
         begin 
            select min(h.id) into v_lowmark
              from temp_registry_mart h
              where h.state = 0
                and h.session_id = v_session;

            select t.id into v_topmark
              from ( select h.id, row_number() over (order by h.id) rn
                       from temp_registry_mart h
                      where h.state = 0
                        and h.session_id = v_session
              	   ) t
             where t.rn = 30000;

            -- similar code for 2 other marts removed

            delete from pref_registry_mart
             where person_id in (select m.person_id from temp_registry_mart m
                                  where m.id between v_lowmark and v_topmark
                                    and m.session_id = v_session
                                    and m.state = 0
                                );
            commit;
 

            insert into pref_registry_mart (id, person_id, name, update_date, index1, index2, index3
                , reg_date, status_code, status_name, unreg_date, unreg_start_date
                , end_code, dtactual) 
            select m.id, m.person_id, n.fullname, m.update_date, i.index1, i.index2, f.index3
                , f.startdate, f.status_code, f.status_name, i.unreg_date, i.unreg_start_date
                , f.end_code, f.dtactual
              from temp_registry_mart m
        inner join pref_registry_empr f on f.id = m.empr_id
        inner join pref_registry_empr_index i on i.empr_id = f.id
        inner join pref_registry_empr_name n on n.empr_id = f.id
             where m.session_id = v_session
               and m.id between v_lowmark and v_topmark
               and m.state = 0;

               v_count := v_count + sql%rowcount;
               debuglog_add(1,'prepare specmart: registry inserted '||v_count||' records ');
            commit;

            -- similar code for 2 other marts removed, etc., below...         

            update temp_registry_mart
               set state = 1
             where session_id = v_session
               and id between v_lowmark and v_topmark;              

	        commit;
       	 exception
       	     when others
       	         then
       	             v_isdone := 1;
       	 end;
     end loop;


    delete from pref_registry_mart
     where person_id in (select m.person_id from temp_registry_mart m
                          where m.session_id = v_session
                            and m.state = 0
     	                );

    commit;


    insert into pref_registry_mart (id, person_id, name, update_date, index1, index2, index3
        , reg_date, status_code, status_name, unreg_date, unreg_start_date
        , end_code, dtactual) 
    select m.id, m.person_id, n.fullname, m.update_date, i.index1, i.index2, f.index3
        , f.startdate, f.status_code, f.status_name, i.unreg_date, i.unreg_start_date
        , f.end_code, f.dtactual
      from temp_registry_mart m
inner join pref_registry_empr f on f.id = m.empr_id
inner join pref_registry_empr_index i on i.empr_id = f.id
inner join pref_registry_empr_name n on n.empr_id = f.id
     where m.session_id = v_session
       and m.state = 0;

       v_count := v_count + sql%rowcount;
       debuglog_add(1,'prepare specmart: registry inserted '||v_count||' records ');

       commit;

        update temp_registry_mart
           set state = 1
         where session_id = v_session;

     select max(update_date) into last_update_date
       from pref_registry_mart;

     SaveSetParamDate('LastPrepareRegistryEX', last_update_date);
       
     pref_common.log_event('W', 'Step=CreateSpecMart: Процедура завершилась успешно.'
                , -1 , 'Заполнение витрин с данными',-1);

     debuglog_add(1,'prepare specmart: finished');

       commit;

exception
    when others
        then
            pref_common.log_event('E'
   , 'Step=CreateSpecMart, general error: '||sqlerrm||' '||dbms_utility.format_error_backtrace,-1
   , 'Заполнение витрин с данными');

            debuglog_add(1,'prepare specmart: exception '||sqlerrm||' '||dbms_utility.format_error_backtrace);

end;
/
show errors;