CREATE OR REPLACE FUNCTION public.insert_student_1_1(
	reg_num integer,
	entry_date date)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

BEGIN
FOR i in 1..reg_num LOOP 
	INSERT INTO "Student" (
							SELECT A.amka amka, N.name as name, F.name father_name,(case when N.sex='M' then S.surname else S.f_surname end) surname, E.email email, M.am, $2 entry_date
							FROM
											(SELECT name,sex
											FROM "Name"
											ORDER BY random() 
											LIMIT 1) N,

											(SELECT Z.surname surname, (case when (RIGHT(Z.trimmed, 1)='Ο') then Z.trimmed ||'Υ' else Z.trimmed end) as f_surname
											FROM(
												 SELECT surname, TRIM(TRAILING  'Σ' FROM surname) trimmed
												 FROM "Surname"
												 ORDER BY random() 
												 LIMIT 1) Z) S,

											(SELECT name
											FROM "Name"
											WHERE sex='M'
											ORDER BY random() 
											LIMIT 1) F,

											(SELECT A.max+1 amka
											FROM(
												 SELECT MAX(amka) max
												 FROM "Student") A) A,

											(SELECT 's'||((Y."year"*1000000)+A.amka)||'@isc.tuc.gr' email
											FROM (SELECT MAX(amka)+1 AS amka
												 FROM "Student") A,
												 (SELECT EXTRACT(year FROM $2) AS "year") Y) E,

											(SELECT (max(am)::integer+1)::CHARACTER(10) AS am
											FROM "Student" S
											WHERE S.am LIKE concat((SELECT EXTRACT(year FROM $2)),'%') ) M
		
	);
END LOOP;	
END; 
$BODY$;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InsertGrades12(in sem1 integer)
returns void as $$

begin 

UPDATE "Register" 
SET exam_grade=(select random() * 9 + 1) :: integer
FROM( 
	 	SELECT DISTINCT R.course_code cc, R.amka ak, R.serial_number sr
		FROM "CourseRun" L, "Register" R
		WHERE L.semesterrunsin= (SELECT Z.semester_id from "Semester" Z where semester_id=sem1) 
											and R.serial_number=L.serial_number and R.course_code=L.course_code 
													  	and R.register_status='approved') W
where W.cc=course_code and W.ak=amka and W.sr= serial_number and serial_number=sem1;

UPDATE "Register"
SET lab_grade=(select random() * 9 + 1) :: integer
FROM(
	SELECT DISTINCT R.course_code cc, R.amka ak, R.serial_number sr
		FROM "CourseRun" L, "Register" R
		WHERE L.semesterrunsin= (SELECT Z.semester_id from "Semester" Z where Z.semester_id=sem1) 
											and R.serial_number=L.serial_number and R.course_code=L.course_code 
													 and R.register_status='approved' and (L.labuses is not null)) W
where W.cc=course_code and W.ak=amka and W.sr= serial_number;

UPDATE "Register"
SET final_grade= (case 
				  when lab_grade is null then exam_grade
				  else ((B.exam_percentage * exam_grade) + ((1 - B.exam_percentage) * lab_grade))
				  end)
FROM(
	select DISTINCT R.course_code as cc,R.amka as ak,L.exam_percentage
		from "CourseRun" L , "Register" R 
				where L.semesterrunsin= (SELECT Z.semester_id from "Semester" Z where Z.semester_id=sem1)
												and R.serial_number=L.serial_number and R.course_code=L.course_code 
													 and R.register_status='approved') B 
where amka=B.ak and course_code=B.cc and serial_number=sem1;

end;
$$
LANGUAGE 'plpgsql';
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.search_professor_21(IN lab_id integer)
  RETURNS TABLE(name character, surname character, amka integer) AS
$BODY$
BEGIN
RETURN QUERY
SELECT p.name,p.surname,p.amka
FROM   "Professor" p WHERE p.labjoins= lab_id
UNION
SELECT l.name,l.surname,l.amka
FROM   "LabStaff" l WHERE l.labworks=lab_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    CREATE OR REPLACE FUNCTION find_student22(
  in amka1 integer, 
  type_grade varchar
  )
returns table(course_title character (30), grade numeric)
AS $$
BEGIN

