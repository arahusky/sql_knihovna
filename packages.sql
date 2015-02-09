----------------------
--Packages------------
----------------------

Create package db_kniha as
  --pridani nove knihy
  PROCEDURE pridej(
    xisbn      kniha.ISBN%type,
    xjmenoKnihy   kniha.JmenoKnihy%type,
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
    xjmenoKnihy   kniha.JmenoKnihy%type default null,
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
    xjmenoKnihy   kniha.JmenoKnihy%type,
    xidZanru  kniha.IdZanru%type,
    xIdNakl  kniha.IdNakl%type,
    xPocet kniha.Pocet%type
  )
  AS
  begin
      insert into kniha (ISBN, JmenoKnihy, IdZanru, IdNakl, Pocet)
        values (xisbn, xjmenoKnihy, xidZanru, xIdNakl, xPocet);

      DBMS_OUTPUT.PUT_LINE ('Nova kniha ' || xjmenoKnihy || ' byla uspesne pridana. Doporucujeme, co nejdrive pridat autory.');
      
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
    xjmenoKnihy   kniha.JmenoKnihy%type default null,
    xidZanru  kniha.IdZanru%type default null,
    xIdNakl  kniha.IdNakl%type default null,
    xPocet kniha.Pocet%type default null
  ) as 
 begin  
   update Kniha set
      isbn = decode(xisbn, null, isbn, xisbn),
      JmenoKnihy = decode(xjmenoKnihy, null, JmenoKnihy, xjmenoKnihy),
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
    xjmeno      ctenar.JmenoCten%type,
    xprijmeni   ctenar.PrijmeniCten%type,
    xdatumNarozeni  ctenar.DatumNarozeniCten%type,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type
  );

  --odebrani ctenare dle ID
  PROCEDURE odeber(xid ctenar.idCten%type);

  --editace ctenare
  procedure edit(
    xid   ctenar.idCten%type,
    xjmeno      ctenar.JmenoCten%type default null,
    xprijmeni   ctenar.PrijmeniCten%type default null,
    xdatumNarozeni  ctenar.DatumNarozeniCten%type default null,
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
 --EXC_datum_spatny_format EXCEPTION;

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);
 PRAGMA EXCEPTION_INIT (EXC_neexistujici_cte_kniha, -02291);

 PROCEDURE pridej(
    xjmeno      ctenar.JmenoCten%type,
    xprijmeni   ctenar.PrijmeniCten%type,
    xdatumNarozeni  ctenar.DatumNarozeniCten%type,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type
  )
  AS
  begin
      insert into ctenar (JmenoCten, PrijmeniCten, DatumNarozeniCten, Mesto, CisloPopisne, Email)
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
    --trigger se postara o to, abychom nemazali uzivatele, ktery ma neco pujceneho
 end;

 procedure edit(
    xid   ctenar.idCten%type,
    xjmeno      ctenar.JmenoCten%type default null,
    xprijmeni   ctenar.PrijmeniCten%type default null,
    xdatumNarozeni  ctenar.DatumNarozeniCten%type default null,
    xmesto  ctenar.Mesto%type default null,
    xcisloPopisne ctenar.CisloPopisne%type default null,
    xemail  ctenar.email%type default null
  ) as 
 begin  
   update Ctenar set
      JmenoCten = decode(xjmeno, null, JmenoCten, xjmeno),
      PrijmeniCten = decode(xprijmeni, null, PrijmeniCten, xprijmeni),
      DatumNarozeniCten = decode(xdatumNarozeni, null, DatumNarozeniCten, xdatumNarozeni),
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

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);

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
    --trigger se postara o to, abychom nesmazali zanr, pokud je uveden u nektere knihy
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

 PRAGMA EXCEPTION_INIT (EXC_prilis_dlouha_hodnota, -12899);
 PRAGMA EXCEPTION_INIT (EXC_porusena_unikatnost, -00001);

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
    --trigger se postara o to, abychom nesmazali nakladatelstvi, pokud je uvedeno u nektere knihy
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
    xjmenoAut      autor.JmenoAut%type,
    xprijmeniAut   autor.PrijmeniAut%type,
    xdatumNarozeniAut  autor.DatumNarozeniAut%type
  );

  --odebrani autora dle ID
  PROCEDURE odeber(xid autor.IdAutor%type);

  --editace autora
  procedure edit(
    xid   autor.IdAutor%type,
    xjmenoAut      autor.JmenoAut%type default null,
    xprijmeniAut   autor.PrijmeniAut%type default null,
    xdatumNarozeniAut  autor.DatumNarozeniAut%type default null
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
    xjmenoAut      autor.JmenoAut%type,
    xprijmeniAut   autor.PrijmeniAut%type,
    xdatumNarozeniAut  autor.DatumNarozeniAut%type
  )
  AS
  begin
      insert into autor (JmenoAut, PrijmeniAut, DatumNarozeniAut)
        values (xjmenoAut, xprijmeniAut, xdatumNarozeniAut);

      DBMS_OUTPUT.PUT_LINE ('Novy autor ' || xjmenoAut || ' ' || xprijmeniAut || ' byl uspesne pridan.');
      
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
    xjmenoAut      autor.JmenoAut%type default null,
    xprijmeniAut   autor.PrijmeniAut%type default null,
    xdatumNarozeniAut  autor.DatumNarozeniAut%type default null
  ) as 
 begin  
   update Autor set
      JmenoAut = decode(xjmenoAut, null, JmenoAut, xjmenoAut),
      PrijmeniAut = decode(xprijmeniAut, null, PrijmeniAut, xprijmeniAut),
      DatumNarozeniAut = decode(xdatumNarozeniAut, null, DatumNarozeniAut, xdatumNarozeniAut)
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