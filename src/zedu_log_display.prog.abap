REPORT zedu_log_display.

*-----------------------------------------------------------------------
* Type Definition
*-----------------------------------------------------------------------
TYPES: BEGIN OF ty_output,
         log_id        TYPE zedu_log-log_id,
         process_type  TYPE zedu_log-process_type,
         process_text  TYPE char20,
         ref_id        TYPE zedu_log-ref_id,
         course_id     TYPE zedu_log-course_id,
         enroll_id     TYPE zedu_log-enroll_id,
         msg_type      TYPE zedu_log-msg_type,
         msg_type_text TYPE char10,
         msg_text      TYPE zedu_log-msg_text,
         program_id    TYPE zedu_log-program_id,
         created_by    TYPE zedu_log-created_by,
         created_date  TYPE zedu_log-created_date,
         created_time  TYPE zedu_log-created_time,
       END OF ty_output.

*-----------------------------------------------------------------------
* Data
*-----------------------------------------------------------------------
DATA: gt_output       TYPE STANDARD TABLE OF ty_output,
      gv_date         TYPE zedu_log-created_date,
      gv_msg_type     TYPE zedu_log-msg_type,
      gv_process_type TYPE zedu_log-process_type,
      gv_program_id   TYPE zedu_log-program_id,
      gv_enroll_id    TYPE zedu_log-enroll_id.

DATA: lo_alv       TYPE REF TO cl_salv_table,
      lo_functions TYPE REF TO cl_salv_functions_list,
      lo_columns   TYPE REF TO cl_salv_columns_table,
      lo_column    TYPE REF TO cl_salv_column.

*-----------------------------------------------------------------------
* Selection Screen
*-----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.

SELECT-OPTIONS: s_date  FOR gv_date,
                s_mtype FOR gv_msg_type,
                s_ptype FOR gv_process_type,
                s_prog  FOR gv_program_id,
                s_enrid FOR gv_enroll_id.

SELECTION-SCREEN END OF BLOCK b1.

*-----------------------------------------------------------------------
* Start
*-----------------------------------------------------------------------
START-OF-SELECTION.

  PERFORM get_data.
  PERFORM display_alv.

*-----------------------------------------------------------------------
* Get Data
*-----------------------------------------------------------------------
FORM get_data.

  CLEAR gt_output.

  SELECT log_id
         process_type
         ref_id
         course_id
         enroll_id
         msg_type
         msg_text
         program_id
         created_by
         created_date
         created_time
    FROM zedu_log
    INTO CORRESPONDING FIELDS OF TABLE gt_output
    WHERE created_date IN s_date
      AND msg_type     IN s_mtype
      AND process_type IN s_ptype
      AND program_id   IN s_prog
      AND enroll_id    IN s_enrid.

  SORT gt_output BY created_date DESCENDING
                    created_time DESCENDING
                    log_id       DESCENDING.

  LOOP AT gt_output ASSIGNING FIELD-SYMBOL(<fs_output>).

    CASE <fs_output>-process_type.
      WHEN 'I'.
        <fs_output>-process_text = '초기데이터'.
      WHEN 'S'.
        <fs_output>-process_text = '상태변경'.
      WHEN 'B'.
        <fs_output>-process_text = '배치처리'.
      WHEN 'E'.
        <fs_output>-process_text = '오류처리'.
      WHEN OTHERS.
        <fs_output>-process_text = '기타'.
    ENDCASE.

    CASE <fs_output>-msg_type.
      WHEN 'S'.
        <fs_output>-msg_type_text = '성공'.
      WHEN 'E'.
        <fs_output>-msg_type_text = '오류'.
      WHEN 'W'.
        <fs_output>-msg_type_text = '경고'.
      WHEN 'I'.
        <fs_output>-msg_type_text = '정보'.
      WHEN OTHERS.
        <fs_output>-msg_type_text = '기타'.
    ENDCASE.

  ENDLOOP.

ENDFORM.

*-----------------------------------------------------------------------
* Display ALV
*-----------------------------------------------------------------------
FORM display_alv.

  IF gt_output IS INITIAL.
    MESSAGE '조회된 로그 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.

      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = gt_output
      ).

      lo_functions = lo_alv->get_functions( ).
      lo_functions->set_all( abap_true ).

      lo_columns = lo_alv->get_columns( ).
      lo_columns->set_optimize( abap_true ).

      lo_column = lo_columns->get_column( 'LOG_ID' ).
      lo_column->set_short_text( '로그ID' ).

      lo_column = lo_columns->get_column( 'PROCESS_TYPE' ).
      lo_column->set_short_text( '처리구분' ).

      lo_column = lo_columns->get_column( 'PROCESS_TEXT' ).
      lo_column->set_short_text( '처리명' ).

      lo_column = lo_columns->get_column( 'REF_ID' ).
      lo_column->set_short_text( '참조ID' ).

      lo_column = lo_columns->get_column( 'COURSE_ID' ).
      lo_column->set_short_text( '과정ID' ).

      lo_column = lo_columns->get_column( 'ENROLL_ID' ).
      lo_column->set_short_text( '신청ID' ).

      lo_column = lo_columns->get_column( 'MSG_TYPE' ).
      lo_column->set_short_text( '메시지' ).

      lo_column = lo_columns->get_column( 'MSG_TYPE_TEXT' ).
      lo_column->set_short_text( '메시지명' ).

      lo_column = lo_columns->get_column( 'MSG_TEXT' ).
      lo_column->set_short_text( '내용' ).

      lo_column = lo_columns->get_column( 'PROGRAM_ID' ).
      lo_column->set_short_text( '프로그램' ).

      lo_column = lo_columns->get_column( 'CREATED_BY' ).
      lo_column->set_short_text( '생성자' ).

      lo_column = lo_columns->get_column( 'CREATED_DATE' ).
      lo_column->set_short_text( '생성일' ).

      lo_column = lo_columns->get_column( 'CREATED_TIME' ).
      lo_column->set_short_text( '생성시간' ).

      lo_alv->display( ).

    CATCH cx_salv_msg.
      MESSAGE 'ALV 출력 중 오류가 발생했습니다.' TYPE 'S' DISPLAY LIKE 'E'.

    CATCH cx_salv_not_found.
      MESSAGE 'ALV 컬럼 설정 중 오류가 발생했습니다.' TYPE 'S' DISPLAY LIKE 'E'.

  ENDTRY.

ENDFORM.
