*&---------------------------------------------------------------------*
*& Report ZEDU_ENROLL_LIST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zedu_enroll_list.

TYPES: BEGIN OF ty_output,
         enroll_id   TYPE zedu_enroll-enroll_id,
         course_id   TYPE zedu_course-course_id,
         course_name TYPE zedu_course-course_name,
         course_type TYPE zedu_course-course_type,
         emp_id      TYPE zedu_enroll-emp_id,
         emp_name    TYPE zedu_enroll-emp_name,
         dept_name   TYPE zedu_enroll-dept_name,
         status      TYPE zedu_enroll-status,
         status_text TYPE char10,
         req_date    TYPE zedu_enroll-req_date,
         comp_date   TYPE zedu_enroll-comp_date,
           END of ty_output.

DATA: gt_output    TYPE STANDARD TABLE OF ty_output WITH EMPTY KEY,
      gv_course_id TYPE zedu_course-course_id,
      gv_emp_id    TYPE zedu_enroll-emp_id,
      gv_req_date  TYPE zedu_enroll-req_date.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

  SELECT-OPTIONS: s_cid FOR gv_course_id,
  s_emp FOR gv_emp_id,
  s_req FOR gv_req_date.

  PARAMETERS p_stat TYPE zedu_enroll-status.

SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  PERFORM get_data.
  PERFORM display_alv.

FORM get_data.

  CLEAR gt_output.

  IF p_stat IS INITIAL.

  SELECT
   e~enroll_id,
   c~course_id,
   c~course_name,
   c~course_type,
   e~emp_id,
   e~emp_name,
   e~dept_name,
   e~status,
   e~req_date,
   e~comp_date
    FROM zedu_enroll AS e
    INNER JOIN zedu_course AS c
    ON e~course_id = c~course_id
    WHERE  c~course_id IN @s_cid
    AND e~emp_id IN @s_emp
    AND e~req_date IN @s_req
    INTO CORRESPONDING FIELDS OF TABLE @gt_output.

ELSE.

  SELECT
    e~enroll_id,
    c~course_id,
    c~course_name,
    c~course_type,
    e~emp_id,
    e~emp_name,
    e~dept_name,
    e~status,
    e~req_date,
    e~comp_date
    FROM zedu_enroll AS e
    INNER JOIN zedu_course AS c
      ON e~course_id = c~course_id
    WHERE c~course_id IN @s_cid
      AND e~emp_id    IN @s_emp
      AND e~req_date  IN @s_req
      AND e~status    = @p_stat
    INTO CORRESPONDING FIELDS OF TABLE @gt_output.

  ENDIF.

  LOOP AT gt_output ASSIGNING FIELD-SYMBOL(<fs_output>).
    CASE <fs_output>-status.
      WHEN 'A'.
        <fs_output>-status_text = '신청'.
      WHEN 'C'.
        <fs_output>-status_text = '이수'.
      WHEN 'N'.
        <fs_output>-status_text = '미이수'.
      WHEN 'X'.
        <fs_output>-status_text = '취소'.
      WHEN OTHERS.
        <fs_output>-status_text = '기타'.
    ENDCASE.
  ENDLOOP.

ENDFORM.

FORM display_alv.

  IF gt_output IS INITIAL.
    MESSAGE '조회된 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table   =                           DATA(lo_alv)
        CHANGING
          t_table        = gt_output
      ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_columns( )->set_optimize( abap_true ).

      DATA(lo_columns) = lo_alv->get_columns( ).


      lo_columns->get_column( 'ENROLL_ID' )->set_short_text( '신청ID' ).
      lo_columns->get_column( 'COURSE_ID' )->set_short_text( '과정ID' ).
      lo_columns->get_column( 'COURSE_NAME' )->set_short_text( '과정명' ).
      lo_columns->get_column( 'COURSE_TYPE' )->set_short_text( '유형' ).
      lo_columns->get_column( 'EMP_ID' )->set_short_text( '사번' ).
      lo_columns->get_column( 'EMP_NAME' )->set_short_text( '이름' ).
      lo_columns->get_column( 'DEPT_NAME' )->set_short_text( '부서' ).
      lo_columns->get_column( 'STATUS' )->set_short_text( '상태' ).
      lo_columns->get_column( 'STATUS_TEXT' )->set_short_text( '상태명' ).
      lo_columns->get_column( 'REQ_DATE' )->set_short_text( '신청일' ).
      lo_columns->get_column( 'COMP_DATE' )->set_short_text( '이수일' ).

      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

    CATCH cx_salv_not_found INTO DATA(lx_not_found).
      MESSAGE lx_not_found->get_text( ) TYPE 'S' DISPLAY LIKE 'E'..

  ENDTRY.

ENDFORM.
