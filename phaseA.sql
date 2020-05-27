-- erwthma 3.1-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION CreateStudents__3_1(year integer, num integer)
RETURNS void AS
$BODY$
DECLARE
yearContains integer;
BEGIN
yearContains := (select count(s.amka) from "Student" s where s.entry_date=concat(year,'-09-10')::date);
WITH inst AS (
	SELECT n.name as nm, random_father_name() as fthr, adapt_surname(s.surname,n.sex) as srnm, 
	concat('s', year, lpad(nextval('"Student_email_seq"'::regclass)::text,6,'0'), '@isc.tuc.gr')::character(30) as email,
	create_am(year,n.id+yearContains) as am, concat(year,'-09-10')::date as entry
		FROM random_names(num) n NATURAL JOIN random_surnames(num) s
)

INSERT INTO "Student"(name,father_name,surname,email,am,entry_date) SELECT * FROM inst;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;
--------------------------------------------
create or replace function random_Lab_Prof(num integer)
returns table(l integer, id integer)  AS
$BODY$
BEGIN
	RETURN QUERY
	select n.lab_code,row_number() OVER ()::integer from (select lab_code from "Lab" ORDER BY random() LIMIT num)n;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;
------
create or replace function random_Rank_Prof(num integer)
returns table(r rank_type, id integer)  AS
$BODY$
BEGIN
	RETURN QUERY
	select enu.unnest,row_number() OVER ()::integer
	from
	(select n.unnest
	from((SELECT * FROM unnest(enum_range(NULL::rank_type)) ORDER BY random() LIMIT num) n
		full outer join --epeidi allios den paragei perissotera apo 4 to proto query
		(select * from "Name" limit num) asd
		on true) --epairna id apo to name kai xalouse to natural join me apotelesma diplotupa
	ORDER BY random() --stin CreateProfessors__3_1, luthike etsi
	LIMIT num) enu;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;
--select * from random_Rank_Prof(10)
-----
CREATE OR REPLACE FUNCTION CreateProfessors__3_1(num integer)
RETURNS void AS
$BODY$
BEGIN
WITH inst AS (
	SELECT n.name as nm, f.father as fthr, adapt_surname(s.surname,n.sex) as srnm, 
	concat('p', date_part('year', CURRENT_DATE), lpad(nextval('"email_Prof_seq"'::regclass)::text,6,'0'), '@isc.tuc.gr')::character(30) as email,
	lab.l as leb, rk.r as rnk
		FROM random_names(num) n NATURAL JOIN random_surnames(num) s natural join random_father_names(num) f
			natural join random_Rank_Prof(num) rk natural join random_Lab_Prof(num) lab
)

INSERT INTO "Professor" (name,father_name,surname,email,"labJoins",rank) SELECT * FROM inst;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;

--------------------------------------------
create or replace function random_Level_Lab(num integer)
returns table(r level_type, id integer)  AS
$BODY$
BEGIN
	RETURN QUERY
	select enu.unnest,row_number() OVER ()::integer
	from
	(select n.unnest
	from((SELECT * FROM unnest(enum_range(NULL::level_type)) ORDER BY random() LIMIT num) n
		full outer join --epeidi allios den paragei perissotera apo 4 to proto query
		(select * from "Name" limit num) asd
		on true) --epairna id apo to name kai xalouse to natural join me apotelesma diplotupa
	ORDER BY random() --stin CreateProfessors__3_1, luthike etsi
	LIMIT num) enu;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;
--select * from random_Level_Lab(10)
-----
CREATE OR REPLACE FUNCTION CreateLabStaffs__3_1(num integer)
RETURNS void AS
$BODY$
BEGIN
WITH inst AS (
	SELECT n.name as nm, f.father as fthr, adapt_surname(s.surname,n.sex) as srnm, 
	concat('l', date_part('year', CURRENT_DATE), lpad(nextval('"email_Prof_seq"'::regclass)::text,6,'0'), '@isc.tuc.gr')::character(30) as email,
	lab.l as leb, rk.r as rnk
		FROM random_names(num) n NATURAL JOIN random_surnames(num) s natural join random_father_names(num) f
			natural join random_Level_Lab(num) rk natural join random_Lab_Prof(num) lab
)

INSERT INTO "LabStaff" (name,father_name,surname,email,labworks,level) SELECT * FROM inst;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;

