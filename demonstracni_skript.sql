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
