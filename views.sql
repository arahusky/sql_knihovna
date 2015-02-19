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