--select * from CreateStudents__3_1(2020, 15);
--select * from CreateProfessors__3_1(13);
--select * from CreateLabStaffs__3_1(5);
--            -------------------------------------------------------------------


-- erwthma 3.2-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION InsertGrades__3_2(in acYear integer, in acSeason semester_season_type)
RETURNS void as 
$BODY$
DECLARE
semestID integer;
begin 
semestID := (select semester_id from "Semester" where academic_year=acYear and academic_season=acSeason);

if semestID is null
	then RAISE EXCEPTION 'Semester Not Found.';
	else
		update "Register"   Reg
		set exam_grade = (case
					when Reg.exam_grade is null then				
						(SELECT floor(random() * 10 +1)::numeric) 				
					else Reg.exam_grade
					end)
		where Reg.course_code in (select CR.course_code from "CourseRun" CR 
			where CR.semesterrunsin=semestID and CR.serial_number=Reg.serial_number)
						   and Reg.register_status='approved';

		update "Register" Reg
 		set lab_grade= (case
                when (select R.lab_grade 
					  from "Register" R
					  where R.course_code in (select CR.course_code
											  from "CourseRun" CR 
                                              where CR.course_code= Reg.course_code) 
                       and R.amka=Reg.amka 
					   and R.lab_grade is not null
					   and R.serial_number=semestID
                       order by R.lab_grade desc limit 1) >=5
					   
                then (select R.lab_grade 
					  from "Register" R 
					  where R.course_code in (select CR.course_code 
											  from "CourseRun" CR 
                                               where CR.course_code=Reg.course_code) 
                      and R.amka=Reg.amka 
					  and R.lab_grade is not null
					  and R.serial_number=semestID
                      order by R.lab_grade desc limit 1)
					  
                else (SELECT floor(random() * 10 +1)::numeric)
                end)
 			where Reg.course_code in (select CR.course_code from "CourseRun" CR where
						   CR.semesterrunsin=semestID and CR.serial_number=Reg.serial_number) 
						   and Reg.register_status='approved';

		update "Register" Reg
		set final_grade= (case
				when((select C.lab_hours 
	  				from "Course" C 
	  				where C.course_code=Reg.course_code)<0) 
				then Reg.exam_grade
				when ((select C.lab_hours
	   				from "Course" C
	  				where C.course_code=Reg.course_code)>0
       				and ((Reg.lab_grade)<(select CR.lab_min 
							 from "CourseRun" CR
							 where CR.course_code=Reg.course_code
				             and CR.semesterrunsin=semestID
							and CR.serial_number=Reg.serial_number)))
				then 0
				when((select C.lab_hours 
	  				from "Course" C 
	  				where C.course_code=Reg.course_code)>0
					and ((Reg.exam_grade)<(select CR.exam_min 
					   from "CourseRun" CR 
					   		where CR.course_code=Reg.course_code
					   		and CR.semesterrunsin=semestID
					  		and CR.serial_number=Reg.serial_number))) 
				then Reg.exam_grade
				else
				((Reg.exam_grade *(select CR.exam_percentage 
				  		from "CourseRun" CR 
				  		where CR.course_code=Reg.course_code
				  		and CR.semesterrunsin=semestID
				 		and CR.serial_number=Reg.serial_number)) 
					+ 
				(Reg.lab_grade * (1-(select CR.exam_percentage 
					   from "CourseRun" CR 
					   where CR.course_code=Reg.course_code
				    	and CR.semesterrunsin=semestID
						and CR.serial_number=Reg.serial_number))))
				end)
				where Reg.course_code in (select CR.course_code from "CourseRun" CR where
 						   CR.semesterrunsin=semestID and CR.serial_number=Reg.serial_number)
						   and Reg.register_status='approved';
end if;
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from InsertGrades__3_2('2019','winter');
--            -------------------------------------------------------------------

