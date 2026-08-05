@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZEDU 교육 신청 RAP Root'
define root view entity ZR_ZEDU_ENROLL
  as select from zedu_enroll
{
  key enroll_id    as EnrollId,
      course_id    as CourseId,
      emp_id       as EmpId,
      emp_name     as EmpName,
      dept_name    as DeptName,
      status       as Status,
      req_date     as ReqDate,
      comp_date    as CompDate,
      created_by   as CreatedBy,
      created_date as CreatedDate
}
