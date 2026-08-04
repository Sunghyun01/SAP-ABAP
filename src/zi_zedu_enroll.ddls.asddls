@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZEDU 교육 신청 조회'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: '교육신청',
  typeNamePlural: '교육신청목록',
  title: {
    type: #STANDARD,
    value: 'EnrollId'
  },
  description: {
    value: 'CourseName'
  }
}
define root view entity ZI_ZEDU_ENROLL
  as select from zedu_enroll as Enroll
    inner join zedu_course as Course
      on Enroll.course_id = Course.course_id
{
  @UI.lineItem: [{ position: 10, label: '신청ID' }]
  @UI.selectionField: [{ position: 10 }]
  key Enroll.enroll_id as EnrollId,

  @UI.lineItem: [{ position: 20, label: '과정ID' }]
  @UI.selectionField: [{ position: 20 }]
  Enroll.course_id as CourseId,

  @UI.lineItem: [{ position: 30, label: '과정명' }]
  @UI.selectionField: [{ position: 30 }]
  Course.course_name as CourseName,

  @UI.lineItem: [{ position: 40, label: '교육유형' }]
  Course.course_type as CourseType,

  @UI.lineItem: [{ position: 50, label: '사번' }]
  @UI.selectionField: [{ position: 40 }]
  Enroll.emp_id as EmpId,

  @UI.lineItem: [{ position: 60, label: '성명' }]
  Enroll.emp_name as EmpName,

  @UI.lineItem: [{ position: 70, label: '부서' }]
  Enroll.dept_name as DeptName,

  @UI.lineItem: [{ position: 80, label: '상태' }]
  @UI.selectionField: [{ position: 50 }]
  Enroll.status as Status,

  @UI.lineItem: [{ position: 90, label: '상태명' }]
  cast(
    case Enroll.status
      when 'A' then '신청'
      when 'C' then '이수'
      when 'N' then '미이수'
      when 'X' then '취소'
      else '기타'
    end as abap.char(10)
  ) as StatusText,

  @UI.lineItem: [{ position: 100, label: '신청일' }]
  @UI.selectionField: [{ position: 60 }]
  Enroll.req_date as ReqDate,

  @UI.lineItem: [{ position: 110, label: '이수일' }]
  Enroll.comp_date as CompDate,

  @UI.lineItem: [{ position: 130, label: '생성일' }]
  Enroll.created_date as CreatedDate
}