RETURN QUERY
SELECT DISTINCT S.course_title,

		case
			when type_grade = 'exam_grade' then F.exam_grade
	        when type_grade = 'lab_grade'  then F.lab_grade
		    else F.final_grade
		end
FROM "Course" S NATURAL JOIN "Register" F  NATURAL JOIN "Semester" E NATURAL JOIN "CourseRun" Cr
WHERE E.semester_status='present' and F.amka=amka1 and Cr.semesterrunsin=E.semester_id ;
END;
$$
LANGUAGE 'plpgsql' STABLE;
---------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.am_date_23(
        )
		returns table (am character(10),entry_date date)
AS $$
BEGIN
RETURN QUERY
SELECT DISTINCT S.am, S.entry_date
	
FROM "Student" S  NATURAL JOIN "Register" R NATURAL JOIN "Semester" E NATURAL JOIN "Course" C NATURAL JOIN "CourseRun" Cr
WHERE E.semester_status='present' and R.amka=S.amka and R.course_code= Cr.course_code and Cr.course_code= C.course_code and C.obligatory='false' and Cr.semesterrunsin=E.semester_id;
END;
$$
LANGUAGE 'plpgsql' STABLE;
---------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pass24(in am1 character)
RETURNS TABLE (code character, done text)
AS

$$
BEGIN
RETURN QUERY
SELECT distinct C.course_code ,
        case 
			when Z.code is Null then 'OXI'
		else
			'NAI'
				
				
		end
FROM "Course" C Left outer  JOIN  ( SELECT C1.course_code as code
	
				from	 "Student" S NATURAL JOIN "Course" C1  NATURAL JOIN "Register" R1
				where  am1=S.am and S.amka=R1.amka and R1.course_code=C1.course_code and  c1.obligatory='TRUE' and R1.register_status='pass'   ) Z 
on C.course_code=Z.code
where C.obligatory='true';
END;
$$
LANGUAGE 'plpgsql' STABLE;
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.choice25()
RETURNS TABLE (code character(7),course_title character (100))
AS
$$
BEGIN

RETURN QUERY
SELECT Z.course_code,Z.course_title
From
(select C.course_code,C.course_title
	FROM "Course" C NATURAL JOIN "Semester" E												
where C.obligatory='false'  and E.semester_status='present' and E.academic_season=C.typical_season) Z
WHERE Z.course_code not in (SELECT CR.course_code 
						   from "CourseRun" CR NATURAL JOIN "Semester" S1
						   where S1.semester_id=CR.semesterrunsin and S1.semester_status='present');
END;
$$
LANGUAGE 'plpgsql';			
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_most_proff_26()
Returns Table(amka integer, email character(30))
AS $$
Begin
RETURN QUERY 
	SELECT P.amka, P.email
	FROM (Select P1.amka ,count(p1.amka) as maxcnt
		  FROM   "CourseRun" CR NATURAL JOIN "Semester" S NATURAL JOIN "Professor" P1
		  WHERE P1.amka=CR.amka_prof1 or P1.amka=CR.amka_prof2 and CR.semesterrunsin=S.semester_id and S.semester_status='past'
											 GROUP BY P1.amka )tmp NATURAL JOIN "Professor" P
	WHERE tmp.amka=P.amka and tmp.maxcnt=(SELECT MAX(L3.cnt)
			                			  FROM (SELECT P2.amka, count(P2.amka) as cnt
								 		  FROM "CourseRun" CR2,"Professor" P2, "Semester" S2
								 		  WHERE P2.amka=CR2.amka_prof1 or P2.amka= CR2.amka_prof2 and CR2.semesterrunsin=S2.semester_id and S2.semester_status='past'
								 		  GROUP BY P2.amka) L3);
