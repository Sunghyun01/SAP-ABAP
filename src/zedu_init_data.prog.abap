*&---------------------------------------------------------------------*
*& Report ZEDU_INIT_DATA
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zedu_init_data.

DATA: lt_course TYPE STANDARD TABLE OF zedu_course,
      lt_enroll TYPE STANDARD TABLE OF zedu_enroll.

START-OF-SELECTION.
  DELETE FROM zedu_enroll.
  DELETE FROM zedu_course.

  lt_course = VALUE #(
   ( mandt        = sy-mandt
     course_id    = 'ABAP_BASIC'
     course_name  = 'ABAP 기본 문법'
     course_type  = 'ABAP'
     start_date   = sy-datum
     end_date     = sy-datum + 5
     capacity     = 30
     created_by   = sy-uname
     created_date = sy-datum )

   ( mandt        = sy-mandt
     course_id    = 'ABAP_ALV'
     course_name  = 'ABAP ALV 실습'
     course_type  = 'ABAP'
     start_date   = sy-datum + 7
     end_date     = sy-datum + 10
     capacity     = 20
     created_by   = sy-uname
     created_date = sy-datum )

   ( mandt        = sy-mandt
     course_id    = 'OPEN_SQL'
     course_name  = 'Open SQL 조회 실습'
     course_type  = 'SQL'
     start_date   = sy-datum + 14
     end_date     = sy-datum + 16
     capacity     = 25
     created_by   = sy-uname
     created_date = sy-datum )
 ).

  lt_enroll = VALUE #(
    ( mandt        = sy-mandt
      enroll_id    = 'ENR000000001'
      course_id    = 'ABAP_BASIC'
      emp_id       = 'E00001'
      emp_name     = '김개발'
      dept_name    = 'HR시스템팀'
      status       = 'A'
      req_date     = sy-datum
      comp_date    = '00000000'
      created_by   = sy-uname
      created_date = sy-datum )

    ( mandt        = sy-mandt
      enroll_id    = 'ENR000000002'
      course_id    = 'ABAP_BASIC'
      emp_id       = 'E00002'
      emp_name     = '이운영'
      dept_name    = '교육운영팀'
      status       = 'C'
      req_date     = sy-datum - 3
      comp_date    = sy-datum
      created_by   = sy-uname
      created_date = sy-datum )

    ( mandt        = sy-mandt
      enroll_id    = 'ENR000000003'
      course_id    = 'ABAP_ALV'
      emp_id       = 'E00003'
      emp_name     = '박테스트'
      dept_name    = '플랫폼팀'
      status       = 'N'
      req_date     = sy-datum - 1
      comp_date    = '00000000'
      created_by   = sy-uname
      created_date = sy-datum )

    ( mandt        = sy-mandt
      enroll_id    = 'ENR000000004'
      course_id    = 'OPEN_SQL'
      emp_id       = 'E00004'
      emp_name     = '최인터페이스'
      dept_name    = '연계개발팀'
      status       = 'X'
      req_date     = sy-datum - 2
      comp_date    = '00000000'
      created_by   = sy-uname
      created_date = sy-datum )
  ).

  INSERT zedu_course FROM TABLE lt_course.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    WRITE / 'ZEDU_COURSE 데이터 생성 실패'.
    RETURN.
  ENDIF.

  INSERT zedu_enroll FROM TABLE lt_enroll.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    WRITE / 'ZEDU_ENROLL 데이터 생성 실패'.
    RETURN.
  ENDIF.

  COMMIT WORK.

  WRITE: / '샘플 데이터 생성 완료'.
  WRITE: / '교육 과정 건수:', lines( lt_course ).
  WRITE: / '교육 신청 건수:', lines( lt_enroll ).
