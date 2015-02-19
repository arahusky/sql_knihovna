--Jedna se o zjednodussenou databazi knihovny
--Zakladnimi entitami jsou Ctenar, Kniha a Autor
--Kazda kniha pak je prave jednoho zanru a vydalo ji prave jedno nakladatelstvi 
--Kazdy Ctenar si muze (pokud jsou k dispozici) pujcit az 10 knih na dobu maximalne 100 dni (pokud tuto dobu presahne, tak mu nebude umozneno pujcit si dalsi knihu a po vraceni pak bude obsluha upozornena)
--Vsechny pujcovani a vraceni jsou logovany do archivu
--Kazdy Ctenar muze po precteni (a vraceni) knihy danou knihy zhodnotit

--podrobne omezujici informace mohou byt nalezeny v integritnich omezenich databaze, triggerech a procedurach

-----------------------------------------
--Definice tabulek a prislusnych indexu--
-----------------------------------------

--Tabulka Ctenar obsahujici jednotlive ctenare registrovane v knihovne
create table Ctenar(
  IdCten numeric(7,0),
  Jmeno varchar2(50) not null,
  Prijmeni varchar2(50) not null,
  DatumNarozeni date not null,
  Mesto varchar2(50) default null,
  CisloPopisne numeric(5,0) default null,
  Email varchar2(100) not null, 
  --
  constraint Ctenar_PK primary key (IdCten),
  constraint Ctenar_U_mail unique (Email), --kazdy ctenar musi mit unikatni emailovou adresu
  constraint Ctenar_CHK_Email --email musi byt validni
    check (REGEXP_LIKE(Email, '[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,4}'))
 );

--Tabulka Zanr obsahujici ruzne druhy zanru (e.g. sci-fi, historicky, ...), do kterych jsou jednotlive knihy zarazeny
create table Zanr(
	IdZanru numeric(2,0), 
	NazevZanru varchar2(50) not null,
 	--
 	constraint Zanr_PK primary key (IdZanru),
  constraint Zanr_U_NazevZanru unique (NazevZanru) --nazev Zanru musi byt unikatni
 );


--Tabulka Nakladatelstvi obsahuje nakladatelstvi, ktere vydavaji jednotlive knihy
create table Nakladatelstvi(
	IdNakl numeric(4,0), 
	NazevNakl varchar2(50) not null,
 	--
 	constraint Nakladatelstvi_PK primary key (IdNakl),
  constraint Nakladatelstvi_U_NazevNakl unique (NazevNakl) --nazev Nakladatelstvi musi byt unikatni
 );

--Tabulka Knihy obsahujici jednotlive knihy
create table Kniha(
	IdKnihy numeric(7,0),
	ISBN varchar2(17) not null,
	Jmeno varchar2(50) not null,
 	IdZanru numeric(2,0) not null,
 	IdNakl numeric(4,0) not null,
 	Pocet numeric(3,0) default 0 not null,
 	--
 	constraint Kniha_PK primary key (IdKnihy),
 	constraint Kniha_U_ISBN unique (ISBN), --ISBN je kandidatnim klicem, je pro kazdou knihu unikatni
 	constraint Kniha_CHK_Pocet check(Pocet>=0), 
 	constraint Kniha_FK_Zanr FOREIGN KEY (IdZanru) references Zanr(IdZanru),
 	constraint Kniha_FK_Nakladatelstvi FOREIGN KEY (IdNakl) references Nakladatelstvi(IdNakl)
 );

--indexy pres cizi klice (zanr a nakladatelstvi)
create index Kniha_zanr_INX on Kniha(IdZanru);
create index Kniha_Nakladatelstvi_INX on Kniha(IdNakl);

--Tabulka autor obsahuje vsechny autory
create table Autor(
	IdAutor numeric(6,0),
	Jmeno varchar2(50) not null,
 	Prijmeni varchar2(50) not null,
 	DatumNarozeni date not null,
 	--
 	constraint Autor_PK primary key (IdAutor)
 );

--Tabulka Napsal obsahuje informace o tom, kdo napsal kterou knihu
create table Napsal(
	IdAutor numeric(6,0),
	IdKnihy numeric(7,0),
 	--
 	constraint Napsal_PK primary key (IdAutor, IdKnihy),
  --pokud se smaze dana kniha, nebo jeji autor, maze se i prislusny radek
 	constraint Napsal_FK_Autor FOREIGN KEY (IdAutor) references Autor(IdAutor) on delete cascade,
 	constraint Napsal_FK_Kniha FOREIGN KEY (IdKnihy) references Kniha(IdKnihy) on delete cascade
 );

--indexy pres cizi klice (zanr a nakladatelstvi)

--zastupitelny indexem pres primarni klic
--create index Napsal_Autor_INX on Napsal(IdAutor); 
create index Napsal_Kniha_INX on Napsal(IdKnihy);



--Tabulka Vypujcky obsahuje vsechny aktualne vypujcene knihy
create table Vypujcky(
	IdVypujc numeric(9,0),
	IdCten numeric(7,0),
	IdKnihy numeric(7,0),
	KdyPujc date default current_date not null,
 	--
 	constraint Vypujcky_PK primary key (IdVypujc),
 	constraint Vypujcky_U_CtenarKniha unique(IdCten, IdKnihy), --jeden ctenar nemuze mit zaraz pujcenych vice stejnych knih
 	constraint Vypujcky_FK_Ctenar FOREIGN KEY (IdCten) references Ctenar(IdCten),
 	constraint Vypujcky_FK_Kniha FOREIGN KEY (IdKnihy) references Kniha(IdKnihy)
 );

--indexy pres cizi klice (IdCtenare a IdKnihy)
create index Vypucky_Ctenar_INX on Vypujcky(IdCten);
create index Vypujcky_Kniha_INX on Vypujcky(IdKnihy);

--Tabulka Archiv slouzi jako log udalosti spojenych s pujcovanim knih
create table Archiv(
	IdUdalosti numeric(9,0),
	DatumUdalosti date default current_date not null, --kdy k teto udalosti doslo
	IdCten numeric(7,0), --ktereho ctenare se tyka
	IdKnihy numeric(7,0), -- ktere knihy se tyka
	Status CHARACTER(1) NOT NULL, -- P pujceno, V vraceno, R rezervovano
	Poznamka Varchar2(64) default null, --textova poznamka k dane udalosti (e.g. vraceno se zpozdenim X dnu)
 	--
 	constraint Archiv_PK primary key (IdUdalosti),
 	constraint Archiv_FK_Ctenar FOREIGN KEY (IdCten) references Ctenar(IdCten) on delete cascade,
 	constraint Archiv_FK_Kniha FOREIGN KEY (IdKnihy) references Kniha(IdKnihy) on delete cascade
 );

--indexy pres cizi klice (IdCtenare a IdKnihy)
create index Archiv_Ctenar_INX on Archiv(IdCten);
create index Archiv_Kniha_INX on Archiv(IdKnihy);