end;						   
$$						 							
LANGUAGE plpgsql VOLATILE	
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.passpercent27(in year1 integer,season1 semester_season_type)
RETURNS TABLE (course_code character,success_per real)
as $$
BEGIN 
RETURN QUERY
			Select  P1.course_code,(case 
				   		when P2.count_participation=0 then 0::REAL 
						else ( round((((P1.count_pass)::REAL / (P2.count_participation)::REAL)::numeric),2) )
						end) AS success_per 
				from (SELECT Cr.course_code,sum(case when R.final_grade>=8.5 then 1 else 0 end) as count_pass

			 FROM "Semester" S NATURAL JOIN "CourseRun" Cr  NATURAL JOIN "Register" R
			 WHERE  Cr.semesterrunsin = S.semester_id   and S.academic_season=season1 and S.academic_year=year1  and Cr.serial_number=R.serial_number
		  	GROUP BY Cr.course_code) as P1,
		
		(SELECT Cr.course_code,sum(case when R.register_status='pass' then 1 else 0 end) as count_participation

			 FROM "Semester" S NATURAL JOIN "CourseRun" Cr  NATURAL JOIN "Register" R
			 WHERE  Cr.semesterrunsin = S.semester_id   and S.academic_season=season1 and S.academic_year=year1  and Cr.serial_number=R.serial_number
		  	GROUP BY Cr.course_code) AS P2
				
	WHERE P1.course_code=P2.course_code; 
END; 

$$
LANGUAGE 'plpgsql';	
----------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.hours28(in am1 character)
RETURNS TABLE(hours bigint)
as $$
Begin 
Return Query
	Select sum(C.lab_hours) +sum(C.lecture_hours)+sum(C.tutorial_hours) 
	From "Course" C NATURAL JOIN "CourseRun" CR NATURAL JOIN "Semester" S NATURAL JOIN "Student" St NATURAL JOIN "Register" R
	where am1=St.am and St.amka=R.amka and  R.course_code=C.course_code and C.course_code=Cr.course_code and CR.semesterrunsin=S.semester_id and S.semester_status='present'  ;
	
END;
$$
LANGUAGE 'plpgsql' STABLE;
--------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_semester_3_1()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF 
AS $BODY$

BEGIN

	IF (TG_OP = 'UPDATE') THEN
		IF(
			SELECT DISTINCT C.check
			FROM 
				(SELECT (S1.start_date, S1.end_date) OVERLAPS (NEW.start_date, NEW.end_date) as check
				FROM "Semester" S1
				WHERE S1.semester_id<>OLD.semester_id) as C
			WHERE C.check = true
			UNION
			SELECT DISTINCT C.check
			FROM 
				(SELECT (CASE WHEN NEW.semester_status='past' and (S1.semester_status='present' or S1.semester_status='future')
								THEN NEW.end_date>S1.start_date
							WHEN NEW.semester_status='present' and S1.semester_status='present' THEN TRUE
							WHEN NEW.semester_status='present' and S1.semester_status='past'
								THEN NEW.start_date < S1.end_date
							WHEN NEW.semester_status='present' and S1.semester_status='future'
								THEN NEW.end_date > S1.start_date
							WHEN NEW.semester_status='future' and (S1.semester_status='past' or S1.semester_status='present')
								THEN NEW.start_date<S1.end_date END) as check
				FROM "Semester" S1
				WHERE S1.semester_id<>OLD.semester_id) as C
			WHERE C.check = true) THEN
			
			RETURN NULL;
		ELSE
			RETURN NEW;
		END IF;

	ELSIF (TG_OP = 'INSERT') THEN
		IF (
			SELECT DISTINCT C.check
			FROM 
				(SELECT (S1.start_date, S1.end_date) OVERLAPS (NEW.start_date, NEW.end_date) as check
				FROM "Semester" S1) as C
			WHERE C.check = true
			UNION
			SELECT DISTINCT C.check
			FROM 
				(SELECT (CASE WHEN NEW.semester_status='past' and (S1.semester_status='present' or S1.semester_status='future')
								THEN NEW.end_date>S1.start_date
							WHEN NEW.semester_status='present' and S1.semester_status='present' THEN TRUE
							WHEN NEW.semester_status='present' and S1.semester_status='past'
								THEN NEW.start_date < S1.end_date
							WHEN NEW.semester_status='present' and S1.semester_status='future'
								THEN NEW.end_date > S1.start_date
							WHEN NEW.semester_status='future' and (S1.semester_status='past' or S1.semester_status='present')
								THEN NEW.start_date<S1.end_date END) as check
				FROM "Semester" S1) as C
			WHERE C.check = true) THEN
			RETURN NULL;
		ELSE
			RETURN NEW;
		END IF;
	END IF;

