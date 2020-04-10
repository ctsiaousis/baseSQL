-- erwthma 3.1-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_students(year integer, num integer)
RETURNS TABLE (am CHARACTER(10), surname character(50), name character(50)) AS
$BODY$
BEGIN
	RETURN QUERY
	SELECT create_am(year,n.id), adapt_surname(s.surname,n.sex), n.name
		FROM random_names(num) n NATURAL JOIN random_surnames(num) s;
END;
$BODY$ LANGUAGE 'plpgsql' VOLATILE;

select * from create_students(2020, 15)
--         ----------------------------------------------------------------------

-- erwthma 3.2-------------------------------------------------------------------
CREATE OR REPLACE FUNCTION InsertGrades(in sem integer)
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
--         ----------------------------------------------------------------------