--Tabulka Hodnoceni slouzi pro ohodnoceni knihy ctenarem (az pote, co ji vrati)
create table Hodnoceni(
	IdCten numeric(7,0), --ktereho ctenare se tyka
	IdKnihy numeric(7,0), -- ktere knihy se tyka
	Znamka numeric(1,0) NOT NULL, 
	--
 	constraint Hodnoceni_PK primary key (IdCten, IdKnihy),
    constraint Hodnoceni_CHK_Znamka check(Znamka>=1 and Znamka<=5), --hodnoceni (1-5)
 	constraint Hodnoceni_FK_Ctenar FOREIGN KEY (IdCten) references Ctenar(IdCten) on delete cascade,
 	constraint Hodnoceni_FK_Kniha FOREIGN KEY (IdKnihy) references Kniha(IdKnihy) on delete cascade
 );

--indexy pres cizi klice (IdCtenare a IdKnihy)

--zastupitelny indexem pres primarni klic
--create index Hodnoceni_Ctenar_INX on Hodnoceni(IdCten);
create index Hodnoceni_Kniha_INX on Hodnoceni(IdKnihy);

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
  if (:NEW.IdKnihy is null) then  
    select SEQ_Kniha_id.nextval into :NEW.IdKnihy from dual;
  end if;
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
  if (:NEW.IdCten is null) then
    select SEQ_Ctenar_id.nextval into :NEW.IdCten from dual;
  end if;
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
  if (:NEW.IdAutor is null) then
    select SEQ_Autor_id.nextval into :NEW.IdAutor from dual;
  end if;
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
  if (:NEW.IdNakl is null) then
    select SEQ_Nakladatelstvi_id.nextval into :NEW.IdNakl from dual;
  end if;
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
  if (:NEW.IdZanru is null) then
    select SEQ_Zanr_id.nextval into :NEW.IdZanru from dual;
  end if;
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
  if (:NEW.IdVypujc is null) then
    select SEQ_Vypujcky_id.nextval into :NEW.IdVypujc from dual;
  end if;
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
  if (:NEW.IdUdalosti is null) then
    select SEQ_Archiv_id.nextval into :NEW.IdUdalosti from dual;
  end if;
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
        (:old.Jmeno = :new.Jmeno) AND (:old.IdZanru = :new.IdZanru) AND
        (:old.IdNakl = :new.IdNakl) AND (:old.Pocet < :new.Pocet)) --tj. zvysuje se pouze mnozstvi
        then
         RAISE_APPLICATION_ERROR(-20045, 'Danou knihu ma nekdo vypujcenou, jedine, co lze delat, je zvysovani poctu kusu.');
      end if;
    end if;
  end if;
end bef_del_upd_Kniha;
/

-- zruseno kvuli paralelnimu behu (osetreno v procedure na smazani uzivatele)
-- pokud ma ctenar pujcenou nejakou knihu, pak nejde smazat
-- create trigger bef_del_Ctenar
-- before delete
-- on Ctenar
-- for each row 
-- declare
--   pocet_pujcenych number; --pocet aktualne pujcenych knih daneho ctenare
-- begin
--  select count(*) into pocet_pujcenych from Vypujcky v where (v.idCten = :old.IdCten);

--   if (pocet_pujcenych > 0) then
--     RAISE_APPLICATION_ERROR(-20054, 'Ctenar nemuze byt smazan, pokud ma pujcenou nejakou knihu.');    
--   end if;
-- end bef_del_Ctenar;
-- /

-- zruseno kvuli paralelnimu behu (osetreno v procedure na smazani uzivatele)
--pokud je zanr uveden u nektere knihy, pak nejde smazat
-- create trigger bef_del_Zanr
-- before delete
-- on Zanr
-- for each row 
-- declare
--    pocet_knih number; --pocet knih s danym zanrem
-- begin
--   select count(*) into pocet_knih from Kniha k where (k.IdZanru = :old.IdZanru);

--   if (pocet_knih > 0) then
--     RAISE_APPLICATION_ERROR(-20054, 'Zanr je uveden u nektere knihy. Nemuze byt tudiz smazan.');    
--   end if;
-- end bef_del_Zanr;
-- /

--pokud je zanr uveden u nektere knihy, pak nejde smazat
-- create trigger bef_del_Nakladatelstvi
-- before delete
-- on Nakladatelstvi
-- for each row 
-- declare
--    pocet_knih number; --pocet knih s danym nakladatelstvim
-- begin
--   select count(*) into pocet_knih from Kniha k where (k.IdNakl = :old.IdNakl);

--   if (pocet_knih > 0) then
--     RAISE_APPLICATION_ERROR(-20054, 'Nakladatelstvi je uvedeno u nektere knihy. Nemuze byt tudiz smazano.');    
--   end if;
-- end bef_del_Nakladatelstvi;
-- /

--vyzkouseni:
--delete from vypujcky

---------------------------------------
--Vlozeni demonstracnich dat-----------
---------------------------------------

insert into Zanr (NazevZanru) values ('sci-fi');
insert into Zanr (NazevZanru) values ('fantasy');
insert into Zanr (NazevZanru) values ('detektivka');

insert into Nakladatelstvi (NazevNakl) values ('Euromedia Group - Knižní klub');
insert into Nakladatelstvi (NazevNakl) values ('Albatros');
insert into Nakladatelstvi (NazevNakl) values ('Kniha Zlín');

insert into Kniha (ISBN, Jmeno, IdZanru, IdNakl, Pocet) 
  values ('978-80-242-4682-6', 'Nástroje smrti 6: Město nebeského ohně', 2, 1, 2);

insert into Kniha (ISBN, Jmeno, IdZanru, IdNakl, Pocet) 
  values ('978-80-00-02756-2', 'Harry Potter a kámen mudrců', 2, 2, 1);

insert into Kniha (ISBN, Jmeno, IdZanru, IdNakl, Pocet) 
  values ('80-00-01197-2', 'Harry Potter a Tajemná komnata', 2, 2, 1);

insert into Kniha (ISBN, Jmeno, IdZanru, IdNakl, Pocet) 
  values ('978-80-87497-45-6', 'Sněhulák', 3, 3, 2);

insert into Kniha (ISBN, Jmeno, IdZanru, IdNakl, Pocet) 
  values ('978-80-87497-01-2', 'Nemesis', 3, 3, 1);

insert into autor (Jmeno, Prijmeni, DatumNarozeni) 
  values ('Cassandra', 'Clareová', '27-JUL-1973');
insert into autor (Jmeno, Prijmeni, DatumNarozeni) 
  values ('Joanne', 'Rowlingová', '31-JUL-1965');
insert into autor (Jmeno, Prijmeni, DatumNarozeni) 
  values ('Jo', 'Nesbø', '29-MAR-1960');

