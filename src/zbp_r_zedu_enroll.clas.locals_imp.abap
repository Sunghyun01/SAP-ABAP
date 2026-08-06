CLASS lhc_enrollment DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS set_completed FOR MODIFY
      IMPORTING keys FOR ACTION Enrollment~set_completed RESULT result.

    METHODS set_not_completed FOR MODIFY
      IMPORTING keys FOR ACTION Enrollment~set_not_completed RESULT result.

    METHODS set_cancelled FOR MODIFY
      IMPORTING keys FOR ACTION Enrollment~set_cancelled RESULT result.

    METHODS save_log FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Enrollment~save_log.

ENDCLASS.


CLASS lhc_enrollment IMPLEMENTATION.

  METHOD set_completed.

    MODIFY ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        UPDATE FIELDS ( Status CompDate )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky     = key-%tky
            Status   = 'C'
            CompDate = sy-datum
          )
        )
      FAILED failed
      REPORTED reported.

    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId EmpId EmpName DeptName Status ReqDate CompDate CreatedBy CreatedDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD set_not_completed.

    MODIFY ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        UPDATE FIELDS ( Status CompDate )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky     = key-%tky
            Status   = 'N'
            CompDate = '00000000'
          )
        )
      FAILED failed
      REPORTED reported.

    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId EmpId EmpName DeptName Status ReqDate CompDate CreatedBy CreatedDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD set_cancelled.

    MODIFY ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        UPDATE FIELDS ( Status CompDate )
        WITH VALUE #(
          FOR key IN keys
          (
            %tky     = key-%tky
            Status   = 'X'
            CompDate = '00000000'
          )
        )
      FAILED failed
      REPORTED reported.

    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId EmpId EmpName DeptName Status ReqDate CompDate CreatedBy CreatedDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls_result IN lt_result
      (
        %tky   = ls_result-%tky
        %param = ls_result
      )
    ).

  ENDMETHOD.


  METHOD save_log.

    DATA: ls_log        TYPE zedu_log,
          lv_log_id     TYPE zedu_log-log_id,
          lv_prefix     TYPE c LENGTH 17,
          lv_seq        TYPE n LENGTH 3,
          lv_msg        TYPE zedu_log-msg_text,
          lv_old_status TYPE zedu_enroll-status.

    READ ENTITIES OF zr_zedu_enroll IN LOCAL MODE
      ENTITY Enrollment
        FIELDS ( EnrollId CourseId Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_enroll).

    CONCATENATE 'LOG' sy-datum sy-uzeit INTO lv_prefix.

    LOOP AT lt_enroll INTO DATA(ls_enroll).

      CLEAR lv_old_status.

      SELECT SINGLE status
        FROM zedu_enroll
        INTO lv_old_status
        WHERE enroll_id = ls_enroll-EnrollId.

      IF sy-subrc = 0 AND lv_old_status = ls_enroll-Status.
        CONTINUE.
      ENDIF.

      CLEAR: ls_log,
             lv_log_id,
             lv_seq,
             lv_msg.

      CONCATENATE '교육 신청 상태 변경:'
                  lv_old_status
                  '->'
                  ls_enroll-Status
        INTO lv_msg SEPARATED BY space.

      DO 999 TIMES.

        lv_seq = sy-index.
        CONCATENATE lv_prefix lv_seq INTO lv_log_id.

        CLEAR ls_log.

        ls_log-mandt        = sy-mandt.
        ls_log-log_id       = lv_log_id.
        ls_log-process_type = 'S'.
        ls_log-ref_id       = ls_enroll-EnrollId.
        ls_log-course_id    = ls_enroll-CourseId.
        ls_log-enroll_id    = ls_enroll-EnrollId.
        ls_log-msg_type     = 'S'.
        ls_log-msg_text     = lv_msg.
        ls_log-program_id   = sy-repid.
        ls_log-created_by   = sy-uname.
        ls_log-created_date = sy-datum.
        ls_log-created_time = sy-uzeit.

        INSERT zedu_log FROM ls_log.

        IF sy-subrc = 0.
          EXIT.
        ENDIF.

      ENDDO.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
