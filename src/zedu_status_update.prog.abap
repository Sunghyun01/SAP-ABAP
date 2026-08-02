REPORT zedu_status_update.

*-----------------------------------------------------------------------
* Data
*-----------------------------------------------------------------------
DATA: ls_enroll      TYPE zedu_enroll,
      lv_status_text TYPE char10,
      lv_msg_text    TYPE zedu_log-msg_text,
      gv_log_saved   TYPE c.

*-----------------------------------------------------------------------
* Selection Screen
*-----------------------------------------------------------------------
PARAMETERS: p_enrid TYPE zedu_enroll-enroll_id OBLIGATORY,
            p_stat  TYPE zedu_enroll-status    OBLIGATORY.

*-----------------------------------------------------------------------
* Validation
*-----------------------------------------------------------------------
AT SELECTION-SCREEN.

  CASE p_stat.
    WHEN 'A' OR 'C' OR 'N' OR 'X'.
      " 정상 상태값
    WHEN OTHERS.
      MESSAGE '상태값은 A, C, N, X 중 하나만 입력 가능합니다.' TYPE 'E'.
  ENDCASE.

*-----------------------------------------------------------------------
* Start
*-----------------------------------------------------------------------
START-OF-SELECTION.

  PERFORM get_status_text.
  PERFORM update_status.

*-----------------------------------------------------------------------
* 상태 텍스트 변환
*-----------------------------------------------------------------------
FORM get_status_text.

  CASE p_stat.
    WHEN 'A'.
      lv_status_text = '신청'.
    WHEN 'C'.
      lv_status_text = '이수'.
    WHEN 'N'.
      lv_status_text = '미이수'.
    WHEN 'X'.
      lv_status_text = '취소'.
    WHEN OTHERS.
      lv_status_text = '기타'.
  ENDCASE.

ENDFORM.

*-----------------------------------------------------------------------
* 상태 변경
*-----------------------------------------------------------------------
FORM update_status.

  DATA: lv_process_type TYPE zedu_log-process_type,
        lv_ref_id       TYPE zedu_log-ref_id,
        lv_course_id    TYPE zedu_log-course_id,
        lv_enroll_id    TYPE zedu_log-enroll_id,
        lv_msg_type     TYPE zedu_log-msg_type.

  CLEAR: ls_enroll,
         lv_msg_text,
         lv_process_type,
         lv_ref_id,
         lv_course_id,
         lv_enroll_id,
         lv_msg_type.

  SELECT SINGLE *
    FROM zedu_enroll
    INTO ls_enroll
    WHERE enroll_id = p_enrid.

  IF sy-subrc <> 0.

    CONCATENATE '존재하지 않는 신청 ID입니다:' p_enrid
      INTO lv_msg_text SEPARATED BY space.

    lv_process_type = 'S'.
    lv_ref_id       = p_enrid.
    lv_course_id    = ''.
    lv_enroll_id    = p_enrid.
    lv_msg_type     = 'E'.

    PERFORM save_log USING lv_process_type
                           lv_ref_id
                           lv_course_id
                           lv_enroll_id
                           lv_msg_type
                           lv_msg_text.

    COMMIT WORK.

    MESSAGE lv_msg_text TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

  ls_enroll-status = p_stat.

  IF p_stat = 'C'.
    ls_enroll-comp_date = sy-datum.
  ELSE.
    ls_enroll-comp_date = '00000000'.
  ENDIF.

  UPDATE zedu_enroll FROM ls_enroll.

  IF sy-subrc = 0.

    CONCATENATE '교육 신청 상태가'
                lv_status_text
                '상태로 변경되었습니다.'
      INTO lv_msg_text SEPARATED BY space.

    lv_process_type = 'S'.
    lv_ref_id       = p_enrid.
    lv_course_id    = ls_enroll-course_id.
    lv_enroll_id    = ls_enroll-enroll_id.
    lv_msg_type     = 'S'.

    PERFORM save_log USING lv_process_type
                           lv_ref_id
                           lv_course_id
                           lv_enroll_id
                           lv_msg_type
                           lv_msg_text.

    COMMIT WORK.

    WRITE: / '교육 신청 상태가 변경되었습니다.'.
    WRITE: / '신청 ID:', p_enrid.
    WRITE: / '교육 과정:', ls_enroll-course_id.
    WRITE: / '변경 상태:', p_stat, lv_status_text.
    WRITE: / '처리 일자:', sy-datum.
    WRITE: / '처리 시간:', sy-uzeit.

    IF gv_log_saved = 'X'.
      WRITE: / '로그 저장:', '완료'.
    ELSE.
      WRITE: / '로그 저장:', '실패'.
    ENDIF.

  ELSE.

    ROLLBACK WORK.

    CONCATENATE '교육 신청 상태 변경에 실패했습니다:' p_enrid
      INTO lv_msg_text SEPARATED BY space.

    lv_process_type = 'S'.
    lv_ref_id       = p_enrid.
    lv_course_id    = ls_enroll-course_id.
    lv_enroll_id    = ls_enroll-enroll_id.
    lv_msg_type     = 'E'.

    PERFORM save_log USING lv_process_type
                           lv_ref_id
                           lv_course_id
                           lv_enroll_id
                           lv_msg_type
                           lv_msg_text.

    COMMIT WORK.

    WRITE: / '교육 신청 상태 변경에 실패했습니다.'.
    WRITE: / '신청 ID:', p_enrid.

    IF gv_log_saved = 'X'.
      WRITE: / '오류 로그 저장:', '완료'.
    ELSE.
      WRITE: / '오류 로그 저장:', '실패'.
    ENDIF.

  ENDIF.

ENDFORM.

*-----------------------------------------------------------------------
* 로그 저장
*-----------------------------------------------------------------------
FORM save_log
  USING    VALUE(iv_process_type) TYPE zedu_log-process_type
           VALUE(iv_ref_id)       TYPE zedu_log-ref_id
           VALUE(iv_course_id)    TYPE zedu_log-course_id
           VALUE(iv_enroll_id)    TYPE zedu_log-enroll_id
           VALUE(iv_msg_type)     TYPE zedu_log-msg_type
           VALUE(iv_msg_text)     TYPE zedu_log-msg_text.

  DATA: ls_log    TYPE zedu_log,
        lv_log_id TYPE zedu_log-log_id,
        lv_prefix TYPE c LENGTH 17,
        lv_seq    TYPE n LENGTH 3.

  CLEAR: ls_log,
         lv_log_id,
         lv_prefix,
         lv_seq,
         gv_log_saved.

  CONCATENATE 'LOG' sy-datum sy-uzeit INTO lv_prefix.

  ls_log-mandt        = sy-mandt.
  ls_log-process_type = iv_process_type.
  ls_log-ref_id       = iv_ref_id.
  ls_log-course_id    = iv_course_id.
  ls_log-enroll_id    = iv_enroll_id.
  ls_log-msg_type     = iv_msg_type.
  ls_log-msg_text     = iv_msg_text.
  ls_log-program_id   = sy-repid.
  ls_log-created_by   = sy-uname.
  ls_log-created_date = sy-datum.
  ls_log-created_time = sy-uzeit.

  DO 999 TIMES.

    lv_seq = sy-index.
    CONCATENATE lv_prefix lv_seq INTO lv_log_id.

    ls_log-log_id = lv_log_id.

    INSERT zedu_log FROM ls_log.

    IF sy-subrc = 0.
      gv_log_saved = 'X'.
      EXIT.
    ENDIF.

  ENDDO.

ENDFORM.
