----------------------------------
--Vytvareni prislusnych triggeru--
----------------------------------

create sequence SEQ_Kniha_id
  minvalue 1
  maxvalue 9999999 -- kategorie maji ID number(7,0)
  nocycle
;

create trigger bef_ins_kniha_id
before insert -- spustit jeste pred vlastnim insertem ...
on Kniha  -- ... do tabulky Kniha ...
for each row  -- ... pro kazdou radku znovu ...
begin
  select SEQ_Kniha_id.nextval into :NEW.IdKnihy from dual;
end bef_ins_kniha_id;
/

create sequence SEQ_Ctenar_id
  minvalue 1
  maxvalue 9999999 -- ctenar ma ID number(7,0)
  nocycle
;

create trigger bef_ins_Ctenar_id
before insert 
on Ctenar 
for each row 
begin
  select SEQ_Ctenar_id.nextval into :NEW.IdCten from dual;
end bef_ins_Ctenar_id;
/

create sequence SEQ_Autor_id
  minvalue 1
  maxvalue 999999 -- autor ma ID number(6,0)
  nocycle
;

create trigger bef_ins_Autor_id
before insert 
on Autor 
for each row 
begin
  select SEQ_Autor_id.nextval into :NEW.IdAutor from dual;
end bef_ins_Autor_id;
/

create sequence SEQ_Nakladatelstvi_id
  minvalue 1
  maxvalue 9999 -- nakladatelstvi ma ID number(4,0)
  nocycle
;

create trigger bef_ins_Nakladatelstvi_id
before insert 
on Nakladatelstvi 
for each row 
begin
  select SEQ_Nakladatelstvi_id.nextval into :NEW.IdNakl from dual;
end bef_ins_Nakladatelstvi_id;
/

create sequence SEQ_Zanr_id
  minvalue 1
  maxvalue 99 -- zanr ma ID number(2,0)
  nocycle
;

create trigger bef_ins_Zanr_id
before insert 
on Zanr
for each row 
begin
  select SEQ_Zanr_id.nextval into :NEW.IdZanru from dual;
end bef_ins_Zanr_id;
/

create sequence SEQ_Vypujcky_id
  minvalue 1
  maxvalue 999999999 -- vypujcky maji ID number(9,0)
  nocycle
;

create trigger bef_ins_Vypujcky_id
before insert  
on Vypujcky
for each row 
begin
  select SEQ_Vypujcky_id.nextval into :NEW.IdVypujc from dual;
end bef_ins_Vypujcky_id;
/

create sequence SEQ_Archiv_id
  minvalue 1
  maxvalue 999999999 -- archiv ma ID number(9,0)
  nocycle
;

create trigger bef_ins_Archiv_id
before insert  
on Archiv
for each row 
begin
  select SEQ_Archiv_id.nextval into :NEW.IdUdalosti from dual;
end bef_ins_Archiv_id;
/

--nelze hodnotit knihu, pokud dany uzivatel danou knihu jeste nevratil (resp. nikdy si ji nepujcil)
--o to, ze ctenar nemuze vicekrat hodnotit stejnou knihu se staraji integritni omezeni tabulky (primarni klic)
create trigger bef_ins_Hodnoceni
before insert  
on Hodnoceni
for each row 
declare
   pocet_precteni number;
begin
  select count(*) into pocet_precteni 
  	from Archiv a 
  	where ((a.status = 'V') AND (a.IdCten = :NEW.IdCten) AND (a.IdKnihy = :New.IdKnihy));
  if (pocet_precteni = 0) 	
  	then
		RAISE_APPLICATION_ERROR(-20043, 'Nelze hodnotit knihu, pokud jste ji jeste nevratili, nebo ji vubec necetli!');
  end if;
end bef_ins_Hodnoceni;
/

--vyzkouseni funkcnosti triggeru
--insert into hodnoceni (IdCten, IdKnihy,Znamka) Values (0,0,20043);
--insert into archiv (IdCten, IdKnihy,Status) values (0, 0, 'V');

--nelze si pujcit knizku pokud:
--i)uz mam pujcenou knihu se stejnym ID (tj. stejnou knihu) - reseno na urovni integritnich omezeni (kandidatni klic)
--ii)dana kniha neni k dispozici (tj. vsechny exemplare jsou momentalne pujcene)
--iii)mam pocet pujcenych (nevracenych) knizek >10
--iv)libovolna z mych pujcenych (nevracenych) knizek je pujcena pres 100 dni
create trigger bef_ins_Vypujcky
before insert  
on Vypujcky
for each row 
declare
   pocet_kusu number; --celkovy pocet knih, ktere knihovna vlastni
   pocet_pujcenych number; --pocet aktualne pujcenych exemplaru dane knihy
   pocet_mych_pujcenych number; --pocet aktualne mnou pujcenych knih
   nejdrivejsi_vypujcka date; --ma dosud nevracena nejdrivejsi vypujcka