insert into napsal (IdAutor, IdKnihy) values (1, 1);
insert into napsal (IdAutor, IdKnihy) values (2, 2);
insert into napsal (IdAutor, IdKnihy) values (2, 3);
insert into napsal (IdAutor, IdKnihy) values (3, 4);
insert into napsal (IdAutor, IdKnihy) values (3, 5);

insert into Ctenar (Jmeno, Prijmeni, DatumNarozeni, Mesto, CisloPopisne, Email)
  values ('Jakub', 'Naplava', '03-Mar-1993', 'Osvetimany', 378, 'arahusky@seznam.cz');

insert into Ctenar (Jmeno, Prijmeni, DatumNarozeni, Mesto, CisloPopisne, Email)
  values ('Josef', 'Valtr', '01-JUN-2000', 'Praha', 123, 'pepa.valtr@google.com');

insert into Ctenar (Jmeno, Prijmeni, DatumNarozeni, Mesto, CisloPopisne, Email)
  values ('Jana', 'Novotna', '24-DEC-1967', 'Uherské Hradiště', 4352, 'jana.novotna@google.com');

insert into Ctenar (Jmeno, Prijmeni, DatumNarozeni, Mesto, CisloPopisne, Email)
  values ('Ema', 'Destinova', '19-NOV-1933', 'New York', 1, 'ema.dest@email.cz');

insert into Vypujcky (IdCten, IdKnihy) 
  values (1, 1);

insert into Vypujcky (IdCten, IdKnihy) 
  values (2, 1);

--defaultne se vklada jako den pujceni current_date, my vlozime pujceni knihy pred 200 dny
insert into Vypujcky (IdCten, IdKnihy, KdyPujc) 
  values (2, 2, current_date - 200);

insert into Vypujcky (IdCten, IdKnihy, KdyPujc) 
  values (3, 4, current_date - 101);

insert into Vypujcky (IdCten, IdKnihy) 
  values (4, 5);

----------------------
--Packages------------
----------------------

Create package db_kniha as
  --pridani nove knihy
  PROCEDURE pridej(
    xisbn      kniha.ISBN%type,
    xJmeno   kniha.Jmeno%type,
    xidZanru  kniha.IdZanru%type,
    xIdNakl  kniha.IdNakl%type,
    xPocet kniha.Pocet%type
  );

  --odebrani knihy dle ID (uplne odebrani vsech kusu)
  PROCEDURE odeber(xid kniha.idKnihy%type);

  --editace knihy (i pro snizeni poctu kusu dane knihy)
  procedure edit(
    xid   kniha.idKnihy%type,
    xisbn      kniha.ISBN%type default null,
    xJmeno   kniha.Jmeno%type default null,
    xidZanru  kniha.IdZanru%type default null,
    xIdNakl  kniha.IdNakl%type default null,
    xPocet kniha.Pocet%type default null
  );

  --zjisteni ID na zaklade znalosti ISBN
  function id_podle_isbn(xisbn kniha.isbn%type) return kniha.idKnihy%type;

  --zjisteni, kolik knih s danym ID je momentalne pujcenych
  function pocet_pujcenych(xid kniha.IdKnihy%type) return kniha.Pocet%type;
  END; --db_kniha
/

CREATE PACKAGE BODY db_kniha AS
 
  --provazani s vyjimkami, ktere vyhazuje db
 EXC_prilis_dlouha_hodnota EXCEPTION;
 EXC_neexistujici_zanr_nkl EXCEPTION;
 EXC_porusena_unikatnost EXCEPTION;

 --EXC_datum_spatny_format EXCEPTION;

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_neexistujici_zanr_nkl, -02291);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);

 PROCEDURE pridej(
    xisbn      kniha.ISBN%type,
    xJmeno   kniha.Jmeno%type,
    xidZanru  kniha.IdZanru%type,
    xIdNakl  kniha.IdNakl%type,
    xPocet kniha.Pocet%type
  )
  AS
  begin
      insert into kniha (ISBN, Jmeno, IdZanru, IdNakl, Pocet)
        values (xisbn, xJmeno, xidZanru, xIdNakl, xPocet);

      DBMS_OUTPUT.PUT_LINE ('Nova kniha ' || xJmeno || ' byla uspesne pridana. Doporucujeme, co nejdrive pridat autory.');
      
   EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Dane ISBN uz je v databazi ulozene.');
    when EXC_neexistujici_zanr_nkl then
      RAISE_APPLICATION_ERROR (-20015,'Zanr nebo nakladatelstvi s pozadovanym ID neexistuje.');
  end; --pridej


 procedure odeber(xid kniha.idKnihy%type)
 as
 begin
  delete from kniha where idKnihy = xid;
    --pokud ma danou knihu nekdo pujcenou, postara se o nesmazani a vyhozeni chybove hlasky trigger
 end; --odeber

 procedure edit(
    xid   kniha.idKnihy%type,
    xisbn      kniha.ISBN%type default null,
    xJmeno   kniha.Jmeno%type default null,
    xidZanru  kniha.IdZanru%type default null,
    xIdNakl  kniha.IdNakl%type default null,
    xPocet kniha.Pocet%type default null
  ) as 
 begin  
   update Kniha set
      isbn = decode(xisbn, null, isbn, xisbn),
      Jmeno = decode(xJmeno, null, Jmeno, xJmeno),
      IdZanru = decode(xidZanru, null, IdZanru, xidZanru),
      IdNakl = decode(xIdNakl, null, IdNakl, xIdNakl),
      Pocet = decode(xPocet, null, Pocet, xPocet)
    where idKnihy=xid;
    --podobne i zde se trigger postara o to, ze kdyz ma nekdo nejakou knihu pujcenou, tak lze pouze zvysit jeji mnozstvi

    EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Dany email uz je registrovany.');
    when EXC_neexistujici_zanr_nkl then
      RAISE_APPLICATION_ERROR (-20015,'Zanr nebo nakladatelstvi s pozadovanym ID neexistuje.');
  end; --edit

  function id_podle_isbn(xisbn kniha.isbn%type) return kniha.idKnihy%type as
    ret kniha.idKnihy%type;
  begin
    select IdKnihy into ret from Kniha where isbn = xisbn;
    return ret;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR (-20003, 'Kniha s ISBN: ' || xisbn || ' neexistuje.');
  return null;
  end; --id_podle_isbn


  --zjisteni, kolik knih s danym ID je momentalne pujcenych
  function pocet_pujcenych(xid kniha.IdKnihy%type) return kniha.Pocet%type as
    ret kniha.Pocet%type;
  begin
    select count(*) into ret
      from vypujcky v 
      where (v.idKnihy = xid);
    return ret;
  end; --pocet_pujcenych

 END; --db_kniha
/

--examples
--select db_kniha.id_podle_isbn('80-00-01197-2') from dual;


