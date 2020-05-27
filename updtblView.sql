select * from "Professor" union "LabStaff";
(select * from "Participates" p natural join "LearningActivity" l where (l.activity_type='lab' or l.activity_type='computer_lab')
and p.role='responsible' and p.serial_number=( SELECT "Semester".semester_id
                           FROM "Semester"
                          WHERE "Semester".semester_status = 'present'::semester_status_type)
		and exists(
WITH RECURSIVE taken(wd, st, et, rm, cc) AS (
                 SELECT "LearningActivity".weekday AS wd,
                    "LearningActivity".start_time AS st,
                    "LearningActivity".end_time AS et,
                    "LearningActivity".room_id AS rm,
                    "LearningActivity".course_code AS cc
                   FROM "LearningActivity"
                  WHERE "LearningActivity".serial_number = ( SELECT "Semester".semester_id
                           FROM "Semester"
                          WHERE "Semester".semester_status = 'present'::semester_status_type))
select * from taken ta where l.room_id=ta.rm))
														
select * from AutoFill__3_3('ΠΛΗ 102','2020','spring')


--create view lab_schedule_B_2_2 as
--select * from "Lab" where sector_code='1'