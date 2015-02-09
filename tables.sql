-----------------------------------------
--Definice tabulek a prislusnych indexu--
-----------------------------------------

--Tabulka Ctenar obsahujici jednotlive ctenare registrovane v knihovne
create table Ctenar(
  IdCten numeric(7,0),
  JmenoCten varchar2(50) not null,
  PrijmeniCten varchar2(50) not null,
  DatumNarozeniCten date not null,
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
	JmenoKnihy varchar2(50) not null,
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
	JmenoAut varchar2(50) not null,
 	PrijmeniAut varchar2(50) not null,
 	DatumNarozeniAut date not null,
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
create index Napsal_Autor_INX on Napsal(IdAutor);
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
create index Hodnoceni_Ctenar_INX on Hodnoceni(IdCten);
create index Hodnoceni_Kniha_INX on Hodnoceni(IdKnihy);