Create package db_ctenar as
  --pridani noveho ctenare
  PROCEDURE pridej(
    xjmeno      ctenar.Jmeno%type,
    xprijmeni   ctenar.Prijmeni%type,
    xdatumNarozeni  ctenar.DatumNarozeni%type,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type
  );

  --odebrani ctenare dle ID
  PROCEDURE odeber(xid ctenar.idCten%type);

  --editace ctenare
  procedure edit(
    xid   ctenar.idCten%type,
    xjmeno      ctenar.Jmeno%type default null,
    xprijmeni   ctenar.Prijmeni%type default null,
    xdatumNarozeni  ctenar.DatumNarozeni%type default null,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type default null
  );

  --zjisteni ID na zaklade znalosti emailu
  function id_podle_emailu(xemail ctenar.email%type) return ctenar.idCten%type;

  --dany uzivatel si pujci danou knihu
  procedure pujc_knihu(
    xidCten   ctenar.idCten%type,
    xidKnihy  kniha.IdKnihy%type
  );

  --zkusi vratit knihu (pokud mame knihu pujcenou dele nez 100 dni, je nutno pouzit vrat_knihu_pozde)
  procedure vrat_knihu(
    xidCten   ctenar.idCten%type,
    xidKnihy  kniha.IdKnihy%type
  );

  --vraceni knihy, pokud byla pujcena nejdriv pred 100 dny
  procedure vrat_knihu_pozde(
    xidCten   ctenar.idCten%type,
    xidKnihy  kniha.IdKnihy%type
  );


  procedure pridej_hodnoceni(
    xidCten   hodnoceni.idCten%type,
    xidKnihy  hodnoceni.IdKnihy%type,
    xznamka hodnoceni.Znamka%type
  );

  END; --db_ctenar
/

CREATE PACKAGE BODY db_ctenar AS
 
 --provazani s vyjimkami, ktere vyhazuje db
 EXC_prilis_dlouha_hodnota EXCEPTION;
 EXC_porusena_unikatnost EXCEPTION;
 EXC_neexistujici_cte_kniha EXCEPTION;
 EXC_kniha_pujcena EXCEPTION;
 --EXC_datum_spatny_format EXCEPTION;

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);
 PRAGMA EXCEPTION_INIT (EXC_neexistujici_cte_kniha, -02291);
 PRAGMA EXCEPTION_INIT (EXC_kniha_pujcena, -02292);

 PROCEDURE pridej(
    xjmeno      ctenar.Jmeno%type,
    xprijmeni   ctenar.Prijmeni%type,
    xdatumNarozeni  ctenar.DatumNarozeni%type,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type
  )
  AS
  begin
      insert into ctenar (Jmeno, Prijmeni, DatumNarozeni, Mesto, CisloPopisne, Email)
        values (xjmeno, xprijmeni, xdatumNarozeni, xmesto, xcisloPopisne, lower(xemail));

      DBMS_OUTPUT.PUT_LINE ('Novy ctenar ' || xjmeno || ' ' || xprijmeni || ' byl uspesne pridan.');
      
  EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Dany email uz je registrovany.');
  end; --pridej


 procedure odeber(xid ctenar.idCten%type)
 as
 begin
  delete from ctenar where idCten = xid;
  EXCEPTION
    when EXC_kniha_pujcena then
      RAISE_APPLICATION_ERROR (-20071,'Ctenar ma pujcenou nejakou knihu. Nelze tudiz smazat.');
 end;

 procedure edit(
    xid   ctenar.idCten%type,
    xjmeno      ctenar.Jmeno%type default null,
    xprijmeni   ctenar.Prijmeni%type default null,
    xdatumNarozeni  ctenar.DatumNarozeni%type default null,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type default null
  ) as 
 begin  
   update Ctenar set
      Jmeno = decode(xjmeno, null, Jmeno, xjmeno),
      Prijmeni = decode(xprijmeni, null, Prijmeni, xprijmeni),
      DatumNarozeni = decode(xdatumNarozeni, null, DatumNarozeni, xdatumNarozeni),
      Mesto = decode(xmesto, null, Mesto, 'null', null, xmesto),
      CisloPopisne = decode(xcisloPopisne, null, CisloPopisne, 'null', null, xcisloPopisne),
      Email = decode(xemail, null, email, lower(xemail))
    where idCten=xid;

    EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Dany email uz je registrovany.');
  end; --edit

  function id_podle_emailu(xemail ctenar.email%type) return ctenar.idCten%type as
    ret ctenar.idCten%type;
  begin
    select IdCten into ret from Ctenar where Email = lower(xemail);
    return ret;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20003, 'Uzivatel s emailem: ' || xemail || ' neexistuje.');
  return null;
  end; --id_podle_emailu

  procedure pujc_knihu(
    xidCten   ctenar.idCten%type,
    xidKnihy  kniha.IdKnihy%type
  ) as 
  begin
    insert into vypujcky (idCten, idKnihy) values (xidCten, xidKnihy);
  EXCEPTION 
    WHEN EXC_porusena_unikatnost THEN
      RAISE_APPLICATION_ERROR(-20088, 'Dany uzivatel uz si danou knihu pujcil. Nelze pujcovat vice exemplaru jednomu ctenari.');
    WHEN EXC_neexistujici_cte_kniha then
     RAISE_APPLICATION_ERROR(-20089, 'Dany uzivatel nebo kniha neexistuje.'); 
  end; --pujc_knihu

  procedure vrat_knihu(
    xidCten   ctenar.idCten%type,
    xidKnihy  kniha.IdKnihy%type
  ) 
  as 
     pujceno vypujcky.KdyPujc%type;
  begin
    select KdyPujc into pujceno 
      from Vypujcky v 
      Where ((v.IdCten = xidCten) AND (v.idKnihy = xidKnihy));

    if ((pujceno + 100) < current_date) then
      RAISE_APPLICATION_ERROR (-20075,'Dana kniha byla pujcena pred dele nez 100 dny. Pro jeji vraceni je tedy nutne pouzit proceduru ''vrat_knihu_pozde''');
    end if;

    delete from vypujcky where ((idKnihy = xidKnihy) AND (idCten = xidCten));
  end; --vrat_knihu

  --vraceni knihy, pokud byla pujcena nejdriv pred 100 dny
  procedure vrat_knihu_pozde(
    xidCten   ctenar.idCten%type,
    xidKnihy  kniha.IdKnihy%type
  )
  as
  begin
    delete from vypujcky where ((idKnihy = xidKnihy) AND (idCten = xidCten));
  end; --vrat_knihu_pozde


  procedure pridej_hodnoceni(
    xidCten   hodnoceni.idCten%type,
    xidKnihy  hodnoceni.IdKnihy%type,
    xznamka hodnoceni.Znamka%type
  ) as
  begin
    if ((xznamka < 1) OR (xznamka > 5)) then
      RAISE_APPLICATION_ERROR(-20066, 'Znamka musi byt v rozpeti 1-5.');
    end if;

    insert into hodnoceni (idCten, idKnihy, Znamka) values (xidCten, xidKnihy, xznamka);
  EXCEPTION 
    WHEN EXC_porusena_unikatnost THEN
      RAISE_APPLICATION_ERROR(-20088, 'Dany uzivatel uz danou knihu hodnotil.');
    WHEN EXC_neexistujici_cte_kniha then
     RAISE_APPLICATION_ERROR(-20089, 'Dany uzivatel nebo kniha neexistuje.'); 
  end; --pridej_hodnoceni

 END; --db_ctenar