-- erwthma 3.3----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION AutoFill__3_3(in cc character(7), in acYear integer, in acSeason semester_season_type)
RETURNS void as 
$BODY$
DECLARE
---to calculate things
lectHours integer;
tutHours integer;
labHours integer;
semestID integer;
---to be put into
roomID character(6);
weekD integer;
startT numeric;
endT numeric;
BEGIN
semestID  := (select semester_id from "Semester" where academic_year=acYear and academic_season=acSeason); --find semester ID
lectHours := (select lecture_hours from "Course" where course_code=cc); --find lecture Hours
tutHours  := (select tutorial_hours from "Course" where course_code=cc); --find tutorial Hours
labHours  := (select lab_hours from "Course" where course_code=cc); --find lab Hours
--gonna use recursion as shown in lab5...
create temporary table programma(weekday integer, strT numeric, enT numeric, rmI character(6));
WITH RECURSIVE Taken(wd,st,et,rm) AS (
	SELECT weekday as wd, start_time as st,end_time as et,room_id as rm
	FROM "LearningActivity" where serial_number=semestID --to programma tou sugkekrimenou eksaminou rei!
	UNION
	SELECT d.weekday as wd, r.st as anc,r.et as des,d.room_id as rm
	FROM Taken r, "LearningActivity" d
	WHERE r.et = d.end_time and r.st=d.start_time and d.serial_number=semestID
)
insert into programma(weekday, strT, enT, rmI) select * from Taken;
--stin arxi nomiza oti mporw na xrhsimopoihsw thn sxesh Taken opou thelw...
--telika xreiazetai tempTable, thusiazw xwro gia taxutita i guess..
IF NOT EXISTS( --never trust the user's input!!!
select cr.course_code from "CourseRun" cr --mhpws eis aouganos?
	where cr.semesterrunsin=semestID and cr.course_code=cc) --mporei kai na sai
	THEN
	RAISE EXCEPTION 'OUG OUG OUG';
END IF;
------------------------FIND A ROOM FOR LECTURES------------------------------------
roomID  := null;
-- prepei na vrw eleuthero xrono
	for s in 8..20-lectHours loop --gia kathe wra psakse
		for w in 1..6 loop --gia kathe mera psakse
			roomID := (select r.room_id from "Room" r where r.room_type='lecture_room' --dialekse ena domatio gia dialeksi
					  and not exists(select * from programma pr where --pou den uparxei sto programma
									pr.rmI=r.room_id and pr.weekday=w
									 and pr.strT>=s and pr.strT<=s+lectHours)
					  order by random() limit 1); --tin mera kai wres pou to psaxnw
			weekD := w;
			startT := s;
			exit when roomID is not null; --yay vrika diathesimo
		end loop;
		exit when roomID is not null; --not sure if exit breaks both nested loops
	end loop;
    endT := startT + lectHours;
	if roomID is null then RAISE EXCEPTION 'out of room bruh'; end if; --an vgw kai einai null den vrika kati
	
INSERT INTO "LearningActivity"(
room_id, weekday, start_time, end_time, activity_type, serial_number, course_code)
	VALUES (roomID, weekD, startT, endT, 'lecture', semestID, cc);
	
--oops auto den to xa skeftei... prepei na ksanaftiaxnw to programma :@
DROP TABLE programma;
create temporary table programma(weekday integer, strT numeric, enT numeric, rmI character(6));
WITH RECURSIVE Taken(wd,st,et,rm) AS (
	SELECT weekday as wd, start_time as st,end_time as et,room_id as rm
	FROM "LearningActivity" where serial_number=semestID --to programma tou sugkekrimenou eksaminou rei!
	UNION
	SELECT d.weekday as wd, r.st as anc,r.et as des,d.room_id as rm
	FROM Taken r, "LearningActivity" d
	WHERE r.et = d.end_time and r.st=d.start_time and d.serial_number=semestID
)
insert into programma(weekday, strT, enT, rmI) select * from Taken;
	
------------------------FIND A ROOM FOR TUTORIALS------------------------------------
--gia na mai sigouros
roomID := null;
-- prepei na vrw eleuthero xrono
	for s in 8..20-tutHours loop --gia kathe wra psakse
		for w in 1..6 loop --gia kathe mera psakse
			roomID := (select r.room_id from "Room" r 
					  where r.room_type='lecture_room' --dialekse ena domatio gia tutor
					  and not exists(select * from programma pr where --pou den uparxei sto programma
									pr.rmI=r.room_id and pr.weekday=w
									 and pr.strT>=s and pr.strT<=s+tutHours)
					  order by random() limit 1); --tin mera kai wres pou to psaxnw
			weekD := w;
			startT := s;
			exit when roomID is not null; --yay vrika diathesimo
		end loop;
		exit when roomID is not null; --not sure if exit breaks both nested loops
	end loop;
    endT := startT + lectHours;
	if roomID is null then RAISE EXCEPTION 'out of room bruh'; end if; --an vgw kai einai null den vrika kati
	
