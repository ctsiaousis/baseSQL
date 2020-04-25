-- erwthma 3.1-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION CreateStudents__3_1(year integer, num integer)
RETURNS TABLE (am CHARACTER(10), surname character(50), name character(50)) AS
$BODY$
BEGIN
	RETURN QUERY
	SELECT create_am(year,n.id), adapt_surname(s.surname,n.sex), n.name
		FROM random_names(num) n NATURAL JOIN random_surnames(num) s;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;

-- select * from create_students(2020, 15);
--            -------------------------------------------------------------------


-- erwthma 3.2-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION InsertGrades__3_2(in sem integer)
RETURNS void as 
$BODY$
begin 

UPDATE "Register" 
SET exam_grade=(select random() * 9 + 1) :: integer
FROM( 
	 	SELECT DISTINCT R.course_code cc, R.amka ak, R.serial_number sr
		FROM "CourseRun" L, "Register" R
		WHERE L.semesterrunsin= (SELECT Y.semester_id from "Semester" Y where semester_id=sem) 
											and R.serial_number=L.serial_number and R.course_code=L.course_code 
													  	and R.register_status='approved') W
where W.cc=course_code and W.ak=amka and W.sr= serial_number;-- and semester_id=sem;

UPDATE "Register"
SET lab_grade=(select random() * 9 + 1) :: integer
FROM(
	SELECT DISTINCT R.course_code cc, R.amka ak, R.serial_number sr
		FROM "CourseRun" L, "Register" R
		WHERE L.semesterrunsin= (SELECT Z.semester_id from "Semester" Z where Z.semester_id=sem) 
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
				where L.semesterrunsin= (SELECT Z.semester_id from "Semester" Z where Z.semester_id=sem)
												and R.serial_number=L.serial_number and R.course_code=L.course_code 
													 and R.register_status='approved') B 
where amka=B.ak and course_code=B.cc and serial_number=sem;

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.1----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION BiggerThan30People__4_1()
RETURNS TABLE(amka integer, name character(30), surname character(30)) AS
$BODY$
BEGIN
--pare ta room_id apo aithouses me capacity>30 kai ola ta amka tou participates me roomid auto
--natural join participates me professor kai labstaf kai print kai onoma epitheto
END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.2----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION OfficeHoursOfProfs__4_2()
RETURNS TABLE(surnameName character(60), course_code character(7), weekday integer, start_time numeric, end_time numeric) AS
$BODY$
BEGIN

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.3----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION MaxGrade__4_3(in sem integer)
RETURNS TABLE(course_code CHARACTER(7), grade numeric) AS
$BODY$
BEGIN

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.4----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ParticipatesInPCRoom__4_4()
RETURNS TABLE(amka integer, entry_date date) AS
$BODY$
BEGIN
SELECT DISTINCT S.am, S.entry_date
	
FROM "Student" S  NATURAL JOIN "Register" R NATURAL JOIN "Semester" E NATURAL JOIN "Course" C NATURAL JOIN "CourseRun" Cr
WHERE E.semester_status='present' and R.amka=S.amka and R.course_code= Cr.course_code and Cr.course_code= C.course_code and C.obligatory='false' and Cr.semesterrunsin=E.semester_id;
END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.5----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION NoonHours__4_5()
RETURNS TABLE(course_code character(7), isTrue character(3)) AS
$BODY$
BEGIN

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.6----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ObligatoryWithoutLabRoom__4_6()
RETURNS TABLE(course_code character(7), course_title character(100)) AS
$BODY$
BEGIN

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.7----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION LabAssistantsTotal__4_7()
RETURNS TABLE(amka integer, surname character(30), name character(30), totalHours integer) AS
$BODY$
BEGIN

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------


-- erwthma 4.8----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION MostUsedRoom__4_8()
RETURNS TABLE(room_id character(6)) AS
$BODY$
BEGIN

END;
$BODY$
LANGUAGE 'plpgsql';
--            -------------------------------------------------------------------