/

--priklad
--exec db_ctenar.pridej('Jakub', 'Naplava', '3-MAR-93', 'Osvetimany', 378, 'arahusky@seznam.cz');


Create package db_zanr as
  --pridani noveho zanru
  PROCEDURE pridej(
    xnazevZanru zanr.NazevZanru%type
  );

  --odebrani zanru dle ID
  PROCEDURE odeber(xid zanr.IdZanru%type);

  --editace zanru (zmena jeho nazvu)
  procedure edit(
    xid   zanr.IdZanru%type,
    xnazevZanru zanr.NazevZanru%type
  );

  --zjisteni ID na zaklade znalosti nazvu zanru
  function id_podle_zanru(xnazevZanru zanr.NazevZanru%type) return zanr.IdZanru%type;
  END; --db_zanr
/

CREATE PACKAGE BODY db_zanr AS
 
 --provazani s vyjimkami, ktere vyhazuje db
 EXC_prilis_dlouha_hodnota EXCEPTION;
 EXC_porusena_unikatnost EXCEPTION;
 EXC_zanr_prirazen EXCEPTION;

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);
 PRAGMA EXCEPTION_INIT (EXC_zanr_prirazen, -02292);

 PROCEDURE pridej(
    xnazevZanru zanr.NazevZanru%type
  )
  AS
  begin
      insert into Zanr (NazevZanru)
        values (lower(xnazevZanru)); --case insensitive

      DBMS_OUTPUT.PUT_LINE ('Novy zanr ' || xnazevZanru  || ' byl uspesne pridan.');
      
  EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Zanr s danym nazvem je uz v databazi ulozeny.');
  end; --pridej


 procedure odeber(xid zanr.IdZanru%type)
 as
 begin
  delete from zanr where IdZanru = xid;
  EXCEPTION
    when EXC_zanr_prirazen then
      RAISE_APPLICATION_ERROR (-20071,'Zanr je prirazen nektere knize, nelze tudiz smazat.');
 end;

 procedure edit(
    xid   zanr.IdZanru%type,
    xnazevZanru zanr.NazevZanru%type
  ) as 
 begin  
   update Zanr set
      NazevZanru = lower(xnazevZanru) --case insensitive
    where IdZanru=xid;

    EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Zanr se stejnym nazvem uz existuje.');
  end; --edit

  function id_podle_zanru(xnazevZanru zanr.NazevZanru%type) return zanr.IdZanru%type as
    ret zanr.IdZanru%type;
  begin
    select IdZanru into ret from Zanr where NazevZanru = lower(xnazevZanru); --case insensitive
    return ret;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR (-20003, 'Zanr s nazvem: ' || xnazevZanru || ' neexistuje.');
  return null;
  end; --id_podle_zanru

 END; --db_zanr
/


Create package db_nakladatelstvi as
  --pridani noveho nakladatelstvi
  PROCEDURE pridej(
    xnazevNakl nakladatelstvi.NazevNakl%type
  );

  --odebrani nakladatelstvi dle ID
  PROCEDURE odeber(xid nakladatelstvi.IdNakl%type);

  --editace nakladatelstvi (zmena jeho nazvu)
  procedure edit(
    xid nakladatelstvi.IdNakl%type,
    xnazevNakl nakladatelstvi.NazevNakl%type
  );

  --zjisteni ID na zaklade znalosti nazvu nakladatelstvi
  function id_podle_nazvu(xnazevNakl nakladatelstvi.NazevNakl%type) return nakladatelstvi.IdNakl%type;
  END; --db_nakladatelstvi
/

CREATE PACKAGE BODY db_nakladatelstvi AS
 
 --provazani s vyjimkami, ktere vyhazuje db
 EXC_prilis_dlouha_hodnota EXCEPTION;
 EXC_porusena_unikatnost EXCEPTION;
 EXC_nakl_prirazeno EXCEPTION;

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);
 PRAGMA EXCEPTION_INIT (EXC_nakl_prirazeno, -02292);

 PROCEDURE pridej(
    xnazevNakl nakladatelstvi.NazevNakl%type
  )
  AS
  begin
      insert into Nakladatelstvi (NazevNakl)
        values (lower(xnazevNakl)); --case insensitive

      DBMS_OUTPUT.PUT_LINE ('Nove nakladatelstvi ' || xnazevNakl  || ' bylo uspesne pridano.');
      
  EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Nakladatelstvi s danym nazvem je uz v databazi ulozeno.');
  end; --pridej


 procedure odeber(xid nakladatelstvi.IdNakl%type)
 as
 begin
  delete from nakladatelstvi where IdNakl = xid;
  EXCEPTION
    when EXC_nakl_prirazeno then
      RAISE_APPLICATION_ERROR (-20071,'Nakladatelstvi je prirazeno nektere knize, nelze tudiz smazat.');
 end; --odeber

 procedure edit(
    xid nakladatelstvi.IdNakl%type,
    xnazevNakl nakladatelstvi.NazevNakl%type
  ) as 
 begin  
   update Nakladatelstvi set
      NazevNakl = lower(xnazevNakl) --case insensitive
    where IdNakl=xid;

    EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
    when EXC_porusena_unikatnost then
      RAISE_APPLICATION_ERROR (-20005,'Nakladatelstvi se stejnym nazvem uz existuje.');
  end; --edit

  function id_podle_nazvu(xnazevNakl nakladatelstvi.NazevNakl%type) return nakladatelstvi.IdNakl%type as
    ret nakladatelstvi.IdNakl%type;
  begin
    select IdNakl into ret from Nakladatelstvi where NazevNakl = lower(xnazevNakl); --case insensitive
    return ret;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR (-20003, 'Nakladatelstvi s nazvem: ' || xnazevNakl || ' neexistuje.');
  return null;
  end; --id_podle_nazvu

 END; --db_nakladatelstvi
/


Create package db_autor as
  --pridani noveho autora
  PROCEDURE pridej(
    xJmeno      autor.Jmeno%type,
    xPrijmeni   autor.Prijmeni%type,
    xDatumNarozeni  autor.DatumNarozeni%type
  );

  --odebrani autora dle ID
  PROCEDURE odeber(xid autor.IdAutor%type);

  --editace autora
  procedure edit(
    xid   autor.IdAutor%type,
    xJmeno      autor.Jmeno%type default null,
    xPrijmeni   autor.Prijmeni%type default null,
    xDatumNarozeni  autor.DatumNarozeni%type default null
  );

  --s danym autorem asociuje autorstvi dane knihy
  procedure pridej_knihu(
    xidAut   autor.IdAutor%type,
    xidKniha  kniha.IdKnihy%type
  );

  --odebere autorstvi dane knihy od daneho autora
  procedure odeber_knihu(
    xidAut   autor.IdAutor%type,
    xidKniha  kniha.IdKnihy%type
  );

  END; --db_autor