END; 
$BODY$;
--------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_final_grade32()
RETURNS TRIGGER
AS $$
BEGIN
	
IF (old.lab_grade<>new.lab_grade or old.exam_grade<>new.exam_grade or (old.lab_grade is NULL and new.lab_grade is not NULL) or (old.exam_grade is NULL and new.exam_grade is not NULL)       ) THEN
		UPDATE "Register" 
		SET final_grade = (CASE WHEN (R2.ep1=1 OR R2.eg1<R2.em1) THEN R2.eg1
						    WHEN R2.lg1<R2.lm1 THEN 0 ELSE
							(R2.eg1*R2.ep1)+((1-R2.ep1)*R2.lg1) END), exam_grade= (CASE WHEN R2.lg1<R2.lm1 THEN 0 ELSE R2.eg1 END)
		FROM(
											SELECT DISTINCT R.amka as amka1, R.course_code as cc1, R.serial_number as sn1, R.exam_grade as eg1, R.lab_grade as lg1, Cr.exam_percentage as ep1, Cr.exam_min as em1, Cr.lab_min as lm1
											FROM "Register" R, "CourseRun" Cr, "Semester" S
											WHERE S.semester_status='present' and Cr.serial_number=S.semester_id and R.serial_number=Cr.serial_number and R.course_code=Cr.course_code and R.final_grade IS NULL and R.register_status='approved'
											ORDER BY R.amka
		) as R2
		WHERE amka = R2.amka1 and course_code = R2.cc1 and serial_number = R2.sn1;

		UPDATE "Register" 
		SET register_status= (CASE WHEN R2.fg1>=5 THEN 'pass' ELSE 'fail' END)::register_status_type
		FROM(
			SELECT DISTINCT R.amka as amka1, R.course_code as cc1, R.serial_number as sn1, R.final_grade as fg1
			FROM "Register" R, "CourseRun" Cr, "Semester" S
			WHERE S.semester_status='present' and Cr.serial_number=S.semester_id and R.serial_number=Cr.serial_number and R.course_code=Cr.course_code and R.final_grade IS NOT NULL and R.register_status='approved'
			ORDER BY R.amka
		) as R2
		WHERE amka = R2.amka1 and course_code = R2.cc1 and serial_number = R2.sn1;
	END IF;
	RETURN NEW;
END; 

$$
LANGUAGE 'plpgsql'
--------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.UpdateSemester33()
returns trigger 
as $$
begin
if(new.semester_id<>old.semester_id or old.semester_id is NULL) then
	UPDATE "Semester" 
 	set academic_season=(case
  							when old.academic_season='spring'then 'winter' 
							else 'spring'
					 end);
	if (new.academic_season='winter') then 
		 
		 new.academic_year=old.academic_year+1;

		end if;

end if;



end
$$
LANGUAGE 'plpgsql';
----------------------------------------------------------------------------------------------------------------------
CREATE or replace FUNCTION public.check_courses_3_4()
    RETURNS trigger
  
AS $BODY$

BEGIN

	IF (OLD.register_status='requested' or (old.register_status='proposed' and new.register_status='requested')) THEN
		IF(
			(SELECT COUNT(*)>=6
			FROM "Register" R
			WHERE OLD.amka=R.amka and R.register_status='approved')
				OR
			(SELECT SUM(foo.units)>20
			FROM 
				(SELECT C1.units as units
				FROM "Register" R1, "Course" C1
				WHERE R1.course_code=C1.course_code and R1.amka=OLD.amka and R1.register_status='approved'
					UNION
				SELECT C2.units as units
				FROM "Course" C2
				WHERE C2.course_code=OLD.course_code) as foo)
			)THEN
			
			UPDATE "Register"
			SET register_status='rejected'
			WHERE amka=OLD.amka and serial_number=OLD.serial_number and course_code=OLD.course_code;
			
			RETURN NULL;
		ELSE
			RETURN NEW;
		END IF;
	END IF;
	RETURN NEW;
END; 
$BODY$
  LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF 
-----------------------------------------------------------------------------------------------------------------------------------
	
														