INSERT INTO "LearningActivity"(
room_id, weekday, start_time, end_time, activity_type, serial_number, course_code)
	VALUES (roomID, weekD, startT, endT, 'tutorial', semestID, cc);

--
DROP TABLE programma;
create temporary table programma(weekday integer, strT numeric, enT numeric, rmI character(6));
WITH RECURSIVE Taken(wd,st,et,rm) AS (
	SELECT weekday as wd, start_time as st,end_time as et,room_id as rm
	FROM "LearningActivity" where serial_number=semestID --to programma tou sugkekrimenou eksaminou rei!
	UNION
	SELECT d.weekday as wd, r.st as anc,r.et as des,d.room_id as rm
	FROM Taken r, "LearningActivity" d
	WHERE r.et = d.end_time and r.st=d.start_time and d.serial_number=semestID
)
insert into programma(weekday, strT, enT, rmI) select * from Taken;
------------------------FIND A ROOM FOR LABS------------------------------------
--gia na mai sigouros
roomID := null;
-- prepei na vrw eleuthero xrono
	for s in 8..20-labHours loop --gia kathe wra psakse
		for w in 1..6 loop --gia kathe mera psakse
			roomID := (select r.room_id from "Room" r 
					  where (r.room_type='computer_room' or r.room_type='lab_room') --dialekse ena domatio gia tutor
					  and not exists(select * from programma pr where --pou den uparxei sto programma
									pr.rmI=r.room_id and pr.weekday=w
									 and pr.strT>=s and pr.strT<=s+labHours)
					  order by random() limit 1); --tin mera kai wres pou to psaxnw
			weekD := w;
			startT := s;
			exit when roomID is not null; --yay vrika diathesimo
		end loop;
		exit when roomID is not null; --not sure if exit breaks both nested loops
	end loop;
    endT := startT + lectHours;
	if roomID is null then RAISE EXCEPTION 'out of room bruh'; end if; --an vgw kai einai null den vrika kati
	
INSERT INTO "LearningActivity"(
room_id, weekday, start_time, end_time, activity_type, serial_number, course_code)
	VALUES (roomID, weekD, startT, endT, 'lab', semestID, cc);
	
DROP TABLE programma;
--- kai twra prepei na valoume kai tous summetexonteeeeeeeessssss
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from AutoFill__3_3('ΦΥΣ 102','2019','spring');
--            ----------------------------------------------------------------------

-- erwthma 4.1----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION BiggerThan30People__4_1()
RETURNS TABLE(amka integer, name character(30), surname character(30)) AS
$BODY$
BEGIN
--pare ta room_id apo aithouses me capacity>30 kai ola ta amka tou participates me roomid auto
--natural join participates me professor kai labstaf kai print kai onoma epitheto
return query				
select r.amka, pr.name, pr.surname
	from 
	(select distinct r.amka, r.tieisai
	from "Person" r
	 --oloi apo tin sxesi person pou kanoun participate se rooms me capacity>30
		JOIN (select distinct j.amka from "Participates" j
					  	inner join "Room" r using (room_id)
			  				where r.capacity > 30) n
					ON r.amka=n.amka) r
	join
	--apo olous tous profs kai ola ta labstaff dialekse autous pou exoun matching amka
	(select p.name,p.surname,p.amka from "Professor" p
	UNION
	select l.name,l.surname,l.amka from "LabStaff" l) pr
	on pr.amka=r.amka
	order by r.amka asc;					 	
END;
$BODY$
LANGUAGE 'plpgsql';

--select * from BiggerThan30People__4_1();
--            -------------------------------------------------------------------


-- erwthma 4.2----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION OfficeHoursOfProfs__4_2()
RETURNS TABLE(surnameName character(60), course_code character(7), weekday integer, start_time numeric, end_time numeric) AS
$BODY$
BEGIN
return query
select concat(p.surname, p.name)::character(60) as surnameAndName, s.course_code, s.weekday, s.start_time, s.end_time
from "Professor" p
join
--pare ola ta activity types ap to LA pou einai office_hours
(select j.course_code, j.weekday, j.start_time, j.end_time, f.amka
	from "LearningActivity" j
 	natural join "Participates" f
 		where j.activity_type = 'office_hours') s
	--kai dialekse kathigites pou exoun kanei participate se auta ta LA
	on p.amka = s.amka and
	--kai vevaiwsou pws to course_code anikei sto trexon eksamino
	--an den baloume to 'and exists' tote uparxei ki allo mathima
		exists (
			SELECT st.course_code
				FROM "Course" st NATURAL JOIN "Semester" E NATURAL JOIN "CourseRun" Cr
				WHERE E.semester_status='present' and Cr.semesterrunsin=E.semester_id 
					and st.course_code=s.course_code)
