-- Process of preparing and building a mart.
-- Some examples of obfuscated queries, abridged

-- Part 1. Exploring and getting feel of the data

select h.id, h.rep_date as report_date, 
   po.name as person_name,
   p.index1, p.index2, p.reg_num as index3,
   a.name as address,
   h.code, h.loaddate as update_date
from hist_specdata h
inner join pref_person p on p.id = h.person_id
inner join pref_object po on po.id = h.person_id
left join pref_object a on a.id = h.address_id

-----

select s.info_ex_id, count(*), n.orgname  from pref_bank_acc s
left join pref_bank_info_ex n on n.id = s.info_ex_id
group by s.info_ex_id, n.orgname
order by 2 desc;




select s.info_ex_id, count(*), n.orgname, s.bank_id, b.bank_name, s.acc_id  from pref_bank_acc s
left join pref_bank_info_ex n on n.id = s.info_ex_id
left join pref_bank_info b on b.id = s.bank_id
group by s.info_ex_id, n.orgname, s.bank_id, b.bank_name, s.acc_id
order by 2 desc;

-----


select count(*) from
( select h.person_id, h.loadid, row_number() over (partition by h.person_id order by loadid desc) rn 
   from hist_specdata h
) t
inner join hist_specdata ht on ht.loadid = t.loadid and ht.person_id = t.person_id and t.rn = 1;
-- order by t.rn;

---------------------------------------
-- Part 2. Building the mart

     insert into ext_spec_mart(id, report_date, person_id, index1, index2, index3, code, update_date)
     select h.id, h.rep_date, h.person_id, p.index1, p.index2, p.reg_num, h.code, h.loaddate
       from hist_specdata h
 inner join pref_person p on p.id = h.person_id
      where h.loadid = (select max(h1.loadid) from hist_specdata h1
                         where h1.person_id = h.person_id
        	           );

     update ext_spec_mart
     	set person_name = (select o.name from pref_object o where o.id = ext_spec_mart.person_id)
      where person_name is null
        and rownum < 200000;
        and update_date > last_update_date;
        
---------------------------------------