/

CREATE PACKAGE BODY db_autor AS
 
 --provazani s vyjimkami, ktere vyhazuje db
 EXC_prilis_dlouha_hodnota EXCEPTION;
 EXC_porusena_unikatnost EXCEPTION;
 EXC_neexistujici_aut_kniha EXCEPTION;

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);
 PRAGMA EXCEPTION_INIT (EXC_neexistujici_aut_kniha, -02291);

 PROCEDURE pridej(
    xJmeno      autor.Jmeno%type,
    xPrijmeni   autor.Prijmeni%type,
    xDatumNarozeni  autor.DatumNarozeni%type
  )
  AS
  begin
      insert into autor (Jmeno, Prijmeni, DatumNarozeni)
        values (xJmeno, xPrijmeni, xDatumNarozeni);

      DBMS_OUTPUT.PUT_LINE ('Novy autor ' || xJmeno || ' ' || xPrijmeni || ' byl uspesne pridan.');
      
  EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
  end; --pridej


 procedure odeber(xid autor.IdAutor%type)
 as
 begin
  delete from autor where IdAutor = xid;
    --daneho autora muzeme smazat kdykoliv (kdyz neco napsal, tak se FK postara, aby dany zaznam zmizel i z tabulky napsal)
 end;

 procedure edit(
    xid   autor.IdAutor%type,
    xJmeno      autor.Jmeno%type default null,
    xPrijmeni   autor.Prijmeni%type default null,
    xDatumNarozeni  autor.DatumNarozeni%type default null
  ) as 
 begin  
   update Autor set
      Jmeno = decode(xJmeno, null, Jmeno, xJmeno),
      Prijmeni = decode(xPrijmeni, null, Prijmeni, xPrijmeni),
      DatumNarozeni = decode(xDatumNarozeni, null, DatumNarozeni, xDatumNarozeni)
    where IdAutor=xid;

    EXCEPTION
    when EXC_prilis_dlouha_hodnota then
      RAISE_APPLICATION_ERROR (-20001,'Nektera z vkladanych hodnot je pro ulozeni prilis dlouha.');
  end; --edit


  procedure pridej_knihu(
    xidAut   autor.IdAutor%type,
    xidKniha  kniha.IdKnihy%type
  ) AS 
  begin  
   insert into Napsal (IdAutor, idKnihy) values (xidAut, xidKniha);

  EXCEPTION
    when EXC_neexistujici_aut_kniha then
      RAISE_APPLICATION_ERROR (-20031,'Nektery z ID je neplatny (tj. bud autor, nebo kniha).');
  end; --pridej_knihu

  procedure odeber_knihu(
    xidAut   autor.IdAutor%type,
    xidKniha  kniha.IdKnihy%type
  ) as
  begin
    delete from napsal 
      where ((IdAutor = xidAut) AND (IdKnihy = xidKniha));
  end; --odeber_knihu

 END; --db_ctenar
/


----------------------
--Views---------------
----------------------

--seznam ctenaru
create view VW_seznam_ctenaru as
  select (Jmeno || ' ' || Prijmeni) as jmeno, DatumNarozeni as datum_narozeni, 
  (Mesto || ' ' || CisloPopisne) as bydliste, email, idCten as id
    from Ctenar
;

--seznam knih
create view VW_seznam_knih as
  select Jmeno as jmeno_knihy, ISBN, NazevNakl as jmeno_nakladatelstvi, NazevZanru as nazev_zanru,
    pocet as pocet_kusu, idKnihy as id
    from Kniha 
    natural join Zanr
    natural join Nakladatelstvi
;

--seznam knih s poctem udavajicim, kolik jich je dostupnych k pujceni
create view VW_pocet_dost_knih as
  select k.IdKnihy, k.ISBN, k.Jmeno, k.idZanru, k.idNakl, 
        (k.pocet - db_kniha.pocet_pujcenych(k.IdKnihy)) as pocet_dostupnych from Kniha k
;

--seznam volnych knih (tj. knih dostupnych pro pujceni)
create view VW_volne_knihy as
  select * from VW_pocet_dost_knih v where (v.pocet_dostupnych > 0)
;

--seznam aktualne vypujcenych knihy
create view VW_pujcene_knihy as
  select IdKnihy as id_knihy, Jmeno as jmeno_knihy, IdCten as id_ctenare, KdyPujc as datum_vypujcky from vypujcky 
    natural join kniha
;

--seznam lidi a prislusnych knih, ktere jsou pujcene dele nez 100 dni
create view VW_seznam_hrisniku_a_knih as
  select idCten AS IdCtenare, (Jmeno || ' ' || Prijmeni) as Jmeno_Ctenare, Email, IdKnihy,
   Jmeno, KdyPujc as Datum_Vypujcky, floor(current_date - KdyPujc) as Pocet_Dni_Od_Pujceni
    from vypujcky
    natural join ctenar
    natural join kniha
    where (KdyPujc + 100 < current_date)
;

--seznam lidi, kteri aktualne maji nektere knihu pujcene dele nez 100 dni
create view VW_seznam_hrisniku as
 select distinct IdCtenare, Jmeno_Ctenare, Email From VW_seznam_hrisniku_a_knih
;

--seznam autoru
create view VW_seznam_autoru as
 select (Jmeno || ' ' || Prijmeni) as jmeno, DatumNarozeni as datum_narozeni, IdAutor as id
   from autor
;

--seznam autoru s knihami, ktere napsali
create view VW_seznam_autor_kniha as
 select V.jmeno as jmeno_autora, V.id as id_autora, k.Jmeno as jmeno_knihy, k.idKnihy as id_knihy  
  from VW_seznam_autoru V
  inner join napsal n on (n.IdAutor = V.id)
  inner join kniha k on (k.idKnihy = n.idKnihy)
;

--view pro archiv
create view VW_archiv as
  select DatumUdalosti as kdy, (Jmeno || ' ' || Prijmeni) as jmeno_ctenare, 
  idCten as id_ctenare, Jmeno as jmeno_knihy, idKnihy as id_knihy, status as akce, poznamka
    from Archiv 
    natural join Ctenar
    natural join Kniha
;

--seznam setrizeny dle poctu pujcovani - resp. vraceni
--tedy od ctenare, ktery si toho pujcoval nejvic, po toho, ktery nejmene (ale aspon jednu)
create view VW_kdo_kolik_pujcoval as
  select count(idCten) as pocet_vraceni, (Jmeno || ' ' || Prijmeni) as jmeno_ctenare
    from Ctenar 
    natural join Archiv
    where status = 'V' --pocitame jenom ty, ktere ctenari uz vratili
    group by idCten, Jmeno, Prijmeni --nejdrive dle id (unique), dalsi jen pro radost DB
    order by pocet_vraceni desc 