order by surnameAndName asc;
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from OfficeHoursOfProfs__4_2();
--            -------------------------------------------------------------------


-- erwthma 4.3----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION MaxGrade__4_3(in acYear integer, in acSeason semester_season_type, in gradeType text)
RETURNS TABLE(course_code CHARACTER(7), grade numeric) AS
$BODY$
declare
sem integer;
BEGIN
--pare to semester ID apo ta input
sem := (select semester_id from "Semester" where academic_year=acYear and academic_season=acSeason);
if sem is null
	--an einai null peta exception
	then RAISE EXCEPTION 'Semester Not Found.';
	else
	--an thelo exam grade
	if gradeType='exam_grade'
		then
		--tha epistrepsw
		return query
		--ta course code tou register
		select c1.course_code, max(c1.exam_grade) as gr
	  		from "Register" c1 
			--pou uparxoun sto courseRun me to sugkekrimeno semester ID
			where exists (
					select c2.course_code
						from "CourseRun" c2
						where c2.semesterrunsin=sem
						and c1.course_code=c2.course_code)
			--kai den tha deiksw ta null epidi mou tin spane
			  and c1.exam_grade is not null
	  	group by c1.course_code
	  	order by gr desc;
	
	elsif gradeType='final_grade'
	then
	--omoia me exam_grade
		return query
		select c1.course_code, max(c1.final_grade) as gr
	  	from "Register" c1 
		where exists (
					select c2.course_code
						from "CourseRun" c2
						where c2.semesterrunsin=sem
						and c1.course_code=c2.course_code)
			  and c1.final_grade is not null
	  	group by c1.course_code
	  	order by gr desc;
	
	elsif gradeType='lab_grade'
	then
	--omoia me exam_grade
		return query
		select c1.course_code, max(c1.lab_grade) as gr
	  	from "Register" c1 
		where exists (
					select c2.course_code
						from "CourseRun" c2
						where c2.semesterrunsin=sem
						and c1.course_code=c2.course_code)
			  and c1.lab_grade is not null
	  	group by c1.course_code
	  	order by gr desc;
	else
	--an evala allo text eimai gaoumpiou
		RAISE EXCEPTION 'Accepted text is "exam_grade","final_grade","lab_grade".';
	end if;
end if;
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from MaxGrade__4_3('2020','spring','final_grade')
--            -------------------------------------------------------------------


-- erwthma 4.4----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ParticipatesInPCRoom__4_4()
RETURNS TABLE(am character(10), entry_date date) AS
$BODY$
DECLARE
curSem integer;
BEGIN
--poio eksamino einai present??
curSem := (select semester_id from "Semester" where semester_status='present');

return query
--epestrepse tous foitites me natural join (sto amka diladi)
select stud.am, stud.entry_date from "Student" stud
natural join
--me auto to subquery pou epistrefei ola ta matching amka
(select distinct j.amka from "Participates" j
 --gia kathe participant se ena learning activity, opou
					  	inner join "LearningActivity" r using (room_id)
 							--to roomID tou LA deixnei se aithousa typou computer_room
			  				where exists(
								select ro.room_id from "Room" ro
								where ro.room_type = 'computer_room'
								and ro.room_id=r.room_id)
 							and
 							--Kai to course_code tou LA einai kai auto sto trexon eksamino
							exists (
								select cr.course_code 
								from "CourseRun" cr 
								where cr.semesterrunsin=curSem
								and cr.course_code=r.course_code)) x;
							
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from ParticipatesInPCRoom__4_4();
--            -------------------------------------------------------------------


-- erwthma 4.5----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION NoonHours__4_5()
RETURNS TABLE(course_code character(7), is_True character(3)) AS
$BODY$
BEGIN
RETURN QUERY
--epestrepse to course_code tou subquery
SELECT distinct C.course_code ,
        case --an to megisto end_time teleiwnei prin tis 4 to mesimeri (16)
			when Z.end_time is null or Z.end_time < 16 
		then 'OXI'::character(3)	--epestrepse oxi
		else 'NAI'::character(3)	--allios epestrepse nai	
		end as stat
