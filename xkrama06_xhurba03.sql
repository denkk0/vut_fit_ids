-- SQL script to create tables and fill in few data
-- Assignment: Costume Rental
-- Author: Denis Kramár (xkrama06), Nicol Hurbánková (xhurba03)

-- NOTES
--
-- Few attributes have been edited in order to represent atomic data, e.g.:
-- address has been decomposed into street, house number, town, etc.
--
-- Two new tables have been introduced - 'produkt_z_kategorie' and 'vypozicanie_produktu',
-- due to the transformation in order to represent * to * relations.
--
-- Generalisation / specialization:
--      in case of 'zakaznik' and 'zamestnanec' entites, this has been done using the 2nd
--      type of transformation from presentation.
--
--      in case of 'doplnok' and 'kostym' entites, this has been done using the 4th
--      type of transformation from presentation.
--

DROP TABLE zakaznik CASCADE CONSTRAINTS;
DROP TABLE zamestnanec CASCADE CONSTRAINTS;
DROP TABLE produkt CASCADE CONSTRAINTS;
DROP TABLE kategoria CASCADE CONSTRAINTS;
DROP TABLE zaznam_o_vypozicani CASCADE CONSTRAINTS;
DROP TABLE produkt_z_kategorie CASCADE CONSTRAINTS;
DROP TABLE vypozicanie_produktu CASCADE CONSTRAINTS;

DROP SEQUENCE zakaznik_id_seq;

DROP TRIGGER create_ID;
DROP TRIGGER availability_status;

DROP PROCEDURE prods_in_cat;
DROP PROCEDURE notify_customer;

DROP MATERIALIZED VIEW mat_view;