;

--seznam knih s jejich prumernou znamkou
create view VW_knihy_hodnoceni as
  select avg(znamka) as prumerna_znamka, Jmeno as jmeno_knihy, isbn
    from Kniha 
    natural join Hodnoceni
    group by idKnihy, Jmeno, ISBN --nejdrive dle id (unique), dalsi jen pro radost DB
;

--top 3 nejlepe hodnocene knihy
--tedy od knihy, ktera je hodnocena nejlepe, po tu ktera nejmene (ale hodnocena aspon jednou)
create view VW_top_knihy as
  select * from 
    (select * from VW_knihy_hodnoceni 
      order by prumerna_znamka ASC)
  where rownum < 4 
;


---------------------------------------
--Statistika--------------------------
---------------------------------------

analyze TABLE archiv compute statistics;
analyze TABLE autor compute statistics;
analyze TABLE ctenar compute statistics;
analyze TABLE hodnoceni compute statistics;
analyze TABLE kniha compute statistics;
analyze TABLE nakladatelstvi compute statistics;
analyze TABLE napsal compute statistics;
analyze TABLE vypujcky compute statistics;
analyze TABLE zanr compute statistics;

---------------------------------------
--Demonstracni skript------------------
---------------------------------------

--seznam ctenaru
exec DBMS_OUTPUT.PUT_LINE('-------SEZNAM CTENARU-------');
select * from VW_seznam_ctenaru;

--seznam knih
exec DBMS_OUTPUT.PUT_LINE('-------SEZNAM KNIH-------');
select * from VW_seznam_knih;

--seznam knih
exec DBMS_OUTPUT.PUT_LINE('-------SEZNAM AUTORU-------');
select * from VW_seznam_autoru;

--seznam autor-kniha
exec DBMS_OUTPUT.PUT_LINE('-------SEZNAM AUTOR-KNIHA-------');
select * from VW_seznam_autor_kniha;

--seznam aktualne vypujcenych knih
exec DBMS_OUTPUT.PUT_LINE('-------SEZNAM AKTUALNE PUJCENYCH KNIH-------');
select * from VW_pujcene_knihy;

-------------------------------

--pridejme noveho ctenare
--parametry: jmeno, prijmeni, datum_narozeni, mesto, cislo_popisne, email
exec db_ctenar.pridej('aja','horekukajova', '14-DEC-1991','Kyjov',314, 'aja.hor@seznam.cz');

--pro dalsi praci s timto ctenarem se nam bude hodit zjistit jeho ID
--to se da provest dvema moznostma, bud se podivat do tabulky Ctenaru a prislusny radek si najit
select * from VW_seznam_ctenaru;
--nebo pomoci funkce db_ctenar.id_podle_emailu(mail), ktera na zaklade emailu (unique column), vrati ctenarovo ID
select db_ctenar.id_podle_emailu('aja.hor@seznam.cz') from dual;
--obe moznosti nam vrati ID = 5

--zkusime si vypujcit knihu, ktera uz je "rozpujcovana"
exec db_ctenar.pujc_knihu(5,1);
--ORA-20042: Vsechny exemplare jsou momentalne pujcene, danou knihu tedy nelze zapujcit.

--proto se podivame, ktere knihy jsou dostupne k pujceni
select * from vw_volne_knihy;

--a jednu z nich si půjčíme
--parametry: idCtenare, idKnihy
exec db_ctenar.pujc_knihu(5,3); 

--zkontrolujeme, ze jsme si ji opravdu pujcili
select * from VW_pujcene_knihy;

--a danou knihu vratime
--parametry: idCtenare, idKnihy
exec db_ctenar.vrat_knihu(5,3);

--zkontrolujeme, zda neni nadale evidovana ve vypujckach
select * from VW_pujcene_knihy;

--a podivame se zda, se ulozilo nase vraceni do archivu (status 'V' = vraceno)
select * from vw_archiv;

--a jelikoz chceme pomoci celkove kvalite knih knihovny, tak danou knihy zhodnotime (znamky 1-5, kde 1 je nejlepsi)
--idCtenare,idKnihy,znamka
exec db_ctenar.pridej_hodnoceni(5,3,1); 

--a podivame se, jestli se dane hodnoceni provedlo
--jelikoz jsme prvni, kdo hodnotil, tak se nam zobrazi pouze nase hodnoceni
select * from vw_knihy_hodnoceni;

-----------------------------------------------------

--dale zkusme vratit knihu nekoho, kdo si ji pujcil pred dele nez 100 dny
--takoveho tudiz prvni musime nalezt
select * from vw_seznam_hrisniku_a_knih;

--a nyni zkusme vratit jednu z knih (Josef Valtr - 2, Harry Potter - 2)
--parametry: idCtenare,idKnihy
exec db_ctenar.vrat_knihu(2,2);
--a dostanem vyjimku: ORA-20075: Dana kniha byla pujcena pred dele nez 100 dny. Pro jeji vraceni je tedy nutne pouzit proceduru 'vrat_knihu_pozde'

--musime ji tedy vratit druhou procedurou
--parametry: idCtenare,idKnihy
exec db_ctenar.vrat_knihu_pozde(2,2);

--coz uz se nam povede a muzeme si vsimnout, ze se dale do archivu ulozila informace o pozdnim vraceni
select * from vw_archiv;

--a knihu zhodnotme (knize davame znamku 2)
--parametry: idCtenare,idKnihy,znamka
exec db_ctenar.pridej_hodnoceni(2,2,2); 

--------------------------------------------------------

--dale vratme nekolik dalsich knih a po kazdem vraceni knihu zhodnotme 
--pozn. pokud bychom chteli hodnotit knihu, kterou jsme jeste nevratili (resp. jeste si ji nepujcili), tak nam databaze vyhodi prislusnou vyjimku
exec db_ctenar.vrat_knihu(2,1); 
exec db_ctenar.pridej_hodnoceni(2,1,3); 

exec db_ctenar.vrat_knihu(1,1); 
exec db_ctenar.pridej_hodnoceni(1,1,5); 

exec db_ctenar.vrat_knihu(4,5); 
exec db_ctenar.pridej_hodnoceni(4,5,2); 

exec db_ctenar.vrat_knihu_pozde(3,4); 
exec db_ctenar.pridej_hodnoceni(3,4,1); 

--nyni by meli byt vraceny vsechny knihy, o cemz se jednodusse presvedcime
select * from VW_pujcene_knihy;

--na hodnoceni jednotlivych knih (se znamkou ziskanou zprumerovanim hodnot) se podivame nasledovne
select * from vw_knihy_hodnoceni;

--a muzeme si nechat vypsat 3 knihy s nejlepsim hodnocenim
select * from VW_top_knihy;