FROM "Course" C left outer join --left outer gia na parw kai auta pou den exoun LA
(select C1.course_code ,max(L1.end_time) as end_time
		from "Course" C1  NATURAL JOIN "LearningActivity" L1 --natural join, dhladh sto course_code
				where L1.course_code=C1.course_code and C1.obligatory --kai to course einai upoxrewtiko
	group by C1.course_code) Z
on C.course_code=Z.course_code
order by stat asc;
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from NoonHours__4_5()
--            -------------------------------------------------------------------


-- erwthma 4.6----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ObligatoryWithoutLabRoom__4_6()
RETURNS TABLE(course_code character(7), course_title character(100)) AS
$BODY$
DECLARE
curSem integer;
BEGIN
--to TREXON eksamhno reeeei
curSem := (select semester_id from "Semester" where semester_status='present');
return query
--to subquery exei tin leitourgikotita kai epistrefei course_code opote to kanw natural join me to Course
--gia na epistrepsw kai to course title. An balw to sub na epistrefei kai course title den mporw na xrhsimopoihsw
--tis sunartiseis exists kai except
select sub.course_code, dom.course_title from "Course" dom natural join
(select c1.course_code
 --gia kathe mathima pou
	from "Course" c1 where
 --einai upoxrewtiko
	c1.obligatory and
 --kai exei timi sto labuses
	exists (
		select c2.course_code
			from "CourseRun" c2
			where c2.labuses is not null
			and c2.semesterrunsin = curSem
			and c2.course_code=c1.course_code
	) except (
 --kai den xrhsimopoiei aithousa typou labroom
		select l.course_code from "LearningActivity" l
				inner join "Room" r using (room_id)
			  	where r.room_type = 'lab_room')) sub;
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from ObligatoryWithoutLabRoom__4_6();
--            -------------------------------------------------------------------


-- erwthma 4.7----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LabAssistantsTotal__4_7()
RETURNS TABLE(amka integer, surname character(30), name character(30), totalHours integer) AS
$BODY$
DECLARE
curSem integer;
BEGIN
--to TREXON eksamhno reeeei
curSem := (select semester_id from "Semester" where semester_status='present');

return query
--pare olous tous labstaf me left outer sto subquery gia na tous emfanisei olous.
--(coalesce gia na kanei ta null mhdenika)
select l.amka, l.surname, l.name, COALESCE(sub.time,0)::integer as total_hours from "LabStaff" l
left outer join (select part.amka, sum(part.end_time-part.start_time) as time --pare to amka kai to athroisma wrwn
				 from "Participates" part --olwn ton participates
				 where part.amka > 29999 --pou exoun amka 30000+ dhl LabStaff
				 and part.serial_number = cursem --auto einai simantiko pio prin den to elegxa
				 and exists(
					 --kai to participate_LA_foreignKey kanei match sto LA
				 	select room_id from "LearningActivity" la
					 where la.serial_number = curSem --tou torinou eksaminou
					 and la.room_id=part.room_id and la.weekday=part.weekday and la.start_time=part.start_time 
					 and la.end_time=part.end_time and la.course_code=part.course_code
					 group by room_id
				 )
				 group by part.amka) sub
on l.amka=sub.amka
order by total_hours desc;

END;
$BODY$
LANGUAGE 'plpgsql';
--select * from LabAssistantsTotal__4_7();
--            -------------------------------------------------------------------


-- erwthma 4.8----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION MostUsedRoom__4_8()
RETURNS TABLE(room_id character(6)) AS
$BODY$
BEGIN
--isws oxi tos efficient thelei review
return query	
select r.room_id
	from "Room" r 
	join(
		select distinct l.room_id,count(distinct d.course_code) as c1 from "LearningActivity" l
		join
		(select distinct v.course_code,v.room_id from "LearningActivity" v) d
	on l.room_id=d.room_id
	group by l.room_id) tot