CREATE TABLE zakaznik(
    id              INT DEFAULT NULL,
    meno            VARCHAR(50) NOT NULL,
    priezvisko      VARCHAR(50) NOT NULL,
    -- tel_c in format e.g. 00421 900 000 000, +421 900 000 000, 0900 000 000 - WITHOUT WHITESPACES!
    tel_c           VARCHAR(14) NOT NULL CHECK (REGEXP_LIKE(tel_c, '^[+]?[0-9]+$')),
    -- mail in standart format name@domain.com with some additional symbols
    mail            VARCHAR(50) CHECK (REGEXP_LIKE(mail, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$')),
    ulica           VARCHAR(50) NOT NULL,
    -- c_domu in format either 25894 or 248/64
    c_domu          VARCHAR(10) NOT NULL CHECK (REGEXP_LIKE(c_domu, '^[0-9]+[\/]?[0-9]+$')),
    mesto           VARCHAR(50) NOT NULL,
    -- psc has to have 5 numbers
    psc             VARCHAR(5)  NOT NULL CHECK (REGEXP_LIKE(psc, '^[0-9]{5}$')),
    stat            VARCHAR(50) NOT NULL,

    PRIMARY KEY     (id)
);

CREATE TABLE zamestnanec(
    id          INT GENERATED AS IDENTITY PRIMARY KEY,
    meno        VARCHAR(50) NOT NULL,
    priezvisko  VARCHAR(50) NOT NULL,
    -- tel_c and mail regex same as in zakaznik table
    tel_c       VARCHAR(14) NOT NULL CHECK (REGEXP_LIKE(tel_c, '^[+]?[0-9]+$')),
    mail        VARCHAR(50) NOT NULL CHECK (REGEXP_LIKE(mail, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$'))
);

CREATE TABLE produkt(
    id              INT GENERATED AS IDENTITY PRIMARY KEY,
    nazov           VARCHAR(50)  NOT NULL,
    -- check if 'velkost' fits one of the sizes named, where UNI represents 'one size fits all' e.g. in case of earrings
    velkost         VARCHAR(3)   NOT NULL CHECK (velkost in ('XS', 'S', 'M', 'L', 'XL', 'XXL', 'UNI')),
    farba           VARCHAR(20)  NOT NULL,
    vyrobca         VARCHAR(20)  NOT NULL,
    material        VARCHAR(20)  NOT NULL,
    popis           VARCHAR(255) NOT NULL,
    -- 'typ' defines generalisation / specialization with either type named
    typ             VARCHAR(7) CHECK (typ in ('doplnok', 'kostym')),
    datum_vyroby    DATE NOT NULL,
    -- 'stav' is basically a rating x/5. where 1/5 represents the worse, and 5/5 the best rating
    stav            NUMBER(1) CHECK (stav in (1, 2, 3, 4, 5)),
    -- 'dostupnost' check if item is available - 0 = false, 1 = true
    cena            NUMBER(10,2) NOT NULL CHECK (cena > 0),
    dostupnost      NUMBER(1) CHECK (dostupnost in (0, 1)),
    id_zamestnanca  INT not NULL,

    FOREIGN KEY     (id_zamestnanca) REFERENCES zamestnanec
);

CREATE TABLE kategoria(
    nazov       VARCHAR(50) PRIMARY KEY,
    prilezitost VARCHAR(50) NOT NULL
);

CREATE TABLE zaznam_o_vypozicani(
    id              INT GENERATED AS IDENTITY PRIMARY KEY,
    datum_pozicania DATE NOT NULL,
    datum_vratenia  DATE NOT NULL,
    udalost         VARCHAR(50) NOT NULL,
    -- 'cena' price with two decimal places, has to be greater than 0
    cena            NUMBER(10,2) NOT NULL CHECK (cena > 0),
    id_zamestnanca  INT NOT NULL, -- SPROSTREDKUVA
    id_zakaznika    INT NOT NULL, -- SPRAVUJE

    FOREIGN KEY     (id_zamestnanca) REFERENCES zamestnanec,
    FOREIGN KEY     (id_zakaznika) REFERENCES zakaznik
);

CREATE TABLE produkt_z_kategorie(
    id_produktu     INT NOT NULL,
    nazov_kategorie VARCHAR(50),

    PRIMARY KEY     (id_produktu, nazov_kategorie),
    FOREIGN KEY     (id_produktu) REFERENCES produkt,
    FOREIGN KEY     (nazov_kategorie) REFERENCES kategoria
);

CREATE TABLE vypozicanie_produktu(
    id_produktu     INT NOT NULL,
    id_vypozicania  INT NOT NULL,

    PRIMARY KEY     (id_produktu, id_vypozicania),
    FOREIGN KEY     (id_produktu) REFERENCES produkt,
    FOREIGN KEY     (id_vypozicania) REFERENCES zaznam_o_vypozicani
);

--------------------------------------------------------------
--   creates a sequence a numbers and sets PK of zakaznik   --
--------------------------------------------------------------
CREATE SEQUENCE zakaznik_id_seq
    START WITH 1
    INCREMENT BY 1;

CREATE OR REPLACE TRIGGER create_ID
    BEFORE INSERT ON zakaznik
    FOR EACH ROW
BEGIN
    :NEW.id := zakaznik_id_seq.nextval;
END;
/

-----------------------------------------------------------
--   sets dostupnost to be 0, when product is borrowed   --
-----------------------------------------------------------
CREATE OR REPLACE TRIGGER availability_status
    BEFORE INSERT ON vypozicanie_produktu
    FOR EACH ROW
BEGIN
    UPDATE produkt
    SET dostupnost = 0
    WHERE produkt.id = :NEW.id_produktu;
END;
/

---------------------------------------------
--   Insert values into 'zakaznik' table   --
---------------------------------------------
INSERT INTO zakaznik(meno, priezvisko, tel_c, mail, ulica, c_domu, mesto, psc, stat)
VALUES ('Denis', 'Kramar', '+421900000000', 'denisov@mail.com', 'Partizanska', '23', 'Myjava', '90701', 'Slovensko');
INSERT INTO zakaznik(meno, priezvisko, tel_c, mail, ulica, c_domu, mesto, psc, stat)
VALUES ('Nicol', 'Hurbankova', '00421900000000', 'nicin@mail.com', 'Poriadie', '381', 'Poriadie', '90721', 'Slovensko');
INSERT INTO zakaznik(meno, priezvisko, tel_c, mail, ulica, c_domu, mesto, psc, stat)
VALUES ('Jozko', 'Mrkvicka', '0900000000', 'jozkov@mail.com', 'Brestovec', '201', 'Brestovec', '90121', 'Slovensko');
INSERT INTO zakaznik(meno, priezvisko, tel_c, mail, ulica, c_domu, mesto, psc, stat)
VALUES ('Ferda', 'Mravec', '0900000000', 'ferkov@mail.com', 'Rudnik', '12/15', 'Rudnik', '90821', 'Slovensko');

------------------------------------------------
--   Insert values into 'zamestnanec' table   --
------------------------------------------------
INSERT INTO zamestnanec(meno, priezvisko, tel_c, mail)
VALUES ('Tomas', 'Zmeko', '0900000000', 'tominov@mail.com');
INSERT INTO zamestnanec(meno, priezvisko, tel_c, mail)
VALUES ('Evina', 'Jagosova', '0900000000', 'evin@mail.com');
INSERT INTO zamestnanec(meno, priezvisko, tel_c, mail)
VALUES ('Gandalf', 'the White', '0900000000', 'gandalfov@mail.com');
INSERT INTO zamestnanec(meno, priezvisko, tel_c, mail)
VALUES ('Harry', 'Potter', '0900000000', 'harry@mail.com');
INSERT INTO zamestnanec(meno, priezvisko, tel_c, mail)
VALUES ('Lukas', 'Borsuk', '0900000000', 'lukasov@mail.com');

--------------------------------------------
--   Insert values into 'produkt' table   --
--------------------------------------------
INSERT INTO produkt(nazov, velkost, farba, vyrobca, material, popis, typ, datum_vyroby, stav, cena, dostupnost, id_zamestnanca)
VALUES ('nausnice', 'UNI', 'zlate', 'netusim', 'zlato', 'okruhle nausnice', 'doplnok', TO_DATE('2020-03-26', 'YYYY-MM-DD'), 1, 5.0, 1, 1);
INSERT INTO produkt(nazov, velkost, farba, vyrobca, material, popis, typ, datum_vyroby, stav, cena, dostupnost, id_zamestnanca)
VALUES ('drakula', 'S', 'cierne', 'netusim', 'bavlna', 'kostym drakulu', 'kostym', TO_DATE('2020-02-12', 'YYYY-MM-DD'), 1, 20.0, 1, 2);
INSERT INTO produkt(nazov, velkost, farba, vyrobca, material, popis, typ, datum_vyroby, stav, cena, dostupnost, id_zamestnanca)
VALUES ('zombie', 'XL', 'zelene', 'netusim', 'polyester', 'kostym zombika', 'kostym', TO_DATE('2020-04-01', 'YYYY-MM-DD'), 1, 30.0, 1, 3);
INSERT INTO produkt(nazov, velkost, farba, vyrobca, material, popis, typ, datum_vyroby, stav, cena, dostupnost, id_zamestnanca)
VALUES ('klobuk', 'UNI', 'cierne', 'netusim', 'bavlna', 'carodejnicky klobuk', 'doplnok', TO_DATE('2020-01-08', 'YYYY-MM-DD'), 1, 7.0, 1, 4 );
INSERT INTO produkt(nazov, velkost, farba, vyrobca, material, popis, typ, datum_vyroby, stav, cena, dostupnost, id_zamestnanca)
VALUES ('zuby', 'UNI', 'biele', 'netusim', 'bioplast', 'drakulove zuby', 'doplnok', TO_DATE('2020-01-01', 'YYYY-MM-DD'), 1, 4.0, 1, 2 );

----------------------------------------------
--   Insert values into 'kategoria' table   --
----------------------------------------------
INSERT INTO kategoria(nazov, prilezitost)
VALUES ('vseobecne', 'ples');
INSERT INTO kategoria(nazov, prilezitost)
VALUES ('myticka bytost', 'halloween');

--------------------------------------------------------
--   Insert values into 'zaznam_o_vypozicani' table   --
--------------------------------------------------------
INSERT INTO zaznam_o_vypozicani(datum_pozicania, datum_vratenia, udalost, cena, id_zamestnanca, id_zakaznika)
VALUES (TO_DATE('2020-03-12', 'YYYY-MM-DD'), TO_DATE('2020-04-12', 'YYYY-MM-DD'), 'skolsky karneval', '4,5', 1, 2);
INSERT INTO zaznam_o_vypozicani(datum_pozicania, datum_vratenia, udalost, cena, id_zamestnanca, id_zakaznika)
VALUES (TO_DATE('2020-03-28', 'YYYY-MM-DD'), TO_DATE('2020-04-10', 'YYYY-MM-DD'), 'maskarny ples', '8,75', 2, 1);
-- 5 days ago
INSERT INTO zaznam_o_vypozicani(datum_pozicania, datum_vratenia, udalost, cena, id_zamestnanca, id_zakaznika)
VALUES (TO_DATE('2020-03-19', 'YYYY-MM-DD'), SYSDATE - 5, 'halloween', '4,20', 3, 3);
-- 1 day later
INSERT INTO zaznam_o_vypozicani(datum_pozicania, datum_vratenia, udalost, cena, id_zamestnanca, id_zakaznika)
VALUES (TO_DATE('2020-03-24', 'YYYY-MM-DD'), SYSDATE + 1, 'neviem no', '1,00', 4, 4);
INSERT INTO zaznam_o_vypozicani(datum_pozicania, datum_vratenia, udalost, cena, id_zamestnanca, id_zakaznika)
VALUES (TO_DATE('2020-03-14', 'YYYY-MM-DD'), TO_DATE('2020-04-20', 'YYYY-MM-DD'), 'polovnicky ples', '6,00', 3, 4);

--------------------------------------------------------
--   Insert values into 'produkt_z_kategorie' table   --
--------------------------------------------------------
INSERT INTO produkt_z_kategorie(id_produktu, nazov_kategorie)
VALUES (1, 'vseobecne');
INSERT INTO produkt_z_kategorie(id_produktu, nazov_kategorie)
VALUES (2, 'myticka bytost');
INSERT INTO produkt_z_kategorie(id_produktu, nazov_kategorie)
VALUES (3, 'myticka bytost');
INSERT INTO produkt_z_kategorie(id_produktu, nazov_kategorie)
VALUES (4, 'vseobecne');
INSERT INTO produkt_z_kategorie(id_produktu, nazov_kategorie)
VALUES (5, 'myticka bytost');

---------------------------------------------------------
--   Insert values into 'vypozicanie_produktu' table   --
---------------------------------------------------------
INSERT INTO vypozicanie_produktu(id_produktu, id_vypozicania)
VALUES(1, 1);
INSERT INTO vypozicanie_produktu(id_produktu, id_vypozicania)
VALUES(2, 2);
INSERT INTO vypozicanie_produktu(id_produktu, id_vypozicania)
VALUES(3, 3);
INSERT INTO vypozicanie_produktu(id_produktu, id_vypozicania)
VALUES(4, 4);

--------------------------------------------------------------
--   shows a number of accessories, costumes and            --
--   total number of products within category               --
--   if total number of products is 0, raise an exception   --
--------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prods_in_cat(cat_name IN VARCHAR)
AS
    number_total INT;
    number_accessories INT;
    number_costume INT;
    empty_category EXCEPTION;
    CURSOR kurzor IS
        SELECT *
        FROM produkt_z_kategorie PZD, produkt PROD
        WHERE PZD.id_produktu = PROD.id
          AND PZD.nazov_kategorie = cat_name;
BEGIN
    number_accessories := 0;
    number_costume := 0;

    FOR x IN kurzor LOOP
        IF x.typ = 'doplnok' THEN
            number_accessories := number_accessories + 1;
        END IF;

        IF x.typ = 'kostym' THEN
            number_costume := number_costume + 1;
        END IF;
    END LOOP;

    number_total := number_accessories + number_costume;

    IF number_total = 0 THEN
        RAISE empty_category;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Pocet produktov v kategorii "' ||cat_name|| '": ' ||number_total);
    DBMS_OUTPUT.PUT_LINE('Pocet doplnokv  v kategorii "' ||cat_name|| '": ' ||number_accessories);
    DBMS_OUTPUT.PUT_LINE('Pocet kostymov  v kategorii "' ||cat_name|| '": ' ||number_costume);

    EXCEPTION
        WHEN empty_category THEN
            RAISE_APPLICATION_ERROR(-20000, 'Kategoria ' ||cat_name|| ' je prazdna.');
END;
/

CALL prods_in_cat('myticka bytost');
-- CALL prods_in_cat('blabla'); -- this CALL raises exception

-------------------------------------------------------------------------------------------
--   notify a customer 5 days ahead to return a product he borrowed on time              --
--   if a customer havent returned a product, warn them the next day after return date   --
-------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE notify_customer
AS
    date zaznam_o_vypozicani.datum_pozicania%TYPE;
    CURSOR kurzor IS
        SELECT ZOV.id, ZOV.datum_vratenia, PROD.nazov
        FROM zaznam_o_vypozicani ZOV, vypozicanie_produktu VP, produkt PROD
        WHERE ZOV.id = VP.id_vypozicania
          AND VP.id_produktu = prod.id;
BEGIN
    FOR x IN kurzor LOOP
        date := x.datum_vratenia;

        IF to_char(date + 5, 'dd.mm.yyyy') = to_char(SYSDATE, 'dd.mm.yyyy') THEN
            DBMS_OUTPUT.PUT_LINE('Pripomienka k objednavke c. ' ||x.id|| '. Za 5 dni vyprsi doba vypozicania.');
        END IF;

        IF to_char(date - 1, 'dd.mm.yyyy') = to_char(SYSDATE, 'dd.mm.yyyy') THEN
            DBMS_OUTPUT.PUT_LINE('Upomienka k objednavke c. ' ||x.id|| '. Vyprsal cas vypozicania.');
        END IF;
    END LOOP;
END;
/

CALL notify_customer();

------------------------------------------
--   proof that indexing reduces cost   --
------------------------------------------
EXPLAIN PLAN FOR
    SELECT ZAM.meno, ZAM.priezvisko, COUNT(ZAM.priezvisko) AS POCET_PRODUKTOV
    FROM zamestnanec ZAM, produkt PROD
    WHERE ZAM.id = PROD.id_zamestnanca
    GROUP BY ZAM.meno, ZAM.priezvisko;
SELECT * FROM TABLE(DBMS_XPLAN.display);

CREATE INDEX index_explan ON produkt(id_zamestnanca);

EXPLAIN PLAN FOR
    SELECT ZAM.meno, ZAM.priezvisko, COUNT(ZAM.priezvisko) AS POCET_PRODUKTOV
    FROM zamestnanec ZAM, produkt PROD
    WHERE ZAM.id = PROD.id_zamestnanca
    GROUP BY ZAM.meno, ZAM.priezvisko;
SELECT * FROM TABLE(DBMS_XPLAN.display);

DROP INDEX index_explan;

---------------------------------------
--   grant permissions to xhurba03   --
---------------------------------------
GRANT ALL ON zakaznik TO XHURBA03;
GRANT ALL ON produkt TO XHURBA03;
GRANT ALL ON kategoria TO XHURBA03;
GRANT ALL ON zaznam_o_vypozicani TO XHURBA03;
GRANT ALL ON produkt_z_kategorie TO XHURBA03;
GRANT ALL ON vypozicanie_produktu TO XHURBA03;

GRANT EXECUTE ON prods_in_cat TO XHURBA03;
GRANT EXECUTE ON notify_customer TO XHURBA03;

-----------------------------------------------
--   create materialized view for xhurba03   --
-----------------------------------------------
CREATE MATERIALIZED VIEW mat_view
CACHE
BUILD IMMEDIATE
REFRESH ON COMMIT AS
    SELECT XKRAMA06.produkt.nazov AS PRODUKT, XKRAMA06.produkt.cena AS CENA
    FROM XKRAMA06.produkt
    ORDER BY XKRAMA06.produkt.nazov;

------------------------------------------------------------
--   Products that zamestnanec with id 1 takes care of   ---
------------------------------------------------------------
SELECT nazov
FROM produkt PROD, zamestnanec ZAM
WHERE PROD.id_zamestnanca = ZAM.id AND ZAM.id = 1;

------------------------------------------------------
--   Which accessories are for mythical creatures   --
------------------------------------------------------
SELECT PROD.nazov, PROD.popis
FROM produkt_z_kategorie PZK, produkt PROD
WHERE PZK.id_produktu = PROD.id
    AND PROD.typ='doplnok'
    AND nazov_kategorie='myticka bytost';

----------------------------------------------
--   Which employee has served a customer   --
----------------------------------------------
SELECT CONCAT(CONCAT(ZAM.meno, ' '),  ZAM.priezvisko) meno_zamestnanca, CONCAT(CONCAT(ZAK.meno, ' '),  ZAK.priezvisko) meno_zakaznika
FROM zaznam_o_vypozicani ZAZ, zamestnanec ZAM, zakaznik ZAK
WHERE ZAZ.id_zamestnanca = ZAM.id AND ZAZ.id_zakaznika = ZAK.id;

----------------------------------------------------------------------
--   Show sum and number of lent products of individual customers   --
----------------------------------------------------------------------
SELECT ZAK.id, ZAK.meno, ZAK.priezvisko, SUM(ZAZ.cena) SUMA_VYPOZICANI, COUNT(ZAZ.cena) POCET_VYPOZICANI
FROM zaznam_o_vypozicani ZAZ, zakaznik ZAK
WHERE ZAZ.id_zakaznika = ZAK.id
GROUP BY ZAK.id, ZAK.meno, ZAK.priezvisko
ORDER BY 1;

------------------------------------------------
--  Show number of products within category   --
------------------------------------------------
SELECT nazov_kategorie, COUNT(id_produktu)
FROM produkt_z_kategorie
GROUP BY nazov_kategorie;

------------------------------------------------------------------------------------------------
--   Which customers have borrowed a costume only for halloween, not for any other occasion   --
------------------------------------------------------------------------------------------------
SELECT meno, priezvisko
FROM zakaznik ZAK, zaznam_o_vypozicani ZAZ
WHERE ZAZ.id_zakaznika = ZAK.id
      AND ZAZ.udalost = 'halloween'
      AND NOT EXISTS(SELECT *
                 FROM zaznam_o_vypozicani ZAZ
                 WHERE ZAZ.id_zakaznika = ZAK.id
                       AND ZAZ.udalost <> 'halloween');

--------------------------------------------------------------
--   Shows employees, which dont take care of any product   --
--------------------------------------------------------------
SELECT meno, priezvisko
FROM zamestnanec
WHERE id NOT IN (SELECT ZAM.id
                  FROM zamestnanec ZAM, produkt PROD
                  WHERE ZAM.id = PROD.id_zamestnanca)