begin
  --ii)
  select k.pocet into pocet_kusu 
  	from Kniha k 
  	where (k.IdKnihy = :NEW.IdKnihy); --idKnihy primarni klic -> index
   
  select count(*) into pocet_pujcenych 
  	from Vypujcky v 
  	where (v.idKnihy = :NEW.IdKnihy); --idKnihy cizi klic -> index
   
  if (pocet_kusu <= pocet_pujcenych) then
  	RAISE_APPLICATION_ERROR(-20042, 'Vsechny exemplare jsou momentalne pujcene, danou knihu tedy nelze zapujcit.');
  end if;

  select count(*), min(KdyPujc)
    into pocet_mych_pujcenych, nejdrivejsi_vypujcka
  	from Vypujcky v 
    where (v.IdCten = :NEW.IdCten); --idKnihy cizi klic -> index
  
  if (pocet_mych_pujcenych > 0) then --jestlize nemam nic pujceneho, pak nemuzu mit moc knizek, ani zadnou pujcenou dele nez 100 dni 
    --iii)
    if (pocet_mych_pujcenych > 10) then
    	RAISE_APPLICATION_ERROR(-20041, 'Nemuzete mit pujcenych vice nez 10 knih, dana kniha tedy nelze pujcit.');
    end if;

    --iv)
    if (nejdrivejsi_vypujcka + 100 < current_date) then
    	RAISE_APPLICATION_ERROR(-20040, 'Mate pujcenou knihu dele nez 100 dni, dokud ji nevratite, nemuze Vam byt pujcena zadna jina kniha.');
    end if;
  end if;

end bef_ins_Vypujcky;
/

--vyzkouseni funkcnosti triggeru
--insert into Vypujcky (IdVypujc, IdCten, IdKnihy) values (1, 2, 0);
--fail - vsechny vypujcene
--insert into Vypujcky (IdVypujc, IdCten, IdKnihy, KdyPujc) values (2, 2, 1, current_date - 200);
--insert into Vypujcky (IdVypujc, IdCten, IdKnihy) values (3, 2, 2);
--error mas ji moc dlouho

--logovani pujcovani a vraceni knizek do archivu
create trigger aft_ins_del_Vypujcky
after insert or delete
on Vypujcky
for each row 
declare
   pozn Varchar2(64); --pro ulozeni poznamky, zda byla kniha vracena v limitu 100 dni
begin
  if (inserting) then
    insert into archiv (IdCten, IdKnihy, Status) 
      values (:new.IdCten, :new.IdKnihy, 'P'); --status P = pujceno
  else 
    if (:old.KdyPujc + 100 < current_date) then
      pozn := 'Vraceno az po ' || floor(current_date - :old.KdyPujc) || ' dnech.'; 
      DBMS_OUTPUT.PUT_LINE ('Pozor kniha s id: ' ||:old.IdKnihy ||' byla vracena se zpozdenim. Vice informaci v archivu.');       
    end if;
    insert into archiv (IdCten, IdKnihy, Status, Poznamka) 
      values (:old.IdCten, :old.IdKnihy, 'V', pozn); --status V = vraceno
  end if; 

end aft_ins_del_Vypujcky;
/

--pokud ma knihu nekdo pujcenou, tak ji nelze smazat, lze pouze zvysit jeji mnozstvi
create trigger bef_del_upd_Kniha
before update or delete
on Kniha
for each row 
declare
   pocet_pujcenych number; --pocet aktualne pujcenych knih s danym ID
begin
  select count(*) into pocet_pujcenych from Vypujcky v where (v.idKnihy = :old.IdKnihy);

  if (pocet_pujcenych > 0) then
    if (deleting) then    
      RAISE_APPLICATION_ERROR(-20044, 'Kniha nemuze byt smazana, pokud ji ma nekdo vypujcenou.');
    else --updating
      if not((:old.IdKnihy = :new.IdKnihy) AND (:old.ISBN = :new.ISBN) AND
        (:old.JmenoKnihy = :new.JmenoKnihy) AND (:old.IdZanru = :new.IdZanru) AND
        (:old.IdNakl = :new.IdNakl) AND (:old.Pocet < :new.Pocet)) --tj. zvysuje se pouze mnozstvi
        then
         RAISE_APPLICATION_ERROR(-20045, 'Danou knihu ma nekdo vypujcenou, jedine, co lze delat, je zvysovani poctu kusu.');
      end if;
    end if;
  end if;
end bef_del_upd_Kniha;
/

--pokud ma ctenar pujcenou nejakou knihu, pak nejde smazat
create trigger bef_del_Ctenar
before delete
on Ctenar
for each row 
declare
   pocet_pujcenych number; --pocet aktualne pujcenych knih daneho ctenare
begin
  select count(*) into pocet_pujcenych from Vypujcky v where (v.idCten = :old.IdCten);

  if (pocet_pujcenych > 0) then
    RAISE_APPLICATION_ERROR(-20054, 'Ctenar nemuze byt smazan, pokud ma pujcenou nejakou knihu.');    
  end if;
end bef_del_Ctenar;
/

--pokud je zanr uveden u nektere knihy, pak nejde smazat
create trigger bef_del_Zanr
before delete
on Zanr
for each row 
declare
   pocet_knih number; --pocet knih s danym zanrem
begin
  select count(*) into pocet_knih from Kniha k where (k.IdZanru = :old.IdZanru);

  if (pocet_knih > 0) then
    RAISE_APPLICATION_ERROR(-20054, 'Zanr je uveden u nektere knihy. Nemuze byt tudiz smazan.');    
  end if;
end bef_del_Zanr;
/

--pokud je zanr uveden u nektere knihy, pak nejde smazat
create trigger bef_del_Nakladatelstvi
before delete
on Nakladatelstvi
for each row 
declare
   pocet_knih number; --pocet knih s danym nakladatelstvim
begin
  select count(*) into pocet_knih from Kniha k where (k.IdNakl = :old.IdNakl);

  if (pocet_knih > 0) then
    RAISE_APPLICATION_ERROR(-20054, 'Nakladatelstvi je uvedeno u nektere knihy. Nemuze byt tudiz smazano.');    
  end if;
end bef_del_Nakladatelstvi;
/