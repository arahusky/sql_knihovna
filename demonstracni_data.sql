---------------------------------------
--Vlozeni demonstracnich dat-----------
---------------------------------------

insert into Zanr (NazevZanru) values ('sci-fi');
insert into Zanr (NazevZanru) values ('fantasy');
insert into Zanr (NazevZanru) values ('detektivka');

insert into Nakladatelstvi (NazevNakl) values ('Euromedia Group - Knižní klub');
insert into Nakladatelstvi (NazevNakl) values ('Albatros');
insert into Nakladatelstvi (NazevNakl) values ('Kniha Zlín');

insert into Kniha (ISBN, JmenoKnihy, IdZanru, IdNakl, Pocet) 
  values ('978-80-242-4682-6', 'Nástroje smrti 6: Město nebeského ohně', 2, 1, 2);

insert into Kniha (ISBN, JmenoKnihy, IdZanru, IdNakl, Pocet) 
  values ('978-80-00-02756-2', 'Harry Potter a kámen mudrců', 2, 2, 1);

insert into Kniha (ISBN, JmenoKnihy, IdZanru, IdNakl, Pocet) 
  values ('80-00-01197-2', 'Harry Potter a Tajemná komnata', 2, 2, 1);

insert into Kniha (ISBN, JmenoKnihy, IdZanru, IdNakl, Pocet) 
  values ('978-80-87497-45-6', 'Sněhulák', 3, 3, 2);

insert into Kniha (ISBN, JmenoKnihy, IdZanru, IdNakl, Pocet) 
  values ('978-80-87497-01-2', 'Nemesis', 3, 3, 1);

insert into autor (JmenoAut, PrijmeniAut, DatumNarozeniAut) 
  values ('Cassandra', 'Clareová', '27-JUL-1973');
insert into autor (JmenoAut, PrijmeniAut, DatumNarozeniAut) 
  values ('Joanne', 'Rowlingová', '31-JUL-1965');
insert into autor (JmenoAut, PrijmeniAut, DatumNarozeniAut) 
  values ('Jo', 'Nesbø', '29-MAR-1960');

insert into napsal (IdAutor, IdKnihy) values (1, 1);
insert into napsal (IdAutor, IdKnihy) values (2, 2);
insert into napsal (IdAutor, IdKnihy) values (2, 3);
insert into napsal (IdAutor, IdKnihy) values (3, 4);
insert into napsal (IdAutor, IdKnihy) values (3, 5);

insert into Ctenar (JmenoCten, PrijmeniCten, DatumNarozeniCten, Mesto, CisloPopisne, Email)
  values ('Jakub', 'Naplava', '03-Mar-1993', 'Osvetimany', 378, 'arahusky@seznam.cz');

insert into Ctenar (JmenoCten, PrijmeniCten, DatumNarozeniCten, Mesto, CisloPopisne, Email)
  values ('Josef', 'Valtr', '01-JUN-2000', 'Praha', 123, 'pepa.valtr@google.com');

insert into Ctenar (JmenoCten, PrijmeniCten, DatumNarozeniCten, Mesto, CisloPopisne, Email)
  values ('Jana', 'Novotna', '24-DEC-1967', 'Uherské Hradiště', 4352, 'jana.novotna@google.com');

insert into Ctenar (JmenoCten, PrijmeniCten, DatumNarozeniCten, Mesto, CisloPopisne, Email)
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
