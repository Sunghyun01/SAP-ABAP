@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZEDU 교육 신청 Fiori 수정용'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: '교육신청',
  typeNamePlural: '교육신청목록',
  title: {
    type: #STANDARD,
    value: 'EnrollId'
  },
  description: {
    value: 'EmpName'
  }
}
define root view entity ZC_ZEDU_ENROLL_EDIT
  provider contract transactional_query
  as projection on ZR_ZEDU_ENROLL
{
  @UI.facet: [
    {
      id: 'GeneralInfo',
      purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: '교육 신청 정보',
      position: 10
    }
  ]

  @UI.lineItem: [
    { position: 10, label: '신청ID' },
    { position: 100, type: #FOR_ACTION, dataAction: 'set_completed', label: '이수 처리' },
    { position: 110, type: #FOR_ACTION, dataAction: 'set_not_completed', label: '미이수 처리' },
    { position: 120, type: #FOR_ACTION, dataAction: 'set_cancelled', label: '신청 취소' }
  ]
  @UI.identification: [
    { position: 10, label: '신청ID' },
    { position: 100, type: #FOR_ACTION, dataAction: 'set_completed', label: '이수 처리' },
    { position: 110, type: #FOR_ACTION, dataAction: 'set_not_completed', label: '미이수 처리' },
    { position: 120, type: #FOR_ACTION, dataAction: 'set_cancelled', label: '신청 취소' }
  ]
  @UI.selectionField: [{ position: 10 }]
  key EnrollId,

  @UI.lineItem: [{ position: 20, label: '과정ID' }]
  @UI.identification: [{ position: 20, label: '과정ID' }]
  CourseId,

  @UI.lineItem: [{ position: 30, label: '사번' }]
  @UI.identification: [{ position: 30, label: '사번' }]
  EmpId,

  @UI.lineItem: [{ position: 40, label: '성명' }]
  @UI.identification: [{ position: 40, label: '성명' }]
  EmpName,

  @UI.lineItem: [{ position: 50, label: '부서' }]
  @UI.identification: [{ position: 50, label: '부서' }]
  DeptName,

  @UI.lineItem: [{ position: 60, label: '상태' }]
  @UI.identification: [{ position: 60, label: '상태' }]
  @UI.selectionField: [{ position: 20 }]
  Status,

  @UI.lineItem: [{ position: 70, label: '신청일' }]
  @UI.identification: [{ position: 70, label: '신청일' }]
  ReqDate,

  @UI.lineItem: [{ position: 80, label: '이수일' }]
  @UI.identification: [{ position: 80, label: '이수일' }]
  CompDate,

  @UI.lineItem: [{ position: 90, label: '생성일' }]
  @UI.identification: [{ position: 90, label: '생성일' }]
  CreatedDate
}