on tot.room_id=r.room_id
group by r.room_id, tot.c1
having tot.c1 = (select max(tot.c1)
				from "Room" r 
				join(
					select distinct l.room_id,count(distinct d.course_code) as c1 from "LearningActivity" l
					join
						(select distinct v.course_code,v.room_id from "LearningActivity" v) d
						on l.room_id=d.room_id
						group by l.room_id) tot
				on tot.room_id=r.room_id);
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from MostUsedRoom__4_8();
--            ----------------------------------------------------------------------

-- erwthma 4.9----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION totalTime__4_9()
RETURNS TABLE(id_of_ROOM character(6),week_day integer,time_start numeric,time_end numeric) AS
$BODY$
BEGIN
create temporary table programma(weekD integer, strT numeric, enT numeric, rmI character(6));
WITH RECURSIVE Taken(wd,st,et,rm) AS (
	SELECT weekday as wd, start_time as st,end_time as et,room_id as rm
	FROM "LearningActivity" --gia opoiodhpote eksamino!
	UNION
	SELECT d.weekday as wd, r.st as anc,r.et as des,d.room_id as rm
	FROM Taken r, "LearningActivity" d
	WHERE r.et = d.end_time and r.st=d.start_time
)
insert into programma(weekD, strT, enT, rmI) select * from Taken;
return query
select rmI as room_id, weekD as weekday, min(strT) as ms, max(enT) as me
from programma pr group by pr.rmI, pr.weekD, pr.strT, pr. enT
having max(pr.enT)-min(pr.strT) >= (select max(s.me-s.ms) from (
	select min(j.strT) as ms, max(j.enT) as me
from programma j where j.rmI=pr.rmI) s);
drop table programma;
END;
$BODY$
LANGUAGE 'plpgsql';
--select * from totalTime__4_9();
--            ----------------------------------------------------------------------
-- erwthma 4.10---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rangeCapacity__4_10(in minC integer,in maxC integer)
RETURNS TABLE(amka integer) AS
$BODY$
BEGIN
if maxC < minC
	then RAISE EXCEPTION 'minC is greater than maxC';
	else
	return query
	select per.amka from "Person" per --ola ta amka pou kanoun match to subquery ki einai 'Professor'
		natural join (select distinct part.amka from "Participates" part --subquery ola ta amka ap to participates
						natural join (select l.* from "LearningActivity" l natural join "Room" r --pou exoun LearnAct
							where r.capacity < maxC and r.capacity > minC) ler) f --pou to room exei to capacity pou thelw
		where per.tieisai='Professor';
end if;
END;
$BODY$
LANGUAGE 'plpgsql';
--            ----------------------------------------------------------------------
-- erwthma 6.1----------------------------------------------------------------------
create or replace view student_view__6_1 as
select cr.course_code, cr.semesterrunsin, count(r.lab_grade) from "CourseRun" cr
join (select course_code, serial_number, lab_grade from "Register" where lab_grade > 8) r
on cr.course_code=r.course_code and cr.semesterrunsin=r.serial_number
group by cr.course_code, cr.semesterrunsin;
--select * from student_view__6_1;
--            ----------------------------------------------------------------------

-- erwthma 6.2----------------------------------------------------------------------
create or replace view weekly_view__6_2 as
select concat(pr.name, pr.surname) as fullName, tab.wd as weekday,
tab.st as startTime, tab.et as endTime, tab.rm as roomID, tab.cc as courseCode
from "Professor" pr
join
(WITH RECURSIVE Taken(wd,st,et,rm,cc) AS ( --apo dw kai katw einai to zoumi, epistrefetai to programma me to amka
	SELECT weekday as wd, start_time as st,end_time as et,room_id as rm,  course_code as cc
	FROM "LearningActivity" where serial_number=(select semester_id from "Semester" where semester_status='present')
	UNION --opws thn anadromh ths 3.3
	SELECT d.weekday as wd, r.st as anc,r.et as des,d.room_id as rm,  d.course_code as cc
	FROM Taken r, "LearningActivity" d
	WHERE r.et = d.end_time and r.st=d.start_time and d.serial_number=(select semester_id from "Semester" where semester_status='present')
) --this relation returns a table of all taken rooms for every activity!
select distinct ta.*, cr.amka_prof1 from "CourseRun" cr 
join
(select distinct * from Taken) ta
on ta.cc=cr.course_code
where cr.semesterrunsin=(select semester_id from "Semester" where semester_status='present'))tab
on pr.amka=tab.amka_prof1;
--select * from weekly_view__6_2;
--            ----------------------------------------------------------------------