--a muzeme se take podivat na jednoduchou tabulku rikajici nam, kdo si pujcil (resp. vratil) kolik knih
select * from VW_kdo_kolik_pujcoval;

--------------------------------------------

--dale muzeme ukazat procedury v baliccich db_kniha, db_autor, db_zanr a db_nakladatelstvi
--pridejme si tedy novy db_zanr
exec db_zanr.pridej('komedie');

--pokud bychom chteli znovu pridat stejny zanr (case insensitive)
exec db_zanr.pridej('Komedie');
--ORA-20005: Zanr s danym nazvem je uz v databazi ulozeny.

--pridejme take nove nakladatelstvi
exec db_nakladatelstvi.pridej('Evropske');

--ktere jsme ale ulozili jinak nez jsme chteli, proto si zjisteme jeho ID (podobne jako u ctenare dve moznosti) a zmenme mu jmeno
exec db_nakladatelstvi.edit(db_nakladatelstvi.id_podle_nazvu('Evropske'), 'Evropske nakladatelstvi');

--dale pridejme knihu, ktera bude mit nove pridany zanr a nakladatelstvi 
--pro demonstraci funkci pouzivam fce konvertujici nazev na ID, v praxi bude pravdepodobne jednodussi si dane ID zjistit
--parametry: isbn, jmeno, idzanru, idnakladatelstvi, pocet_knih
exec db_kniha.pridej('978-80-242-4772-4','Marťan', db_zanr.id_podle_zanru('komedie'), db_nakladatelstvi.id_podle_nazvu('Evropske nakladatelstvi'), 1);

--presvedcme se, ze se kniha opravdu pridala
select * from vw_seznam_knih;

--a jelikoz ma mit kazda kniha i nejakeho autora, tak nejakeho vytvorme
--parametry: jmeno, prijmeni, datum_narozeni
exec db_autor.pridej('Andy', 'Weir', '1-APR-1960');

--zjisteme si autorovo ID
select * from VW_seznam_autoru;

--a pridejme mu autorstvi dane knihy
--parametry: idAutora, idKnihy
exec db_autor.pridej_knihu(4, db_kniha.id_podle_isbn('978-80-242-4772-4'));

--o novem autorsvi se muzeme presvedcit
select * from VW_seznam_autor_kniha;

--na zaver muzeme provest opacny proces, a to postupne odebrani autorstvi
exec db_autor.odeber_knihu(4, db_kniha.id_podle_isbn('978-80-242-4772-4'));

--zruseni autora
exec db_autor.odeber(4);

--zruseni knihy (jelikoz ji nema nikdo aktualne pujcenou, tak si to muzeme dovolit)
exec db_kniha.odeber(db_kniha.id_podle_isbn('978-80-242-4772-4'));

--zruseni zanru
exec db_zanr.odeber(db_zanr.id_podle_zanru('komedie'));

--zruseni nakladatelstvi
exec db_nakladatelstvi.odeber(db_nakladatelstvi.id_podle_nazvu('Evropske nakladatelstvi'));

--a nakonec i ctenare Aji (jelikoz nema nic pujceneho, tak se nam to povede)
exec db_ctenar.odeber(5);


-----------------------
--Ruseni tabulek,...---
-----------------------

--dropovani statistik
analyze TABLE archiv delete statistics;
analyze TABLE autor delete statistics;
analyze TABLE ctenar delete statistics;
analyze TABLE hodnoceni delete statistics;
analyze TABLE kniha delete statistics;
analyze TABLE nakladatelstvi delete statistics;
analyze TABLE napsal delete statistics;
analyze TABLE vypujcky delete statistics;
analyze TABLE zanr delete statistics;
  
drop package db_autor;
drop package db_ctenar;
drop package db_kniha;
drop package db_zanr;
drop package db_nakladatelstvi;

--select 'drop view ' || view_name || ';' from user_views;
drop view VW_ARCHIV;                      
drop view VW_KDO_KOLIK_PUJCOVAL;          
drop view VW_KNIHY_HODNOCENI;             
drop view VW_POCET_DOST_KNIH;             
drop view VW_SEZNAM_AUTORU;               
drop view VW_SEZNAM_AUTOR_KNIHA;          
drop view VW_SEZNAM_CTENARU;              
drop view VW_SEZNAM_HRISNIKU;             
drop view VW_SEZNAM_HRISNIKU_A_KNIH;      
drop view VW_SEZNAM_KNIH;                 
drop view VW_TOP_KNIHY;                   
drop view VW_VOLNE_KNIHY; 
drop view VW_PUJCENE_KNIHY;

--select 'drop sequence ' || sequence_name || ';' from user_sequences;
drop sequence SEQ_ARCHIV_ID;
drop sequence SEQ_AUTOR_ID;
drop sequence SEQ_CTENAR_ID;
drop sequence SEQ_KNIHA_ID;
drop sequence SEQ_NAKLADATELSTVI_ID;
drop sequence SEQ_VYPUJCKY_ID;
drop sequence SEQ_ZANR_ID;

--select 'drop trigger ' || trigger_name || ';' from user_triggers;
-- drop trigger BEF_INS_VYPUJCKY_ID;            
-- drop trigger BEF_INS_VYPUJCKY;               
-- drop trigger AFT_INS_DEL_VYPUJCKY;           
-- drop trigger BEF_INS_ARCHIV_ID;              
-- drop trigger BEF_INS_AUTOR_ID;               
-- drop trigger BEF_INS_HODNOCENI;              
-- drop trigger BEF_INS_KNIHA_ID;               
-- drop trigger BEF_DEL_UPD_KNIHA;              
-- drop trigger BEF_INS_NAKLADATELSTVI_ID;      
-- drop trigger BEF_DEL_NAKLADATELSTVI;         
-- drop trigger BEF_INS_ZANR_ID;                
-- drop trigger BEF_DEL_ZANR;                   
-- drop trigger BEF_INS_CTENAR_ID;              
-- drop trigger BEF_DEL_CTENAR;                 
             
-- drop index KNIHA_ZANR_INX;                 
-- drop index KNIHA_NAKLADATELSTVI_INX;                
-- drop index NAPSAL_AUTOR_INX;               
-- drop index NAPSAL_KNIHA_INX;               
-- drop index VYPUCKY_CTENAR_INX;             
-- drop index VYPUJCKY_KNIHA_INX;             
-- drop index ARCHIV_CTENAR_INX;              
-- drop index ARCHIV_KNIHA_INX;               
-- drop index HODNOCENI_CTENAR_INX;           
-- drop index HODNOCENI_KNIHA_INX;  

--select 'drop table ' || table_name || ';' from user_tables;
drop table VYPUJCKY;
drop table NAPSAL;
drop table HODNOCENI;
drop table ARCHIV;
drop table CTENAR;
drop table KNIHA;
drop table ZANR;
drop table NAKLADATELSTVI;
drop table AUTOR;