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